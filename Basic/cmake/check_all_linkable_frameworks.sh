#!/bin/bash
# License: MIT License
# See LICENSE.md for details.

# Get macOS SDK path
SDK_PATH=$(xcrun --sdk macosx --show-sdk-path)

# Target directories (Apple official + third-party)
FW_DIRS=(
  "$SDK_PATH/System/Library/Frameworks"
  # "/Library/Frameworks"
)

# Empty C++ source (for link testing)
TMP_SRC=$(mktemp /tmp/empty.XXXXXX.cpp)
echo 'int main() { return 0; }' > "$TMP_SRC"

# Display results
echo "Checking linkable frameworks... (this may take a few minutes)"

# Enumerate frameworks and check linkability
for dir in "${FW_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    find "$dir" -type d -name "*.framework" -depth 1 2>/dev/null | while read -r fw_path; do
      fw_name=$(basename "$fw_path" .framework)

      # Test if linkable with clang++
      clang++ "$TMP_SRC" -isysroot "$SDK_PATH" -F"$dir" -framework "$fw_name" -o /dev/null 2>/dev/null

      if [ $? -eq 0 ]; then
        echo "# \"-framework $fw_name\""
      fi
    done
  fi
done | sort -u

# Delete temporary file
rm -f "$TMP_SRC"
