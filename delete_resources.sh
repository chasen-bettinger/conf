#!/bin/bash

# Get all resources with "details-v1" in the name
# resources=$(kubectl get all --all-namespaces -o name | grep -E 'reviews|details|productpage|ratings') 
resources=$(kubectl get all --namespace=ecommerce -o name) 

# Check if any resources were found
if [ -z "$resources" ]; then
    echo "No resources found containing 'details-v1'"
    exit 0
fi

# Print the resources that will be deleted
echo "The following resources will be deleted:"
echo "$resources"

Prompt for confirmation
read -p "Are you sure you want to delete these resources? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    # Delete the resources
    echo "$resources" | xargs kubectl delete --namespace=ecommerce
    echo "Resources deleted successfully."
else
    echo "Operation cancelled."
fi
