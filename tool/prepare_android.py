from pathlib import Path

from PIL import Image
import cairosvg

ROOT = Path(".")
manifest = ROOT / "android/app/src/main/AndroidManifest.xml"
text = manifest.read_text(encoding="utf-8")

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
        source.resize((pixels, pixels), Image.Resampling.LANCZOS).save(
            out_dir / "ic_launcher.png"
        )

rendered.unlink(missing_ok=True)
print("AndroidManifest.xml and launcher icon prepared from vector artwork.")
