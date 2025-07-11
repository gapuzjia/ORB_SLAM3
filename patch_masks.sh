#!/bin/bash

MASK_DIR="./src/Masks"
PARAMS=("System.maskHeight" "System.maskWidth" "System.enableOasis")

echo "[INFO] Patching all CellManager mask variants in: $MASK_DIR"

for file in "$MASK_DIR"/*.cc; do
  echo "→ Patching $file"

  for param in "${PARAMS[@]}"; do
    key=$(echo "$param" | cut -d. -f2)

    # Check if the line accesses the setting directly without checking
    if grep -q "settings\[\"$param\"\]" "$file"; then
      echo "  - Patching $param"
      
      # Replace direct access with safe fallback
      sed -i "s/settings\[\"$param\"\]/(settings.exist(\"$param\") ? settings[\"$param\"] : 0)/g" "$file"
    fi
  done
done

echo "✅ All mask files patched safely."

