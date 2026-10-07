#!/usr/bin/env bash
set -euo pipefail

MOUNT_POINT="${NAS_MOUNT_POINT:-/home/n/share}"
TARGET_DIR="${NAS_TARGET_DIR:-/home/n/share/Backup/tg-archive/minio-data}"
TIMEOUT_SECONDS="${NAS_WAIT_TIMEOUT_SECONDS:-300}"
SLEEP_SECONDS="${NAS_WAIT_SLEEP_SECONDS:-5}"

deadline=$((SECONDS + TIMEOUT_SECONDS))

while (( SECONDS < deadline )); do
  systemctl reset-failed home-n-share.mount home-n-share.automount >/dev/null 2>&1 || true
  systemctl start home-n-share.automount >/dev/null 2>&1 || true

  # Touching the target path triggers the automount. Only accept a real mounted
  # NAS path so Docker never starts MinIO against a local fallback directory.
  if ls -ld "${TARGET_DIR}" >/dev/null 2>&1 && findmnt -rn "${MOUNT_POINT}" >/dev/null 2>&1; then
    exit 0
  fi

  sleep "${SLEEP_SECONDS}"
done

echo "Timed out waiting for NAS mount: ${TARGET_DIR}" >&2
systemctl status home-n-share.mount home-n-share.automount --no-pager -l >&2 || true
exit 1
