#!/usr/bin/env bash

regex_pattern="${POD_REGEX_PATTERN}"

echo "The regex pattern is: $regex_pattern"

if [ -z "$regex_pattern" ]; then
    echo "The POD_REGEX_PATTERN environment variable is not set or is empty."
    exit 1
fi

# Get a list of pods in the specified namespace with creation timestamps
pod_list=$(kubectl get pods --sort-by='.metadata.creationTimestamp' -o json | jq -r ".items[] | select(.metadata.name | test(\"$regex_pattern\")) | .metadata.name")

if [ -z "$pod_list" ]; then
    echo "No pods matching the regex pattern '$regex_pattern' found in current namespace."
    exit 1
fi
echo "Pod list matching the regex pattern:"
echo $pod_list

# Extract the first item from the list
first_matching_pod=$(echo "$pod_list" | head -n 1)

# Print the first matching pod
echo "The following pod will be deleted:"
echo "$first_matching_pod"

# kubectl delete pod $first_matching_pod
