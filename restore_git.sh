#!/bin/bash

# Iterate through all directories in the current path
for dir in */; do
    if [ -d "$dir" ]; then
        echo "Processing directory: $dir"
        # Change into directory
        cd "$dir"
        
        # Check if it's a git repository
        if [ -d ".git" ]; then
            echo "Running git restore in $dir"
            git restore .
        else
            echo "Skipping $dir - not a git repository"
        fi
        
        # Return to parent directory
        cd ..
    fi
done
