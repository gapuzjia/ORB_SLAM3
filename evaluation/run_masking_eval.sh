#!/bin/bash

# 🔧 Define ground truth files for each sequence
declare -A GT_FILES
GT_FILES[MH01]="path/to/MH01_gt.csv"
GT_FILES[MH02]="path/to/MH02_gt.csv"
GT_FILES[V101]="path/to/V101_gt.csv"
GT_FILES[V102]="path/to/V102_gt.csv"
GT_FILES[V103]="path/to/V103_gt.csv"
GT_FILES[V201]="path/to/V201_gt.csv"
GT_FILES[V202]="path/to/V202_gt.csv"
GT_FILES[V203]="path/to/V203_gt.csv"

# Output files
ate_csv="ATE_results.csv"
rpe_csv="RPE_results.csv"
plot_dir="ResultsErrorOverTime"

# Initialize CSVs
echo "run_id,dataset,rmse,mean,max,std,median" > "$ate_csv"
echo "run_id,dataset,trans_rmse,rot_rmse" > "$rpe_csv"
mkdir -p "$plot_dir"

# Loop through all result folders
for folder in 2025-*; do
    echo -e "\nChecking folder: $folder"

    # Determine dataset from folder name
    dataset=""
    for key in "${!GT_FILES[@]}"; do
        if [[ "$folder" == *"$key"* ]]; then
            dataset="$key"
            break
        fi
    done

    if [[ -z "$dataset" ]]; then
        echo "Could not determine dataset from folder: $folder"
        continue
    fi

    gt_file="${GT_FILES[$dataset]}"
    if [[ ! -f "$gt_file" ]]; then
        echo "Ground truth file not found: $gt_file"
        continue
    fi

    f_file=$(find "$folder" -maxdepth 1 -name "f_dataset-${dataset}_stereo_imu.txt")
    kf_file=$(find "$folder" -maxdepth 1 -name "kf_dataset-${dataset}_stereo_imu.txt")

    if [[ -z "$f_file" || -z "$kf_file" ]]; then
        echo "Missing f or kf file in $folder"
        continue
    fi

    # ---------------- ATE ----------------
    echo "ATE: $f_file"
    python3 evaluation/evaluate_ate_scale.py "$gt_file" "$f_file" --csv_output "$ate_csv"

    # ---------------- RPE ----------------
    echo "RPE: $kf_file"
    python3 evaluation/evaluate_rpe_scale_final.py --gt_file "$gt_file" --est_file "$kf_file" --csv "$rpe_csv"

    # ---------------- ERROR OVER TIME (SVG) ----------------
    echo "Error Over Time Plot"
    plot_output="${plot_dir}/${folder}_error_plot.svg"
    python3 evaluation/evaluate_error_over_time.py "$gt_file" "$f_file" --plot "$plot_output"

    echo "Done with: $folder"
done
