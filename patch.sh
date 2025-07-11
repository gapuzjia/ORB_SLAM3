for file in ./Examples/Stereo-Inertial/*.yaml; do
  if ! grep -q "Viewer.Active" "$file"; then
    echo "Viewer.Active: 0" >> "$file"
  else
    sed -i 's/^Viewer\.Active:.*/Viewer.Active: 0/' "$file"
  fi
done

