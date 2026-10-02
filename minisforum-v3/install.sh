#!/usr/bin/env bash
set -euo pipefail
[[ $EUID == 0 ]] || { echo 'Run with sudo.' >&2; exit 1; }
[[ $(cat /sys/class/dmi/id/product_name) == V3 ]] || { echo 'This installer is for the V3.' >&2; exit 1; }
source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
kernel_version=$(uname -r)
[[ -e /sys/bus/i2c/devices/i2c-SMOCF05:00 ]] || {
    echo 'V3 SMOCF05 sensor not found.' >&2; exit 1;
}
# Existing workaround or native support: only refresh the orientation rule.
if [[ ! -L /sys/bus/i2c/devices/i2c-SMOCF05:00/driver ]]; then
    command -v dkms >/dev/null || { echo 'Install dkms first.' >&2; exit 1; }
    [[ -d /lib/modules/$kernel_version/build ]] || {
        echo "Install linux-headers-$kernel_version first." >&2; exit 1;
    }
    if mokutil --sb-state | grep -q 'SecureBoot enabled'; then
        if enrollment_output=$(LC_ALL=C mokutil --test-key /var/lib/shim-signed/mok/MOK.der 2>&1); then
            printf '%s\n' "$enrollment_output"
        else
            printf '%s\n' "$enrollment_output"
            grep -Fxq '/var/lib/shim-signed/mok/MOK.der is already enrolled' <<< "$enrollment_output" || {
                echo 'Could not confirm signing-key enrollment; installation stopped.' >&2; exit 1;
            }
        fi
    fi
    if [[ -z $(dkms status -m minisforum-v3-rotation -v 0.1) ]]; then
        install -d /usr/src/minisforum-v3-rotation-0.1
        install -m 644 "$source_dir"/{st_lsm6dsx_v3.c,st_lsm6dsx.h,Makefile,dkms.conf} /usr/src/minisforum-v3-rotation-0.1/
        dkms add -m minisforum-v3-rotation -v 0.1
    fi
    dkms build -m minisforum-v3-rotation -v 0.1 -k "$kernel_version"
    dkms install -m minisforum-v3-rotation -v 0.1 -k "$kernel_version"
    modprobe st_lsm6dsx_v3
    [[ -L /sys/bus/i2c/devices/i2c-SMOCF05:00/driver ]] || {
        echo 'Module loaded but sensor did not bind; inspect the kernel log.' >&2; exit 1;
    }
fi
bash "$source_dir/refresh-orientation.sh"
