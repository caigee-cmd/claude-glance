#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/Vendor/LottieBinary"
OUTPUT_ZIP="$OUTPUT_DIR/Lottie.xcframework.zip"
URL="https://github.com/airbnb/lottie-ios/releases/download/4.6.0/Lottie.xcframework.zip"
SIZE=54955322
PARTS=8
CHUNK_SIZE=$(( (SIZE + PARTS - 1) / PARTS ))

mkdir -p "$OUTPUT_DIR"

for INDEX in $(seq 0 $((PARTS - 1))); do
  START=$(( INDEX * CHUNK_SIZE ))
  END=$(( START + CHUNK_SIZE - 1 ))
  if [[ "$END" -ge $((SIZE - 1)) ]]; then
    END=$((SIZE - 1))
  fi

  curl -L \
    -C - \
    -r "${START}-${END}" \
    -o "$OUTPUT_DIR/part.${INDEX}" \
    "$URL" &
done

wait
cat \
  "$OUTPUT_DIR/part.0" \
  "$OUTPUT_DIR/part.1" \
  "$OUTPUT_DIR/part.2" \
  "$OUTPUT_DIR/part.3" \
  "$OUTPUT_DIR/part.4" \
  "$OUTPUT_DIR/part.5" \
  "$OUTPUT_DIR/part.6" \
  "$OUTPUT_DIR/part.7" \
  > "$OUTPUT_ZIP"
