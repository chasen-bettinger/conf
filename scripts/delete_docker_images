#!/bin/bash

# Function to delete Docker images by pattern
delete_docker_images_by_pattern() {
    local pattern=$1
    
    # List images matching the pattern
    images=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -E "^ghcr\.io.*(reviews|details|productpage|ratings)")
    
    if [ -z "$images" ]; then
        echo "No images found matching the pattern: $pattern"
        return
    fi
    
    echo "The following images will be deleted:"
    echo "$images"
    
    read -p "Are you sure you want to proceed? (y/N) " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        echo "$images" | xargs -I {} docker rmi {} --force
        echo "Images deleted successfully."
    else
        echo "Operation cancelled."
    fi
}

# Usage
delete_docker_images_by_pattern
