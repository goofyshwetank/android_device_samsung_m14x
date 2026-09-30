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
        .add_line_if_missing('(allow vendor_init_33_0 sysfs_ss_writable (file (write open getattr)))'),
    'vendor/etc/selinux/vendor_service_contexts': blob_fixup()
        .add_line_if_missing(
            'android.hardware.security.sharedsecret.ISharedSecret/gatekeeper u:object_r:hal_sharedsecret_service:s0'
        ),
    (
        'vendor/lib/libexynosgraphicbuffer.so',
        'vendor/lib64/libexynosgraphicbuffer.so',
    ): blob_fixup()
        .add_needed('libui_shim.so'),
    'vendor/bin/hw/vendor.samsung.hardware.health-service': blob_fixup()
        .add_needed('libbase_shim.so'),
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
