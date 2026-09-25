# Copyright (C) 2026 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0

# Galaxy F14 5G / M14 5G Exynos (SM-E146B) — codename m14x

PRODUCT_DEVICE := m14x
PRODUCT_NAME := lineage_m14x
PRODUCT_BRAND := samsung
PRODUCT_MODEL := SM-E146B
PRODUCT_MANUFACTURER := samsung

# Shipping API (vendor is VNDK 33 / first_api 33)
PRODUCT_SHIPPING_API_LEVEL := 33

# A/B — this device is A-only dynamic partitions
AB_OTA_UPDATER := false

# Dynamic partitions
PRODUCT_USE_DYNAMIC_PARTITIONS := true

# BootControl intentionally excluded — m14x is non-A/B (AB_OTA_UPDATER := false)

# Fstab & Vendor Boot Ramdisk
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/fstab.s5e8535:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.s5e8535 \
    $(LOCAL_PATH)/rootdir/etc/fstab.s5e8535:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/fstab.s5e8535 \
    $(LOCAL_PATH)/rootdir/etc/fstab.s5e8535:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/fstab.s5e8535 \
    $(LOCAL_PATH)/rootdir/etc/fstab.s5e8535:$(TARGET_COPY_OUT_RECOVERY)/root/first_stage_ramdisk/fstab.s5e8535

# Touchscreen firmware for vendor ramdisk (early boot display/touch)
PRODUCT_COPY_FILES += \
    vendor/samsung/m14x/proprietary/vendor/firmware/ft8720_m14x.bin:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/vendor/firmware/ft8720_m14x.bin \
    vendor/samsung/m14x/proprietary/vendor/firmware/ft8720_m14x_ramtest.bin:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/vendor/firmware/ft8720_m14x_ramtest.bin \
    vendor/samsung/m14x/proprietary/vendor/firmware/nt36672_m14x_csot.bin:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/vendor/firmware/nt36672_m14x_csot.bin \
    vendor/samsung/m14x/proprietary/vendor/firmware/nt36672_m14x_csot_mp.bin:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/vendor/firmware/nt36672_m14x_csot_mp.bin

# Ensure vendor ramdisk is non-empty
$(call inherit-product, $(SRC_TARGET_DIR)/product/ramdisk_stub.mk)

# Init (optional until stock RC files are extracted)
ifneq ($(wildcard $(LOCAL_PATH)/rootdir/etc/init.s5e8535.rc),)
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/init.s5e8535.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.s5e8535.rc
endif
ifneq ($(wildcard $(LOCAL_PATH)/rootdir/etc/ueventd.s5e8535.rc),)
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/ueventd.s5e8535.rc:$(TARGET_COPY_OUT_VENDOR)/etc/ueventd.rc
endif

# Characteristics
PRODUCT_CHARACTERISTICS := nosdcard

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH) \
    device/samsung/s5e8535-common

# Overlay placeholders
PRODUCT_ENFORCE_RRO_TARGETS := *

# Inherit proprietary blobs when extracted
$(call inherit-product-if-exists, vendor/samsung/m14x/m14x-vendor.mk)

# Security: Software KeyMint and Gatekeeper
PRODUCT_PACKAGES += \
    android.hardware.security.keymint-service \
    android.hardware.gatekeeper@1.0-service.software


# Audio
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/audio/mixer_paths.xml:$(TARGET_COPY_OUT_VENDOR)/etc/mixer_paths.xml

# Overlays
DEVICE_PACKAGE_OVERLAYS += $(LOCAL_PATH)/overlay

# Shims
PRODUCT_PACKAGES += \
    libdsms_vendor \
    libepicoperator \
    libhypervintf \
    libsensorndkbridge_shim

# Sensors
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/sensors/hals.conf:$(TARGET_COPY_OUT_VENDOR)/etc/sensors/hals.conf

# RIL
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/ril/sehradiomanager.conf:$(TARGET_COPY_OUT_VENDOR)/etc/sehradiomanager.conf

# RAM Plus
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/init.ramplus.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.ramplus.rc

# Vendor filesystem config for Samsung-specific AIDs
TARGET_FS_CONFIG_GEN := $(LOCAL_PATH)/config.fs

