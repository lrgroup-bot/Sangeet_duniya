from pathlib import Path

manifest = Path("android/app/src/main/AndroidManifest.xml")
text = manifest.read_text(encoding="utf-8")

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
]

for permission in permissions:
    if permission.split('android:name="')[1].split('"')[0] not in text:
        text = text.replace('    <application', permission + '\n    <application', 1)

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
    text = text.replace("    </application>", service + "    </application>")

manifest.write_text(text, encoding="utf-8")
print("AndroidManifest.xml prepared for audio_service background playback.")
