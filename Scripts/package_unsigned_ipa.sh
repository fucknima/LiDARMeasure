#!/usr/bin/env bash
set -euo pipefail

BUILD_DIR="${1:-build}"
VERSION="${2:-0.1.0}"
ROOT_DIR="$(pwd)"
BUILD_DIR="$(cd "$BUILD_DIR" && pwd)"
APP_PATH="$(find "$BUILD_DIR" -type d -path '*/Release-iphoneos/LiDARMeasure.app' -print -quit)"

if [[ -z "$APP_PATH" || ! -d "$APP_PATH" ]]; then
  echo "LiDARMeasure.app was not found under $BUILD_DIR" >&2
  exit 1
fi

ARTIFACT_DIR="$ROOT_DIR/artifacts"
STAGING_DIR="$(mktemp -d)"
trap 'rm -rf "$STAGING_DIR"' EXIT
mkdir -p "$STAGING_DIR/Payload" "$ARTIFACT_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/Payload/"

IPA_PATH="$ARTIFACT_DIR/LiDARMeasure-v${VERSION}-unsigned.ipa"
rm -f "$IPA_PATH"
(cd "$STAGING_DIR" && zip -qr "$IPA_PATH" Payload)
echo "Created $IPA_PATH"
