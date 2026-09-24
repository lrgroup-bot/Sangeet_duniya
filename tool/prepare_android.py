from pathlib import Path

from PIL import Image
import cairosvg

ROOT = Path(".")
manifest = ROOT / "android/app/src/main/AndroidManifest.xml"
text = manifest.read_text(encoding="utf-8")

# Local same-Wi-Fi admin registration uses a private LAN HTTP endpoint.
if 'android:usesCleartextTraffic=' not in text:
    text = text.replace(
        '<application',
        '<application android:usesCleartextTraffic="true"',
        1,
    )

if 'xmlns:tools=' not in text.split('>', 1)[0]:
    text = text.replace(
        '<manifest xmlns:android="http://schemas.android.com/apk/res/android">',
        '<manifest xmlns:android="http://schemas.android.com/apk/res/android" '
        'xmlns:tools="http://schemas.android.com/tools">'
    )

permissions = [
    '    <uses-permission android:name="android.permission.INTERNET" />',
    '    <uses-permission android:name="android.permission.WAKE_LOCK" />',
    '    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />',
    '    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />',
    '    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />',
    '    <uses-permission android:name="android.permission.RECORD_AUDIO" />',
    '    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />',
]
for permission in permissions:
    permission_name = permission.split('android:name="')[1].split('"')[0]
    if permission_name not in text:
        text = text.replace('    <application', permission + '\n    <application', 1)

text = text.replace(
    'android:label="lrs_sangeet_duniya"',
    'android:label="LR\'s Sangeet_Duniya"',
    1,
)
text = text.replace(
    'android:name=".MainActivity"',
    'android:name="com.ryanheise.audioservice.AudioServiceActivity"',
    1,
)

service = '''        <service
            android:name="com.ryanheise.audioservice.AudioService"
            android:exported="true"
            android:foregroundServiceType="mediaPlayback"
            tools:ignore="Instantiatable">
            <intent-filter>
                <action android:name="android.media.browse.MediaBrowserService" />
            </intent-filter>
        </service>
        <receiver
            android:name="com.ryanheise.audioservice.MediaButtonReceiver"
            android:exported="true"
            tools:ignore="Instantiatable">
            <intent-filter>
                <action android:name="android.intent.action.MEDIA_BUTTON" />
            </intent-filter>
        </receiver>
'''
if "com.ryanheise.audioservice.AudioService" not in text:
    text = text.replace("    </application>", service + "    </application>", 1)

manifest.write_text(text, encoding="utf-8")

# Generate launcher icons from the checked-in vector logo.
svg = ROOT / "assets/brand/logo.svg"
rendered = ROOT / "build_logo_1024.png"
cairosvg.svg2png(url=str(svg), write_to=str(rendered), output_width=1024, output_height=1024)

sizes = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}
with Image.open(rendered).convert("RGBA") as source:
    for folder, pixels in sizes.items():
        out_dir = ROOT / f"android/app/src/main/res/{folder}"
        out_dir.mkdir(parents=True, exist_ok=True)
        resized = source.resize((pixels, pixels), Image.Resampling.LANCZOS)
        resized.save(out_dir / "ic_launcher.png")
        resized.save(out_dir / "ic_launcher_round.png")

# Remove generated adaptive-icon XML so Android resolves the new PNG launcher
# assets consistently across API levels.
for adaptive in [
    ROOT / "android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml",
    ROOT / "android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml",
]:
    adaptive.unlink(missing_ok=True)

stat_dir = ROOT / "android/app/src/main/res/drawable"
stat_dir.mkdir(parents=True, exist_ok=True)
(stat_dir / "ic_stat_sangeet.xml").write_text(
    """<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FFFFFFFF"
        android:pathData="M12,3a7,7 0,0 0,-7 7v4a2,2 0,0 0,2 2h1v-6a4,4 0,0 1,8 0v6h1a2,2 0,0 0,2 -2v-4a7,7 0,0 0,-7 -7zM7,17h-1v3a1,1 0,0 0,1 1h2v-2h-2zM15,19v2h2a1,1 0,0 0,1 -1v-3h-1v2z"/>
</vector>""",
    encoding="utf-8",
)
rendered.unlink(missing_ok=True)
print("AndroidManifest.xml, launcher icon, and media notification icon prepared.")
