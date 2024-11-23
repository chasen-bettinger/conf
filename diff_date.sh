#!/bin/bash
# Bash function to read a date from stdin
# and then calculate the number of days from that date
# to today.

# Date to compare
read -r target_date

# Get the current date in UTC
current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Convert both dates to seconds since the Unix epoch
target_seconds=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$target_date" "+%s")
current_seconds=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$current_date" "+%s")

# Calculate the difference in seconds
diff_seconds=$((current_seconds - target_seconds))

# Calculate the number of days
diff_days=$((diff_seconds / 86400))

# Print the result
echo "$diff_days days ago."

