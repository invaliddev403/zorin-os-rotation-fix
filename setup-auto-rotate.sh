#!/bin/bash
# setup_sensor_matrix.sh

echo "[*] Setting up accelerometer mount matrix..."

cat <<EOF | sudo tee /etc/udev/hwdb.d/61-sensor-local.hwdb >/dev/null
sensor:modalias:acpi:KIOX000A:KIOX000A:
 ACCEL_MOUNT_MATRIX=1, 0, 0; 0, -1, 0; 0, 0, 1
EOF

sudo chmod 644 /etc/udev/hwdb.d/61-sensor-local.hwdb
sudo systemd-hwdb update

DEVICE_PATH="/sys$(udevadm info -q path -n /dev/iio:device0)"
echo "[*] Triggering udev for $DEVICE_PATH"
sudo udevadm trigger -v "$DEVICE_PATH"

echo "[*] Done. Confirm with:"
echo "    udevadm info $DEVICE_PATH | grep ACCEL"
