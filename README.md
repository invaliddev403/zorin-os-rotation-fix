# Accelerometer Orientation Fix (KIOX000A)

This system uses a built-in accelerometer (`KIOX000A`) for screen auto-rotation.
By default, the orientation may be flipped in landscape mode. This fix applies a
correct mount matrix so GNOME rotates the display properly.

## Steps

1. Create `/etc/udev/hwdb.d/61-sensor-local.hwdb` with:

   ```ini
   sensor:modalias:acpi:KIOX000A:KIOX000A:
    ACCEL_MOUNT_MATRIX=1, 0, 0; 0, -1, 0; 0, 0, 1
