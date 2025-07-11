#!/bin/bash

set -e  # Exit on any error

DATE=$(date +"%Y-%m-%d_%H-%M-%S")

# === Function to run ORB-SLAM3 and save results ===
run_orbslam() {
  local config_file=$1
  local result_folder_prefix=$2
  local dataset=$3
  local run_number=$4
  local mask_name=$5

  local log_file="cout_${result_folder_prefix}_${dataset}_${mask_name}_run_${run_number}_${DATE}.log"

  # Format dataset directory
  local dataset_with_underscore
  if [[ $dataset == MH* ]]; then
    dataset_with_underscore="${dataset:0:2}_${dataset:2:2}"
  elif [[ $dataset == V* ]]; then
    dataset_with_underscore="V${dataset:1:1}_${dataset:2:2}"
  else
    dataset_with_underscore="$dataset"
  fi

  # Construct command
  local command="./Examples/Stereo-Inertial/stereo_inertial_euroc \
    ./Vocabulary/ORBvoc.txt $config_file \
    ./Datasets/EuRoc/${dataset_with_underscore}* \
    ./Examples/Stereo-Inertial/EuRoC_TimeStamps/${dataset}.txt \
    dataset-${dataset}_stereo_imu"

  echo "===================================================="
  echo "[RUNNING] $mask_name | $dataset | $result_folder_prefix | Run $run_number"
  echo "===================================================="
  echo "[INFO] Command: $command"

  # Execute and log output to both terminal and file
  eval "$command" 2>&1 | tee "$log_file"

  # Save results
  local result_folder="${DATE}_${result_folder_prefix}_${dataset}_${mask_name}_run_${run_number}"
  mkdir -p "$result_folder"
  mv "$log_file" LocalMapTimeStats.txt ExecMean.txt LBA_Stats.txt TrackingTimeStats.txt SessionInfo.txt 2>/dev/null "$result_folder"

  for file in map_points.csv "f_dataset-${dataset}_stereo_imu.txt" \
              "kf_dataset-${dataset}_stereo_imu.txt" "cellManager.txt"; do
    [[ -f $file ]] && mv "$file" "$result_folder"
  done

  echo "[SAVED] → $result_folder"
}

# === Parameters ===

NUM_RUNS=10

DATASETS=("MH01" "MH02" "MH03" "MH04" "MH05" "V101" "V102" "V103" "V201" "V202" "V203")

MASKS=("MaskCheckerboard" "MaskHorizontalStripes" "MaskVerticalStripes" "MaskRandom")

CONFIGURATIONS=(
  "./Examples/Stereo-Inertial/EuRoC_oasis.yaml result_oasis"
  "./Examples/Stereo-Inertial/EuRoC_deadlines.yaml result_deadlines"
  "./Examples/Stereo-Inertial/EuRoC_fov_deadlines.yaml result_fov_deadlines"
  "./Examples/Stereo-Inertial/EuRoC_fov.yaml result_fov"
  "./Examples/Stereo-Inertial/EuRoC.yaml result_normal"
)

# === Build list of commands ===

commands=()

for config_pair in "${CONFIGURATIONS[@]}"; do
  IFS=' ' read -r BASE_CONFIG RESULT_FOLDER_PREFIX <<< "$config_pair"
  for mask in "${MASKS[@]}"; do
    for ((i=1; i<=NUM_RUNS; i++)); do
      for dataset in "${DATASETS[@]}"; do
        commands+=("cp ./src/Masks/${mask}.cc ./src/CellManager.cc && \
                    rm -rf build && mkdir build && cd build && cmake .. && make -j\$(nproc) && cd .. && \
                    run_orbslam $BASE_CONFIG $RESULT_FOLDER_PREFIX $dataset $i $mask")
      done
    done
  done
done

# === Shuffle and Run Commands ===

shuffled_commands=$(printf "%s\n" "${commands[@]}" | shuf)

while IFS= read -r cmd; do
  eval "$cmd"
done <<< "$shuffled_commands"

