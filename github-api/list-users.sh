#!/bin/bash

# GitHub API base URL
API_URL="https://api.github.com"

# GitHub username and personal access token (ensure these are exported as environment variables or set directly here)
USERNAME="${GITHUB_USERNAME:-your-username}"
TOKEN="${GITHUB_TOKEN:-your-personal-access-token}"

# Repository owner and name (passed as arguments)
REPO_OWNER=$1
REPO_NAME=$2

# Function to make a GET request to the GitHub API
function github_api_get {
    local endpoint="$1"
    local url="${API_URL}/${endpoint}"

    # Send a GET request to the GitHub API with authentication
    response=$(curl -s -u "${USERNAME}:${TOKEN}" "$url")
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to connect to GitHub API."
        exit 1
    fi

    echo "$response"
}

# Function to list users with read access to the repository
function list_users_with_read_access {
    local endpoint="repos/${REPO_OWNER}/${REPO_NAME}/collaborators"

    # Fetch the list of collaborators from the repository
    response=$(github_api_get "$endpoint")

    # Check if API returned an error
    if echo "$response" | jq .message >/dev/null 2>&1; then
        error_message=$(echo "$response" | jq -r .message)
        echo "Error: $error_message"
        exit 1
    fi

    # Parse the collaborators with read access
    collaborators=$(echo "$response" | jq -r '.[] | select(.permissions.pull == true) | .login')

    # Display the list of collaborators with read access
    if [[ -z "$collaborators" ]]; then
        echo "No users with read access found for ${REPO_OWNER}/${REPO_NAME}."
    else
        echo "Users with read access to ${REPO_OWNER}/${REPO_NAME}:"
        echo "$collaborators"
    fi
}

# Main script

# Validate inputs
if [[ -z "$REPO_OWNER" || -z "$REPO_NAME" ]]; then
    echo "Usage: $0 <repo_owner> <repo_name>"
    echo "Example: $0 octocat hello-world"
    exit 1
fi

echo "Listing users with read access to ${REPO_OWNER}/${REPO_NAME}..."
list_users_with_read_access
