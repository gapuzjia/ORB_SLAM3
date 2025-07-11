#!/bin/bash

# Create the destination folder if it doesn't exist
mkdir -p PrelimResults

# Move all folders that start with '2025' into PrelimResults
for dir in 2025*/ ; do
    if [ -d "$dir" ]; then
        mv "$dir" PrelimResults/
    fi
done

echo "Done. Moved all 2025* folders into PrelimResults/"

