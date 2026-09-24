#
# Copyright (C) 2026 The crDroid Android Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from m14x device
$(call inherit-product, device/samsung/m14x/device.mk)

# Inherit some common crDroid stuff.
$(call inherit-product, vendor/crdroid/config/common_full_phone.mk)

PRODUCT_NAME := crdroid_m14x
PRODUCT_DEVICE := m14x
PRODUCT_BRAND := samsung
PRODUCT_MODEL := SM-E146B
PRODUCT_MANUFACTURER := samsung

PRODUCT_GMS_CLIENTID_BASE := android-samsung
