#!/bin/sh

set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
developer_dir=${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}
output_dir="$repository_root/build"
derived_data="$output_dir/DerivedData"
package_dir=$(mktemp -d "${TMPDIR:-/tmp}/reantenna-ipa.XXXXXX")

cleanup() {
    rm -rf "$package_dir"
}
trap cleanup EXIT HUP INT TERM

export DEVELOPER_DIR="$developer_dir"

mkdir -p "$output_dir"

xcodebuild \
    -project "$repository_root/ReAntenna.xcodeproj" \
    -scheme ReAntenna \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -derivedDataPath "$derived_data" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    build

app_path="$derived_data/Build/Products/Release-iphoneos/ReAntenna.app"
ipa_path="$output_dir/ReAntenna-unsigned.ipa"

test -x "$app_path/ReAntenna"
mkdir -p "$package_dir/Payload"
ditto "$app_path" "$package_dir/Payload/ReAntenna.app"
rm -f "$ipa_path"
(
    cd "$package_dir"
    COPYFILE_DISABLE=1 /usr/bin/zip -qry -X "$ipa_path" Payload
)
unzip -t "$ipa_path"
file "$package_dir/Payload/ReAntenna.app/ReAntenna"

version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app_path/Info.plist")
build_number=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$app_path/Info.plist")
downloads_dir=${MACOS_DOWNLOADS_DIR:-"$HOME/Downloads"}
downloads_ipa="$downloads_dir/ReAntenna-$version-build-$build_number.ipa"

mkdir -p "$downloads_dir"
cp -p "$ipa_path" "$downloads_ipa"

echo "SideStore IPA: $ipa_path"
echo "macOS Downloads copy: $downloads_ipa"
