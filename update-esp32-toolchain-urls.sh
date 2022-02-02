#!/bin/bash
set +euxo pipefail

manifest_url=https://raw.githubusercontent.com/espressif/esp-idf/master/tools/tools.json 
manifest_json=$(curl "${manifest_url}")
( touch esp32.manifest && printf '%s' "${manifest_json}" | jq -r '.tools[] | select(.name | test(".*-elf.*")) | .versions[]."linux-amd64" | select(.) | . += { "file": .url | split("/") | last } | "DIST \(.file) \(.size) SHA256 \(.sha256)"' && cat esp32.manifest ) | sort -u > esp32.manifest.new
mv esp32.manifest.new esp32.manifest
urls=$(printf '%s' "${manifest_json}" | jq -r '.tools[] | select(.name | test(".*-elf.*")) | .versions[]."linux-amd64".url | select(.)')
for u in ${urls}; do
    printf '%s\n' "${u}" > "$(basename "${u}").src-uri"
done
