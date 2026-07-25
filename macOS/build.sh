#!/bin/zsh
set -euo pipefail

script_dir="${0:A:h}"
output_root="${BASKETPET_OUTPUT_DIR:-${script_dir}/Build}"
app_path="${output_root}/只因你太美桌宠-120帧版.app"
contents="${app_path}/Contents"

mkdir -p "${output_root}" "${contents}/MacOS" "${contents}/Resources"
mkdir -p "${script_dir}/.module-cache"

CLANG_MODULE_CACHE_PATH="${script_dir}/.module-cache" /usr/bin/swiftc \
  -sdk /Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk \
  -target arm64-apple-macos13.0 \
  -O \
  -framework AppKit \
  "${script_dir}/Sources/main.swift" \
  -o "${script_dir}/.BasketPet-arm64"

CLANG_MODULE_CACHE_PATH="${script_dir}/.module-cache" /usr/bin/swiftc \
  -sdk /Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk \
  -target x86_64-apple-macos13.0 \
  -O \
  -framework AppKit \
  "${script_dir}/Sources/main.swift" \
  -o "${script_dir}/.BasketPet-x86_64"

/usr/bin/lipo -create \
  "${script_dir}/.BasketPet-arm64" \
  "${script_dir}/.BasketPet-x86_64" \
  -output "${contents}/MacOS/BasketPet"

rm "${script_dir}/.BasketPet-arm64" "${script_dir}/.BasketPet-x86_64"

cp "${script_dir}/Info.plist" "${contents}/Info.plist"
cp "${script_dir}/Assets/frames_v5/"*.png "${contents}/Resources/"

/usr/bin/codesign --force --deep --sign - "${app_path}"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent \
  "${app_path}" \
  "${output_root}/只因你太美桌宠-120帧版-macOS.zip"

echo "Built ${app_path}"
