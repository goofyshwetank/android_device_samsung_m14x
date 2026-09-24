#!/usr/bin/env -S PYTHONPATH=../../../tools/extract-utils python3
# SPDX-License-Identifier: Apache-2.0
from extract_utils.main import ExtractUtils, ExtractUtilsModule

module = ExtractUtilsModule(
    'm14x',
    'samsung',
    namespace_imports=['device/samsung/m14x'],
)

if __name__ == '__main__':
    utils = ExtractUtils.device(module)
    utils.run()
