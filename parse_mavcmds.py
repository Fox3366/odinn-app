import json

commands_to_check = [16, 20, 21, 22, 84, 85, 3000, 192, 17, 18, 19, 31, 32]
files = [
    "qgc_temp/src/MissionManager/MavCmdInfoCommon.json",
    "qgc_temp/src/MissionManager/MavCmdInfoVTOL.json",
]

for f in files:
    with open(f, 'r') as fp:
        data = json.load(fp)
        for cmd in data.get('mavCmdInfo', []):
            if cmd['id'] in commands_to_check:
                print(f"Command ID: {cmd['id']} in {f}")
                print(f"Name: {cmd.get('friendlyName', 'Unknown')}")
                for i in range(1, 8):
                    param_key = f'param{i}'
                    if param_key in cmd:
                        p = cmd[param_key]
                        print(f"  {param_key}: label='{p.get('label', '')}', default={p.get('default', 'none')}, units='{p.get('units', '')}'")
                print("-" * 40)
