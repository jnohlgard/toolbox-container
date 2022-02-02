#!/bin/bash
set +euxo pipefail

manifest_url=https://raw.githubusercontent.com/espressif/esp-idf/master/tools/tools.json 
( touch esp32.manifest && curl "${manifest_url}" | jq -r '.tools[] | select(.name | test(".*-elf.*")) | .versions[]."linux-amd64" | select(.) | . += { "file": .url | split("/") | last } | "\(.file) \(.size) SHA256 \(.sha256)"' && cat esp32.manifest ) | sort -u > esp32.manifest.new
mv esp32.manifest.new esp32.manifest
