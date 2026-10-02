# Zorin OS automatic rotation fixes

Supports the original **KIOX000A** accelerometer device and the **Minisforum V3**.
The setup script detects the device, installs its orientation rule, and restarts
`iio-sensor-proxy`. It preserves existing local sensor rules and discovers sensors
by name rather than assuming `/dev/iio:device0` is the accelerometer.

```bash
bash setup-auto-rotate.sh
```

The script requests sudo when needed. You can select a device explicitly with
`bash setup-auto-rotate.sh kiox` or `bash setup-auto-rotate.sh v3`.

## Minisforum V3

Verified on Zorin OS 18.1, GNOME/Wayland, kernel `7.0.0-38-generic`, BIOS 1.05.
The user confirmed correct rotation after installing the driver and corrected
orientation match.

If the SMOCF05 sensor has no driver, setup installs a small DKMS ACPI match
module that uses the distribution's existing `st_lsm6dsx` driver with the
LSM6DS3TR-C hardware ID. It does not replace that driver or modify ACPI firmware.
If a driver is already bound, setup only refreshes the orientation rule, so it
also supports a previously installed workaround or future native kernel support.

Prerequisites for installing the module:

```bash
sudo apt install dkms "linux-headers-$(uname -r)" iio-sensor-proxy mokutil
```

With Secure Boot enabled, Ubuntu's signing key at
`/var/lib/shim-signed/mok/MOK.der` must already be enrolled. DKMS uses its
corresponding private key. Setup accepts an explicit enrollment confirmation
even when `mokutil` returns a failure status due to a kernel-keyring query.
Loading the module still enforces the kernel's signature checks. Setup does
not disable Secure Boot or enroll a new key.

The V3 orientation matrix is `-1, 0, 0; 0, -1, 0; 0, 0, 1`, from
[upstream systemd](https://github.com/systemd/systemd/blob/main/hwdb.d/60-sensor.hwdb).
The manufacturer match accommodates udev 255 sanitizing parentheses into
underscores; without this, the matrix is not applied and rotation can be inverted.
The vendored driver header is from Linux v7.0 and retains its license notice.
DKMS rebuilds on kernel updates; future driver API changes may need an update.

To refresh only the matrix after an existing installation:

```bash
sudo bash minisforum-v3/refresh-orientation.sh
```

It prints the applied `ACCEL_MOUNT_MATRIX` property for the accelerometer.

## KIOX000A

Preserves the original matrix: `1, 0, 0; 0, -1, 0; 0, 0, 1`.
This is the correction for the original device, not a universal calibration for
every device with a KIOX000A sensor. The old `61-sensor-local.hwdb` is left intact;
the new script installs a separate file with the same correction.

## Verify

Run `monitor-sensor` and turn the tablet. It should report an accelerometer and
changes between `normal`, `left-up`, `right-up`, and `bottom-up`. Detach the
keyboard and unlock rotation in GNOME if needed. Check normal and inverted
landscape plus both portrait orientations, including touchscreen alignment.

## Remove

For V3, when migrating to a kernel with native sensor support:

```bash
sudo modprobe -r st_lsm6dsx_v3
sudo dkms remove -m minisforum-v3-rotation -v 0.1 --all
sudo rm -f /etc/udev/hwdb.d/61-minisforum-v3-sensor.hwdb
sudo systemd-hwdb update
sudo udevadm trigger --subsystem-match=iio --action=change
sudo systemctl restart iio-sensor-proxy.service
```

If using native support and keeping its orientation correction, retain the V3
hwdb file. Skip the module commands if it was never installed. For the original
device, remove `/etc/udev/hwdb.d/61-kiox000a-sensor.hwdb` and refresh hwdb/udev as
above; any previous `61-sensor-local.hwdb` correction remains active.
