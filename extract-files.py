#!/usr/bin/env -S PYTHONPATH=../../../tools/extract-utils python3
# SPDX-License-Identifier: Apache-2.0
from extract_utils.fixups_blob import blob_fixup, blob_fixups_user_type
from extract_utils.main import ExtractUtils, ExtractUtilsModule

blob_fixups: blob_fixups_user_type = {
    'vendor/etc/selinux/vendor_sepolicy.cil': blob_fixup()
        .regex_replace(
            r'\(genfscon sysfs "/bus/usb/devices" \(u object_r sysfs_ss_writable \(\(s0\) \(s0\)\)\)\)\n?',
            '',
        )
        .regex_replace(
            r'\(genfscon iso9660 "/" \(u object_r vfat \(\(s0\) \(s0\)\)\)\)\n?',
            '',
        )
        .regex_replace(
            r'\(genfscon proc "/sys/vm/dirty_background_bytes" \(u object_r proc_dirty \(\(s0\) \(s0\)\)\)\)\n?',
            '',
        )
        .regex_replace(
            r'\(genfscon proc "/sys/vm/dirty_bytes" \(u object_r proc_dirty \(\(s0\) \(s0\)\)\)\)\n?',
            '',
        )
        .regex_replace(
            r'\(genfscon udf "/" \(u object_r vfat \(\(s0\) \(s0\)\)\)\)\n?',
            '',
        )
        .add_line_if_missing('(allow hal_gatekeeper_default hal_sharedsecret_service_33_0 (service_manager (add find)))')
        .add_line_if_missing('(allow keystore_33_0 hal_gatekeeper_default (binder (call)))')
        .add_line_if_missing('(allow vendor_init_33_0 sysfs_ss_writable (file (write open getattr)))')
        .add_line_if_missing('(allow init_33_0 vendor_shell_33_0 (process (transition rlimitinh siginh noatsecure)))')
        .add_line_if_missing('(allow hal_camera_default fwk_sensor_service (service_manager (find)))')
        .add_line_if_missing('(type sehradio)')
        .add_line_if_missing('(roletype object_r sehradio)')
        .add_line_if_missing('(typeattributeset domain (sehradio))')
        .add_line_if_missing('(type sehradio_exec)')
        .add_line_if_missing('(roletype object_r sehradio_exec)')
        .add_line_if_missing('(typeattributeset file_type (sehradio_exec))')
        .add_line_if_missing('(typeattributeset exec_type (sehradio_exec))')
        .add_line_if_missing('(typeattributeset vendor_file_type (sehradio_exec))')
        .add_line_if_missing('(typetransition init_33_0 sehradio_exec process sehradio)')
        .add_line_if_missing('(allow init_33_0 sehradio_exec (file (read getattr map execute open)))')
        .add_line_if_missing('(allow init_33_0 sehradio (process (transition siginh rlimitinh noatsecure)))')
        .add_line_if_missing('(allow sehradio sehradio_exec (file (read getattr map execute open entrypoint)))')
        .add_line_if_missing('(allow sehradio binder_device_33_0 (chr_file (ioctl read write getattr map open)))')
        .add_line_if_missing('(allow sehradio servicemanager_33_0 (binder (call transfer)))')
        .add_line_if_missing('(allow servicemanager_33_0 sehradio (binder (call transfer)))')
        .add_line_if_missing('(allow servicemanager_33_0 sehradio (dir (search)))')
        .add_line_if_missing('(allow servicemanager_33_0 sehradio (file (read open)))')
        .add_line_if_missing('(allow servicemanager_33_0 sehradio (process (getattr)))')
        .add_line_if_missing('(allow sehradio hal_radio_service_33_0 (service_manager (find)))')
        .add_line_if_missing('(allow sehradio rild (binder (call transfer)))')
        .add_line_if_missing('(allow sehradio rild (fd (use)))')
        .add_line_if_missing('(allow rild sehradio (binder (call transfer)))')
        .add_line_if_missing('(allow rild sehradio (fd (use)))'),
    'vendor/etc/selinux/vendor_file_contexts': blob_fixup()
        .add_line_if_missing('/(vendor|system/vendor)/bin/sehradio u:object_r:sehradio_exec:s0')
        .add_line_if_missing(
            '/(vendor|system/vendor)/bin/hw/android\\.hardware\\.security\\.keymint-service\\.samsung u:object_r:hal_keymint_default_exec:s0'
        ),
    'vendor/etc/init/android.hardware.security.keymint-service.samsung.rc': blob_fixup()
        .regex_replace('(?m)keymint-service$', 'keymint-service.samsung'),
    'vendor/etc/selinux/vendor_service_contexts': blob_fixup()
        .add_line_if_missing(
            'android.hardware.security.sharedsecret.ISharedSecret/gatekeeper u:object_r:hal_sharedsecret_service:s0'
        ),
    # Stock routes A2DP through Samsung's own policy file; the AOSP stack needs the bluetooth module
    'vendor/etc/audio_policy_configuration.xml': blob_fixup()
        .regex_replace(
            r'(?m)^    </modules>',
            '        <xi:include href="bluetooth_audio_policy_configuration.xml" />\n    </modules>',
        ),
    'vendor/lib/libexynosgraphicbuffer.so': blob_fixup()
        .add_needed('libui_shim.so'),
    # lockYCbCr64 calls GrallocMapper's vtable directly: slot 0x50 was lock(ycbcr) on
    # Android 13 but is unlock() on Android 16, where lock(ycbcr) moved to 0x48
    'vendor/lib64/libexynosgraphicbuffer.so': blob_fixup()
        .add_needed('libui_shim.so')
        .binary_regex_replace(b'\x08\x00\x40\xf9\x08\x29\x40\xf9', b'\x08\x00\x40\xf9\x08\x25\x40\xf9'),
    'vendor/lib64/libSecC2ComponentStore.so': blob_fixup()
        .binary_regex_replace(b'_ZN17C2PooledBlockPool', b'_ZN17C2PooledBlockPoox')
        .add_needed('libsecc2_shim.so'),
    'vendor/bin/hw/vendor.samsung.hardware.health-service': blob_fixup()
        .add_needed('libbase_shim.so'),
    (
        'vendor/bin/hw/android.hardware.wifi@1.0-service',
        'vendor/bin/hw/vendor.samsung.hardware.wifi@2.0-service',
    ): blob_fixup()
        .replace_needed('libwifi-hal.so', 'libwifi-hal-samsung.so'),
    (
        'vendor/lib/libwifi-hal-samsung.so',
        'vendor/lib64/libwifi-hal-samsung.so',
    ): blob_fixup()
        .fix_soname(),
    'vendor/etc/init/android.hardware.bluetooth@1.1-service.rc': blob_fixup()
        .regex_replace('(?m)bluetooth@1.1-service$', 'bluetooth@1.1-service.samsung'),
    'vendor/etc/init/vendor.samsung.rild.rc': blob_fixup()
        .regex_replace('(?m)/vendor/bin/hw/rild$', '/vendor/bin/hw/rild_exynos'),
    'vendor/bin/hw/android.hardware.bluetooth@1.1-service.samsung': blob_fixup()
        .replace_needed('android.hardware.bluetooth@1.0-impl.so', 'android.hardware.bluetooth@1.0-impl-samsung.so'),
    'vendor/lib64/hw/android.hardware.bluetooth@1.0-impl-samsung.so': blob_fixup()
        .fix_soname()
        .binary_regex_replace(b'libbt-vendor.so\x00', b'libbt-exynos.so\x00'),
    (
        'vendor/lib64/libbt-exynos.so',
        'vendor/lib64/lib_profiler-samsung.so',
        'vendor/lib/libtinyalsa-samsung.so',
        'vendor/lib64/libtinyalsa-samsung.so',
    ): blob_fixup()
        .fix_soname(),
    (
        'vendor/lib/libaudioroute-samsung.so',
        'vendor/lib64/libaudioroute-samsung.so',
    ): blob_fixup()
        .fix_soname()
        .replace_needed('libtinyalsa.so', 'libtinyalsa-samsung.so'),
    (
        'vendor/lib/libaboxpcmdump.so',
        'vendor/lib64/libaboxpcmdump.so',
        'vendor/lib/libaudioparamupdate.so',
        'vendor/lib64/libaudioparamupdate.so',
        'vendor/lib/libaudioproxy2.so',
        'vendor/lib64/libaudioproxy2.so',
        'vendor/lib/hw/audio.primary.s5e8535.so',
        'vendor/lib64/hw/audio.primary.s5e8535.so',
        'vendor/lib/libalsautils_sec.so',
        'vendor/lib64/libalsautils_sec.so',
        'vendor/lib/soundfx/libaudioeffectoffload.so',
        'vendor/lib64/soundfx/libaudioeffectoffload.so',
    ): blob_fixup()
        .replace_needed('libaudioroute.so', 'libaudioroute-samsung.so')
        .replace_needed('libtinyalsa.so', 'libtinyalsa-samsung.so'),
    (
        'vendor/lib64/libsamsungcamerahalutils.so',
        'vendor/lib64/libsamsungcamerahwl_impl.so',
        'vendor/lib64/libsamsungcamerahal.so',
        'vendor/bin/hw/vendor.samsung.hardware.camera.provider-service_64',
    ): blob_fixup()
        .replace_needed('lib_profiler.so', 'lib_profiler-samsung.so'),
    'vendor/lib64/unihal_android.so': blob_fixup()
        .add_needed('libui_shim.so')
        .add_needed('libsensorndkbridge_shim.so'),
    (
        'vendor/lib64/libhypermotion_core.so',
        'vendor/lib64/libsensorlistener.so',
    ): blob_fixup()
        .add_needed('libsensorndkbridge_shim.so'),
}

module = ExtractUtilsModule(
    'm14x',
    'samsung',
    blob_fixups=blob_fixups,
    namespace_imports=['device/samsung/m14x'],
)

if __name__ == '__main__':
    utils = ExtractUtils.device(module)
    utils.run()
