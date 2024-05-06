#!/usr/bin/env sh

TEMP_DIR="$(mktemp -d)"
cd "${TEMP_DIR}" || exit

repeat_str() {
  head -c "${1:-0}" </dev/zero | tr '\0' "${2:- }"
}

jellyfin() {
  # shellcheck disable=SC2068
  curl -s -H "X-MediaBrowser-Token: ${API_TOKEN}" $@
}

jellyfin "${BASE_URI}/Users" >'Users.json'
USER_ID="$(
  jq -r "$(
    printf '.[] | select(.Name=="%s").Id' "${USER_NAME}"
  )" 'Users.json'
)"

jellyfin "${BASE_URI}/Users/${USER_ID}/Items" >'Items.json'
jq -rc '.Items[] | {Id: .Id, Name: .Name}' 'Items.json' >'Folders.jsonl'

# shellcheck disable=SC3043
traverse_folders() {
  local FOLDERS_JSONL
  FOLDERS_JSONL="$1"
  local DEPTH
  DEPTH="${2:-0}"

  if [ -z "$(head "${FOLDERS_JSONL}")" ]; then
    return 0
  fi

  while read -r FOLDER_META; do
    FOLDER_ID="$(echo "${FOLDER_META}" | jq -r '.Id')"
    FOLDER_NAME="$(echo "${FOLDER_META}" | jq -r '.Name')"
    echo "$(repeat_str "${DEPTH}" '  ')- ${FOLDER_NAME}"

    jellyfin "${BASE_URI}/Users/${USER_ID}/Items?Fields=Path&ParentId=${FOLDER_ID}" >"${FOLDER_ID}.json"

    jq -rc '.Items[] | select(.IsFolder==false) | {Id: .Id, Name: .Name}' "${FOLDER_ID}.json" >"VideosIn${FOLDER_ID}.jsonl"

    jq -rc '.Items[] | select(.IsFolder==true) | {Id: .Id, Name: .Name}' "${FOLDER_ID}.json" >"FoldersIn${FOLDER_ID}.jsonl"

    while read -r VIDEO_META; do
      VIDEO_ID="$(echo "${VIDEO_META}" | jq -r '.Id')"
      VIDEO_NAME="$(echo "${VIDEO_META}" | jq -r '.Name')"

      jellyfin "${BASE_URI}/Users/${USER_ID}/Items/${VIDEO_ID}" >"Video-${VIDEO_ID}.json"

      VIDEO_FILENAME="$(
        basename "$(jq -r '.Path' "Video-${VIDEO_ID}.json")"
      )"
      VIDEO_PAYLOAD="$(
        jq -c "$(printf '. += {"Name": "%s"}' "${VIDEO_FILENAME%.*}")" "Video-${VIDEO_ID}.json"
      )"

      curl -s "${BASE_URI}/Items/${VIDEO_ID}" \
        -X POST \
        -H "X-MediaBrowser-Token: ${API_TOKEN}" \
        -H 'Content-Type: application/json' \
        --data-raw "${VIDEO_PAYLOAD}"

      echo "$(repeat_str "${DEPTH}" '  ')  v ${VIDEO_NAME}"

    done <"VideosIn${FOLDER_ID}.jsonl"

    traverse_folders "FoldersIn${FOLDER_ID}.jsonl" "$((DEPTH + 1))"

  done <"${FOLDERS_JSONL}"
}

traverse_folders 'Folders.jsonl'

cd /tmp || exit
rm -rf "${TEMP_DIR}"
