#!/bin/bash
set -e

MASK_DIR="./src/Masks"
RESULTS_DIR="./Results"
DATASET_DIR="./Datasets/EuRoc/MH_01_easy"

for MASK_PATH in "$MASK_DIR"/*.cc; do
    MASK_FILE=$(basename "$MASK_PATH")
    MASK_NAME="${MASK_FILE%.*}"  # Remove extension
    OUTPUT_DIR="${RESULTS_DIR}/${MASK_NAME}"

    echo "============================="
    echo "[INFO] Running with: $MASK_NAME"
    echo "============================="

    # Replace CellManager.cc
    cp "$MASK_PATH" ./src/CellManager.cc

    # Rebuild
    echo "[INFO] Building $MASK_NAME..."
    rm -rf build
    mkdir build
    cd build
    cmake ..
    make -j$(nproc)
    cd ..

    # Create results folder
    mkdir -p "$OUTPUT_DIR"

    # Run ORB-SLAM3
    echo "[INFO] Running SLAM with $MASK_NAME..."
    ./Examples/Stereo-Inertial/stereo_inertial_euroc \
        ./Vocabulary/ORBvoc.txt \
        ./Examples/Stereo-Inertial/EuRoC_oasis.yaml \
        "$DATASET_DIR" \
        ./Examples/Stereo-Inertial/EuRoC_TimeStamps/MH01.txt \
        > "${OUTPUT_DIR}/log.txt" 2>&1

    # Move output files
    [ -f CameraTrajectory.txt ] && mv CameraTrajectory.txt "${OUTPUT_DIR}/"
    [ -f KeyFrameTrajectory.txt ] && mv KeyFrameTrajectory.txt "${OUTPUT_DIR}/"
    [ -f cellManager.txt ] && mv cellManager.txt "${OUTPUT_DIR}/"

    echo "[DONE] Results saved to $OUTPUT_DIR"
done

echo "All masks finished!"

