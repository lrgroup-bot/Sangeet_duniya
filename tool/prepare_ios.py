from pathlib import Path
import plistlib

ROOT = Path(".")
plist_path = ROOT / "ios/Runner/Info.plist"

if not plist_path.exists():
    raise SystemExit("Run: flutter create --platforms=ios . before this script.")

with plist_path.open("rb") as handle:
    data = plistlib.load(handle)

background = set(data.get("UIBackgroundModes", []))
background.add("audio")
data["UIBackgroundModes"] = sorted(background)
data["NSMicrophoneUsageDescription"] = (
    'Sangeeta uses the microphone when you enable voice commands.'
)
data["NSSpeechRecognitionUsageDescription"] = (
    'Sangeeta uses speech recognition for "Hey Sangeeta" voice commands.'
)

with plist_path.open("wb") as handle:
    plistlib.dump(data, handle)

print("iOS audio background mode and voice permission descriptions prepared.")
