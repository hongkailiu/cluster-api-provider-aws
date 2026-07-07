#!/usr/bin/env bash

set -euo pipefail

if [[ -z "$MANIFESTS_FILE" ]]; then
    echo "The variable MANIFESTS_FILE must set."  >&2
    exit 1
fi

if [[ -z "$MANIFESTS_SUMMARY_FILE" ]]; then
    echo "The variable MANIFESTS_SUMMARY_FILE must set." >&2
    exit 1
fi

if ! command -v yq >/dev/null 2>&1 ; then
    echo "Command yq is not available. See https://github.com/kislyuk/yq for more information." >&2
    exit 1
fi

TMP_DIR=$(mktemp -d)

if [[ ! -d "$TMP_DIR" ]]; then
    echo "Could not create temporary directory" >&2
    exit 1
fi

trap 'rm -rf "$TMP_DIR"' EXIT

PROFILE="${PROFILE:-default}"

echo "The variable MANIFESTS_FILE=${MANIFESTS_FILE}"
echo "The variable MANIFESTS_SUMMARY_FILE=${MANIFESTS_SUMMARY_FILE}"
echo "The variable PROFILE=${PROFILE}"

TMP_LIST_FILE="$TMP_DIR/list.yaml"
TMP_RESULT_FILE="$TMP_DIR/result.yaml"

yq -s . "${MANIFESTS_FILE}" | yq 'map({apiVersion: .apiVersion, kind: .kind, name: .metadata.name, namespace: .metadata.namespace})' | yq -y 'map(with_entries(select(.value != null))) | sort_by(.kind, .apiVersion, .namespace, .name)' > "${TMP_LIST_FILE}"

yq -y --indentless-lists --arg key "$PROFILE" --argjson value "$(yq . "${TMP_LIST_FILE}")" '.[$key] = $value' "${MANIFESTS_SUMMARY_FILE}" > "${TMP_RESULT_FILE}"

mv "${TMP_RESULT_FILE}" "${MANIFESTS_SUMMARY_FILE}"
