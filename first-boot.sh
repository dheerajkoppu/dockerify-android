#!/bin/bash

# apply settings
apply_settings() {
  adb wait-for-device
  COMPLETED=$(adb shell getprop sys.boot_completed | tr -d '\r')
  while [ "$COMPLETED" != "1" ]; do
    COMPLETED=$(adb shell getprop sys.boot_completed | tr -d '\r')
    sleep 5
  done
  adb root
  adb shell settings put global window_animation_scale 0
  adb shell settings put global transition_animation_scale 0
  adb shell settings put global animator_duration_scale 0
  adb shell settings put global stay_on_while_plugged_in 0
  adb shell settings put system screen_off_timeout 15000
  adb shell settings put system accelerometer_rotation 0
  adb shell settings put global private_dns_mode hostname
  adb shell settings put global private_dns_specifier ${DNS:-one.one.one.one}
  adb shell settings put global airplane_mode_on 1
  adb shell am broadcast -a android.intent.action.AIRPLANE_MODE --ez state true
  adb shell svc data disable
  adb shell svc wifi enable
}

# Detect IP and forward ADB ports
LOCAL_IP=$(ip addr list eth0 | grep "inet " | cut -d' ' -f6 | cut -d/ -f1)
socat tcp-listen:"5555",bind="$LOCAL_IP",fork tcp:127.0.0.1:"5555" &

echo "Emulator is healthy. Proceeding..."

if [ -f /data/.first-boot-done ]; then
  apply_settings
  exit 0
fi

echo "Init AVD ..."

echo "no" | avdmanager create avd -n android -k "system-images;android-34;google_atd;x86_64" -d 48

echo "Preparation ..."

adb wait-for-device
adb root
adb shell avbctl disable-verification
adb disable-verity
adb reboot
adb wait-for-device
adb root
adb remount

for f in $(ls /extras/*); do
  adb push $f /sdcard/Download/
done

echo "Root Script Starting..."

git clone https://gitlab.com/newbit/rootAVD.git
pushd rootAVD
sed -i 's/read -t 10 choice/choice=1/' rootAVD.sh
./rootAVD.sh system-images/android-34/google_atd/x86_64/ramdisk.img
cp /opt/android-sdk/system-images/android-34/google_atd/x86_64/ramdisk.img /data/android.avd/ramdisk.img
popd

echo "Root Done"
sleep 15

echo "Cleanup ..."
rm -r rootAVD
apply_settings
touch /data/.first-boot-done
echo "Success !!"
