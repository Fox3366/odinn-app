/// Drone'dan gelen COMMAND_ACK paketini UI'a taşıyan değişmez veri sınıfı.
class CommandResult {
  final int    command;
  final int    result; // MAV_RESULT (0 = ACCEPTED)
  final String label;

  const CommandResult({
    required this.command,
    required this.result,
    required this.label,
  });

  bool get accepted => result == 0;

  String get resultText {
    switch (result) {
      case 0:  return 'KABUL EDİLDİ';
      case 1:  return 'REDDEDİLDİ';
      case 2:  return 'DESTEKLENMİYOR';
      case 3:  return 'ZAMAN AŞIMI';
      case 4:  return 'BAŞARISIZ';
      default: return 'BİLİNMİYOR ($result)';
    }
  }
}