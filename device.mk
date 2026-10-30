#
# Copyright (C) 2026 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

DEVICE_PATH := device/samsung/m14x

VENDOR_PATH := vendor/samsung/m14x

# Inherit from the m14x vendor
$(call inherit-product, vendor/samsung/m14x/m14x-vendor.mk)

# Inherit from the common tree
$(call inherit-product, device/samsung/s5e8535-common/common.mk)

# Audio
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/configs/audio/mixer_paths.xml:$(TARGET_COPY_OUT_VENDOR)/etc/mixer_paths.xml \
    $(DEVICE_PATH)/configs/audio/mixer_gains.xml:$(TARGET_COPY_OUT_VENDOR)/etc/mixer_gains.xml

# kernel firmwares
PRODUCT_COPY_FILES += \
    $(VENDOR_PATH)/proprietary/vendor/firmware/ft8720_m14x.bin:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/vendor/firmware/ft8720_m14x.bin \
    $(VENDOR_PATH)/proprietary/vendor/firmware/ft8720_m14x_ramtest.bin:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/vendor/firmware/ft8720_m14x_ramtest.bin \
    $(VENDOR_PATH)/proprietary/vendor/firmware/nt36672_m14x_csot.bin:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/vendor/firmware/nt36672_m14x_csot.bin \
    $(VENDOR_PATH)/proprietary/vendor/firmware/nt36672_m14x_csot_mp.bin:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/vendor/firmware/nt36672_m14x_csot_mp.bin

PRODUCT_COPY_FILES += \
    $(VENDOR_PATH)/proprietary/vendor/firmware/ft8720_m14x.bin:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/firmware/ft8720_m14x.bin \
    $(VENDOR_PATH)/proprietary/vendor/firmware/ft8720_m14x_ramtest.bin:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/firmware/ft8720_m14x_ramtest.bin \
    $(VENDOR_PATH)/proprietary/vendor/firmware/nt36672_m14x_csot.bin:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/firmware/nt36672_m14x_csot.bin \
    $(VENDOR_PATH)/proprietary/vendor/firmware/nt36672_m14x_csot_mp.bin:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/firmware/nt36672_m14x_csot_mp.bin

# Overlays
DEVICE_PACKAGE_OVERLAYS += $(DEVICE_PATH)/overlay

# Official builds ship without GApps. Personal builds export WITH_GMS=true.
ifeq ($(WITH_GMS),true)
$(call inherit-product-if-exists, vendor/gapps/arm64/arm64-vendor.mk)
endif

# VoLTE userspace. PhhIms source is packages/apps/PhhIms.
# LTE band picker defaults to auto and applies a band only when the user picks one.
PRODUCT_PACKAGES += \
    PhhIms \
    BandPref

PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/configs/permissions/privapp-permissions-me.phh.ims.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/privapp-permissions-me.phh.ims.xml \
    $(DEVICE_PATH)/configs/permissions/privapp-permissions-com.m14x.bandpref.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/privapp-permissions-com.m14x.bandpref.xml

PRODUCT_SOONG_NAMESPACES += $(DEVICE_PATH)

# Software KeyMint
PRODUCT_PACKAGES += \
    android.hardware.security.keymint-service

# Userdebug & ADB defaults
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    ro.debuggable=1 \
    ro.secure=0 \
    ro.adb.secure=0 \
    persist.sys.usb.config=adb
