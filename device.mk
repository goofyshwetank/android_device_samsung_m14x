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
# Software KeyMint (the Android 13 Samsung service is not compatible here)
PRODUCT_PACKAGES += \
    android.hardware.security.keymint-service

# Stock gatekeeper service: TEEGRIS only accepts Samsung's own client binary, and the
# fingerprint TA verifies enrollment auth tokens against the TEE gatekeeper
PRODUCT_PACKAGES += \
    android.hardware.gatekeeper@1.0-impl

# AOSP builds of generic HAL services whose stock prebuilts clash with AOSP module names
# ponytail: memtrack uses the AOSP example (reports no GPU memory); memtrack-service.exynos
# lives in the hardware/samsung_slsi-linaro/graphics namespace, which clashes with vendor prebuilts.
PRODUCT_PACKAGES += \
    android.hardware.audio.service \
    android.hardware.audio@7.0-impl \
    android.hardware.audio.effect@7.0-impl \
    android.hardware.bluetooth.audio-impl \
    android.hardware.drm-service.clearkey \
    android.hardware.graphics.composer@2.4-service \
    android.hardware.memtrack-service.example \
    android.hardware.sensors@2.0-service.multihal \
    libsecc2_shim \
    libsensorndkbridge_shim \
    vndservicemanager \
    wpa_supplicant

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.fingerprint.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.fingerprint.xml

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
    $(LOCAL_PATH)

# Overlay placeholders
DEVICE_PACKAGE_OVERLAYS += $(LOCAL_PATH)/overlay
PRODUCT_ENFORCE_RRO_TARGETS := *

# Inherit proprietary blobs when extracted
$(call inherit-product-if-exists, vendor/samsung/m14x/m14x-vendor.mk)

# MindTheGapps (optional): git clone -b baklava https://gitlab.com/MindTheGapps/vendor_gapps vendor/gapps
# crDroid's LatinIME already defines libjni_latinimegoogle, so drop MindTheGapps' copy:
#   perl -0pi -e 's/cc_prebuilt_library_shared \{\n    name: "libjni_latinimegoogle".*?\n\}\n\n?//s' vendor/gapps/arm64/Android.bp
#   sed -i -e 's/Phonesky \\/Phonesky/' -e '/libjni_latinimegoogle/d' vendor/gapps/arm64/arm64-vendor.mk
$(call inherit-product-if-exists, vendor/gapps/arm64/arm64-vendor.mk)
