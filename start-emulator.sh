#!/bin/bash

# Check if the .first-boot-done file exists
if [ -f /data/.first-boot-done ]; then
  RAMDISK="-ramdisk /data/android.avd/ramdisk.img"
fi

# Start the emulator with the appropriate ramdisk.img
/opt/android-sdk/emulator/emulator -avd android -nojni -netfast -writable-system -no-window -no-audio -no-boot-anim -skip-adb-auth -gpu swiftshader_indirect -no-snapshot -no-metrics $RAMDISK -qemu -smp ${CPU_CORES:-4} -m ${RAM_SIZE:-8192}