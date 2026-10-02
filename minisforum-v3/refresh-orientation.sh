#!/usr/bin/env bash
set -euo pipefail
[[ $EUID == 0 ]] || { echo 'Run with sudo.' >&2; exit 1; }
[[ $(cat /sys/class/dmi/id/product_name) == V3 ]] || exit 1
source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
install -m 644 "$source_dir/61-minisforum-v3-sensor.hwdb" /etc/udev/hwdb.d/
systemd-hwdb update
udevadm trigger --subsystem-match=iio --action=change
udevadm settle
for device in /sys/bus/iio/devices/iio:device*; do
    if [[ $(cat "$device/name") == lsm6ds3tr-c_accel ]]; then
        udevadm info -q property -p "$device" | grep '^ACCEL_MOUNT_MATRIX='
    fi
done
systemctl restart iio-sensor-proxy.service
