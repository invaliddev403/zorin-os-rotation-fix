// SPDX-License-Identifier: GPL-2.0-only
// V3 ACPI match shim; sensor handling stays in the distribution's driver.
#include <linux/module.h>
#include <linux/i2c.h>
#include <linux/regmap.h>
#include "st_lsm6dsx.h"

static const struct regmap_config v3_regmap = {
    .reg_bits = 8,
    .val_bits = 8,
};

static int v3_probe(struct i2c_client *client)
{
    struct regmap *map = devm_regmap_init_i2c(client, &v3_regmap);

    if (IS_ERR(map))
        return PTR_ERR(map);
    return st_lsm6dsx_probe(&client->dev, client->irq,
                          ST_LSM6DS3TRC_ID, map);
}

static const struct acpi_device_id v3_acpi_ids[] = {
    { "SMOCF05", ST_LSM6DS3TRC_ID },
    { }
};
MODULE_DEVICE_TABLE(acpi, v3_acpi_ids);

static struct i2c_driver v3_driver = {
    .driver = {
        .name = "st_lsm6dsx_v3",
        .acpi_match_table = v3_acpi_ids,
        .pm = pm_sleep_ptr(&st_lsm6dsx_pm_ops),
    },
    .probe = v3_probe,
};
module_i2c_driver(v3_driver);
MODULE_DESCRIPTION("Minisforum V3 SMOCF05 sensor match");
MODULE_LICENSE("GPL");
MODULE_IMPORT_NS("IIO_LSM6DSX");
