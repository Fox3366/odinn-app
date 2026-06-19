"""
odin_video_sender.py
====================
Otonom (Zero-Config) YOLO Video Akış Sunucusu

Kameradan görüntü alır, YOLOv8n ile insan ve araç tespiti yapar,
tespit edilen nesneleri kutulayarak telefona UDP ile gönderir.

İlk çalıştırmada YOLOv8n modeli (~6MB) otomatik indirilir.

Gerekli kütüphaneler:
    pip install ultralytics opencv-python numpy

Kullanım:
    python odin_video_sender.py
    python odin_video_sender.py --show-preview
    python odin_video_sender.py --source video.mp4
"""

import cv2
import numpy as np
import socket
import struct
import time
import argparse
import threading

from ultralytics import YOLO

# ---------- Ayarlar ----------
LISTEN_PORT   = 5600
CHUNK_SIZE    = 1400
TARGET_FPS    = 15
JPEG_QUALITY  = 65
CONFIDENCE    = 0.40

HEADER_FORMAT = "!IHH"

# YOLOv8n COCO sınıflarından İHA görevi için önemli olanlar
# 0=person, 1=bicycle, 2=car, 3=motorbike, 5=bus, 7=truck
DETECT_CLASSES = [0, 1, 2, 3, 5, 7]

# Renk paleti (sınıf ID -> BGR renk)
COLORS = {
    0: (0, 255, 80),    # person  → Yeşil
    1: (255, 180, 0),   # bicycle → Mavi
    2: (255, 100, 0),   # car     → Açık Mavi
    3: (0, 165, 255),   # motorbike → Turuncu
    5: (0, 255, 255),   # bus     → Sarı
    7: (80, 80, 255),   # truck   → Kırmızımsı
}

LABELS_TR = {
    0: "INSAN",
    1: "BISIKLET",
    2: "ARAC",
    3: "MOTORSIKLET",
    5: "OTOBUS",
    7: "KAMYON",
}

# Global hedef (Telefondan ping gelince yazılır)
target_address = None


def discovery_listener(sock):
    """Uygulamadan gelen PING paketini yakalar ve hedef IP'yi kilitler."""
    global target_address
    print(f"[ODİN] Uygulamadan bağlantı bekleniyor (Port: {LISTEN_PORT})...")
    while True:
        try:
            data, addr = sock.recvfrom(1024)
            if target_address != addr:
                target_address = addr
                print(f"[🚀] Hedef Kilitlendi: {addr[0]}:{addr[1]}")
        except:
            time.sleep(1)


def send_frame(sock, addr, frame_id: int, jpeg_bytes: bytes):
    """JPEG frame'i chunk'lara böler ve UDP ile gönderir."""
    chunks = [
        jpeg_bytes[i:i + CHUNK_SIZE]
        for i in range(0, len(jpeg_bytes), CHUNK_SIZE)
    ]
    total = len(chunks)
    for idx, chunk in enumerate(chunks):
        header = struct.pack(HEADER_FORMAT, frame_id, idx, total)
        try:
            sock.sendto(header + chunk, addr)
        except:
            pass


def draw_detections(frame, results):
    """YOLO sonuçlarını frame üzerine çizer. Tespit sayısını döndürür."""
    count = 0
    for r in results:
        for box in r.boxes:
            cls_id = int(box.cls[0])
            if cls_id not in DETECT_CLASSES:
                continue

            conf = float(box.conf[0])
            x1, y1, x2, y2 = map(int, box.xyxy[0])

            color = COLORS.get(cls_id, (200, 200, 200))
            label = LABELS_TR.get(cls_id, f"ID:{cls_id}")
            text  = f"{label} %{int(conf * 100)}"

            # Kutu
            cv2.rectangle(frame, (x1, y1), (x2, y2), color, 2)

            # Etiket arka planı
            (tw, th), _ = cv2.getTextSize(text, cv2.FONT_HERSHEY_SIMPLEX, 0.5, 1)
            cv2.rectangle(frame, (x1, y1 - th - 8), (x1 + tw + 4, y1), color, -1)
            cv2.putText(frame, text, (x1 + 2, y1 - 4),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 0), 1, cv2.LINE_AA)
            count += 1

    # Sol üst köşeye toplam tespit sayısı
    status = f"TESPIT: {count}"
    cv2.putText(frame, status, (10, 28),
                cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 80), 2, cv2.LINE_AA)

    return frame


def main():
    parser = argparse.ArgumentParser(description="ODİN YOLO Video Sender")
    parser.add_argument("--source", default="0", help="Kamera index veya video path")
    parser.add_argument("--show-preview", action="store_true", help="PC'de önizleme göster")
    args = parser.parse_args()

    # YOLO Modeli (ilk seferde otomatik indirilir)
    print("[ODİN] YOLOv8n modeli yükleniyor...")
    model = YOLO("yolov8n.pt")
    print("[ODİN] Model hazır!")

    source = int(args.source) if args.source.isdigit() else args.source
    cap = cv2.VideoCapture(source)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)

    # UDP Soketi
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind(("0.0.0.0", LISTEN_PORT))

    # Keşif Thread'i
    threading.Thread(target=discovery_listener, args=(sock,), daemon=True).start()

    frame_id = 0
    interval = 1.0 / TARGET_FPS
    encode_params = [cv2.IMWRITE_JPEG_QUALITY, JPEG_QUALITY]

    while True:
        t0 = time.monotonic()

        ret, frame = cap.read()
        if not ret:
            time.sleep(0.1)
            continue

        if target_address is not None:
            # YOLO Tespit
            results = model.predict(
                frame,
                conf=CONFIDENCE,
                classes=DETECT_CLASSES,
                verbose=False,
                imgsz=640,
            )

            # Sonuçları çiz
            processed = draw_detections(frame.copy(), results)

            # Önizleme
            if args.show_preview:
                cv2.imshow("ODİN - YOLO", processed)
                if cv2.waitKey(1) & 0xFF == ord('q'):
                    break

            # Encode ve gönder
            ok, jpeg_buf = cv2.imencode(".jpg", processed, encode_params)
            if ok:
                send_frame(sock, target_address, frame_id & 0xFFFFFFFF, jpeg_buf.tobytes())
                frame_id += 1

        elapsed = time.monotonic() - t0
        wait = interval - elapsed
        if wait > 0:
            time.sleep(wait)

    cap.release()
    if args.show_preview:
        cv2.destroyAllWindows()
    sock.close()


if __name__ == "__main__":
    main()
