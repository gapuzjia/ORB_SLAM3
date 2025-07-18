#!/bin/bash
set -e  # Exit on error

MASK_NAME="MaskCheckerboard"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
NUM_RUNS=1


DATASETS=("MH01" "MH02" "MH03" "MH04" "MH05" "V101" "V102" "V103" "V201" "V202" "V203")

CONFIGURATIONS=(
  "./Examples/Stereo-Inertial/EuRoC_oasis.yaml result_oasis"
  "./Examples/Stereo-Inertial/EuRoC_deadlines.yaml result_deadlines"
  "./Examples/Stereo-Inertial/EuRoC_fov_deadlines.yaml result_fov_deadlines"
  "./Examples/Stereo-Inertial/EuRoC_fov.yaml result_fov"
  "./Examples/Stereo-Inertial/EuRoC.yaml result_normal"
)

EXE="./Examples/Stereo-Inertial/stereo_inertial_euroc_${MASK_NAME}"

#run all configs, datasets, and repetitions
run_orbslam() {
  local config_file=$1
  local result_folder_prefix=$2
  local dataset=$3
  local run_number=$4

  local dataset_with_underscore
  if [[ $dataset == MH* ]]; then
    dataset_with_underscore="${dataset:0:2}_${dataset:2:2}"
  elif [[ $dataset == V* ]]; then
    dataset_with_underscore="V${dataset:1:1}_${dataset:2:2}"
  else
    dataset_with_underscore="$dataset"
  fi

  local log_file="cout_${result_folder_prefix}_${dataset}_${MASK_NAME}_run${run_number}_${DATE}.log"
  local result_folder="${DATE}_${result_folder_prefix}_${dataset}_${MASK_NAME}_run${run_number}"

	./Examples/Stereo-Inertial/stereo_inertial_euroc \
		./Vocabulary/ORBvoc.txt $config_file \
  		./Datasets/EuRoc/${dataset_with_underscore}* \
  		./Examples/Stereo-Inertial/EuRoC_TimeStamps/${dataset}.txt \
 		 dataset-${dataset}_stereo_imu \
  		"$MASK_NAME" "$dataset" "$result_folder_prefix" "$run_number" \
  		2>&1 | tee "$log_file"

  mkdir -p "$result_folder"
  mv "$log_file" "$result_folder"

  #let I/O finish before moving
  sleep 1
  for file in LocalMapTimeStats.txt ExecMean.txt LBA_Stats.txt TrackingTimeStats.txt SessionInfo.txt \
              map_points.csv "f_dataset-${dataset}_stereo_imu.txt" \
              "kf_dataset-${dataset}_stereo_imu.txt" "cellManager.txt"; do
    [[ -f $file ]] && mv "$file" "$result_folder"
  done

  echo "[SAVED] → $result_folder"
}

#execute all runs
for config_pair in "${CONFIGURATIONS[@]}"; do
  IFS=' ' read -r CONFIG_FILE RESULT_PREFIX <<< "$config_pair"
  for dataset in "${DATASETS[@]}"; do
    for ((i=1; i<=NUM_RUNS; i++)); do
      run_orbslam "$CONFIG_FILE" "$RESULT_PREFIX" "$dataset" "$i"
    done
  done
done

