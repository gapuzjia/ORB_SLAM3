#!/bin/bash

# Output CSV file
output_file="ATE_results.csv"
echo "Folder,ATE_RMSE_m,Runtime_ms" > "$output_file"

# Ground truth files
gt_mh01="./MH01data.csv"
gt_mh02="./MH02data.csv"

# Loop through all result folders
for folder in 2025-*; do
    echo -e "\nChecking folder: $folder"

    # Only process MH01 or MH02
    if [[ "$folder" == *"MH01"* ]]; then
        gt_file="$gt_mh01"
        seq="MH01"
    elif [[ "$folder" == *"MH02"* ]]; then
        gt_file="$gt_mh02"
        seq="MH02"
    else
        echo "Skipping $folder (not MH01 or MH02)"
        continue
    fi

    echo "Using GT file: $gt_file"

    # Look for f and kf files
    f_file=$(find "$folder" -maxdepth 1 -name "f_dataset-${seq}_stereo_imu.txt")
    kf_file=$(find "$folder" -maxdepth 1 -name "kf_dataset-${seq}_stereo_imu.txt")

    echo "Looking for f_dataset-${seq}_stereo_imu.txt in $folder"
    [[ -z "$f_file" ]] && echo "⚠️  No matching f file found." && ls "$folder"
    echo "Looking for kf_dataset-${seq}_stereo_imu.txt in $folder"
    [[ -z "$kf_file" ]] && echo "⚠️  No matching kf file found." && ls "$folder"

    # Skip if either file is missing
    if [[ -z "$f_file" || -z "$kf_file" ]]; then
        echo "Skipping ATE for $folder (missing f or kf)"
        continue
    fi

    # Run ATE evaluation
    echo "Running ATE on $f_file ..."
    start=$(date +%s%3N)
    ATE_OUTPUT=$(python3 evaluation/evaluate_ate_scale.py "$gt_file" "$f_file")
    end=$(date +%s%3N)
    runtime=$((end - start))

    # Parse RMSE value (first CSV field from script output)
    rmse=$(echo "$ATE_OUTPUT" | cut -d',' -f1)

    echo "Parsed ATE: $rmse"
    echo "Runtime: ${runtime} ms"

    # Save result to CSV
    echo "$folder,$rmse,$runtime" >> "$output_file"
    echo "Done: ATE=$rmse m, Runtime=${runtime} ms"
done

