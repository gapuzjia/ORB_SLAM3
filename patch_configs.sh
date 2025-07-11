#!/bin/bash

# Directory where your config files live
CONFIG_DIR="./Examples/Stereo-Inertial"

# List of required System parameters
REQUIRED_PARAMS=("enableOasis: true" "maskHeight: 4" "maskWidth: 4")

# Go through each .yaml file in the config directory
for file in "$CONFIG_DIR"/*.yaml; do
  echo "[PATCHING] $file"

  # Check if 'System:' exists
  if ! grep -q "^System:" "$file"; then
    echo "System:" >> "$file"
  fi

  # For each required param, insert it if it's missing
  for param in "${REQUIRED_PARAMS[@]}"; do
    key=$(echo "$param" | cut -d: -f1)
    if ! grep -q "^\s*${key}:" "$file"; then
      echo "  $param" >> "$file"
      echo "  → Added '$param'"
    fi
  done
done

echo "✅ All config files patched!"

