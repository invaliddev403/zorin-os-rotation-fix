#!/usr/bin/env bash
set -euo pipefail
source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
device=${1:-auto}
case "$device" in
    auto)
        if [[ $(cat /sys/class/dmi/id/product_name) == V3 && -e /sys/bus/acpi/devices/SMOCF05:00 ]]; then
            device=v3
        elif compgen -G '/sys/bus/acpi/devices/KIOX000A:*' >/dev/null; then
            device=kiox
        else
            echo 'No supported sensor found. Supported: Minisforum V3 and KIOX000A.' >&2
            exit 1
        fi
        ;;
    v3|kiox) ;;
    *) echo 'Usage: setup-auto-rotate.sh [auto|v3|kiox]' >&2; exit 1 ;;
esac
if [[ $EUID != 0 ]]; then
    exec sudo bash "$source_dir/setup-auto-rotate.sh" "$device"
fi
if [[ $device == v3 ]]; then
    bash "$source_dir/minisforum-v3/install.sh"
else
    compgen -G '/sys/bus/acpi/devices/KIOX000A:*' >/dev/null || {
        echo 'KIOX000A sensor not found.' >&2; exit 1;
    }
    install -d /etc/udev/hwdb.d
    install -m 644 "$source_dir/61-kiox000a-sensor.hwdb" /etc/udev/hwdb.d/
    systemd-hwdb update
    udevadm trigger --subsystem-match=iio --action=change
    udevadm settle
    systemctl restart iio-sensor-proxy.service
fi
echo 'Done. Detach the keyboard and test landscape and both portrait directions.'
