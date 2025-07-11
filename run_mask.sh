#!/bin/bash
set -e

MASK_NAME="MaskCheckerboard"
RESULTS_DIR="Results/checkerboard"

echo "[INFO] Using mask: $MASK_NAME"

# Replace CellManager.cc with the desired mask
cp ./src/Masks/${MASK_NAME}.cc ./src/CellManager.cc

# Rebuild the system
echo "[INFO] Rebuilding ORB-SLAM3..."
rm -rf build
mkdir build
cd build
cmake ..
make -j$(nproc)
cd ..

# Make results folder
mkdir -p "$RESULTS_DIR"

# Run ORB-SLAM3
echo "[INFO] Running ORB-SLAM3..."
./Examples/Stereo-Inertial/stereo_inertial_euroc \
    ./Vocabulary/ORBvoc.txt \
    ./Examples/Stereo-Inertial/EuRoC_oasis.yaml \
    ./Datasets/EuRoc/MH_01_easy \
    ./Examples/Stereo-Inertial/EuRoC_TimeStamps/MH01.txt \
    > "$RESULTS_DIR/log.txt" 2>&1

# If trajectory is saved (depends on config), move it too
if [ -f CameraTrajectory.txt ]; then
    mv CameraTrajectory.txt "$RESULTS_DIR/"
fi

if [ -f KeyFrameTrajectory.txt ]; then
    mv KeyFrameTrajectory.txt "$RESULTS_DIR/"
fi

echo "[INFO] Results saved to $RESULTS_DIR"

