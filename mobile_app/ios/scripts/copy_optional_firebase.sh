#!/bin/sh
set -eu
source_file="${PROJECT_DIR}/Runner/GoogleService-Info.plist"
target_file="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/GoogleService-Info.plist"
if [ -f "$source_file" ]; then
  /bin/cp "$source_file" "$target_file"
elif [ -f "$target_file" ]; then
  /bin/rm "$target_file"
fi
