#!/bin/bash

# Define the paths to your executables
EXEC1="./run_mask_random.sh"
EXEC2="./run_mask_vertical.sh"
EXEC3="./run_mask_horizontal.sh"
EXEC4="./run_mask_checkerboard.sh"

# Run each executable and log the output
echo "Running Checkerboard..."
$EXEC1

echo "Running Horizontal Stripes..."
$EXEC2

echo "Running Vertical Stripes..."
$EXEC3

echo "Running Random Mask..."
$EXEC4

echo "All runs completed."

