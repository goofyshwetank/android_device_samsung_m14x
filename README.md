# Samsung Galaxy F14 5G (SM-E146B) — LineageOS 22.1

![Samsung Galaxy F14 5G](assets/sm-e146b.png)

**Codename:** m14x · **SoC:** Samsung Exynos 1330 (s5e8535) · **Android 15**

---

## Device Specifications

| Feature | Specification |
|---|---|
| Model | Samsung Galaxy F14 5G (SM-E146B) |
| Codename | m14x |
| SoC | Samsung Exynos 1330 (s5e8535) — Cortex-A76 × 2 + Cortex-A55 × 6 |
| RAM | 4 GB LPDDR4X |
| Storage | 64 / 128 GB eUFS 2.1 |
| Display | 6.6" PLS LCD, 1080 × 2408, 90 Hz |
| Battery | 6000 mAh, 25 W fast charge |
| Camera | 50 MP (main) + 2 MP (depth) · 13 MP front |
| Partitions | Non-A/B (A-only), Dynamic (super) |
| Boot | GKI 2.0 — boot header v4, vendor_boot, init_boot |
| VNDK | 33 (first API level 33) |
| OS shipped | Android 13 (OneUI 5.1) |

---

## Repository Structure

```
device/samsung/m14x/
├── BoardConfig.mk          # Partition layout, GKI config, non-A/B flags
├── device.mk               # HAL packages, feature flags
├── manifest.xml            # VINTF HAL declarations
├── vendor.prop             # ART heap sizing, board identity
├── system.prop             # System-side overrides
├── proprietary-files.txt   # Blob list for extract-files.py
├── rootdir/etc/            # Init RC files, fstab
└── sepolicy/vendor/        # SELinux policy stubs
```

---

## Companion Repositories

| Repository | Purpose |
|---|---|
| [android_vendor_samsung_m14x](https://github.com/goofyshwetank/android_vendor_samsung_m14x) | Proprietary blobs extracted from stock firmware |
| [android_kernel_samsung_s5e8535](https://github.com/goofyshwetank/android_kernel_samsung_s5e8535) | Kernel source for Exynos 1330 |

---

## Build Status

| Component | Status |
|---|---|
| Boot / system_server | Working |
| Display / Touch | Working |
| USB (ADB) | Working |
| Audio | Partial — HAL loads, stream routing incomplete |
| WiFi | Broken — wpa_supplicant CANNOT LINK |
| Bluetooth | Broken — FLAG_ONEWAY binder crash |
| Camera / Codec2 | Broken — VNDK namespace issue |
| GPS | Disabled — GNSS AIDL v2 not in Android 15 |
| Fingerprint / Face | Broken — TrustZone lib missing |
| Telephony (RIL) | Broken — com.android.phone ANR |

---

## Setting Up a Build

> Requires a full LineageOS 22.1 source tree initialized with `repo init`.

```bash
# Clone trees into your LineageOS source
git clone https://github.com/goofyshwetank/android_device_samsung_m14x     device/samsung/m14x

git clone https://github.com/goofyshwetank/android_vendor_samsung_m14x     vendor/samsung/m14x

git clone https://github.com/goofyshwetank/android_kernel_samsung_s5e8535     kernel/samsung/s5e8535

# Build
source build/envsetup.sh
breakfast m14x
m
```

---

## Fastboot Notes

- **Enter fastbootd:** `adb reboot fastboot` (NOT `adb reboot bootloader` — that opens Samsung Odin mode)
- **Flash vendor:** `fastboot flash vendor vendor.img && fastboot reboot`

---

## Known Important Fixes

- **BootControl excluded** — m14x is non-A/B. Adding `android.hardware.boot@*` will cause a crash loop on every boot.
- **GNSS AIDL v2 removed from manifest** — `android.hardware.gnss-V2-ndk.so` doesn't exist in Android 15; LocationManagerService blocks for 66 s waiting for it.
- **ART heap** — `dalvik.vm.heap*` must be set in `vendor.prop`; the default 16 MB cap causes OOM in system_server.
- **USB HIDL libs** — `android.hardware.usb@1.0`–`@1.3.so` must all be in `vendor/lib64/`; UsbService blocks `CompletableFuture.join()` indefinitely if the USB HAL can't link.

---

## Credits

Bring-up by [goofyshwetank](https://github.com/goofyshwetank) — LineageOS 22.1 (Android 15) port for SM-E146B.
