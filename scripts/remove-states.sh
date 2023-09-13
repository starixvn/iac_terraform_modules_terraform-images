#!/usr/bin/env sh

#
# Script to remove the given Terraform States.
# The states are read from stdin in the format:
# `<state-name>,<last-updated-at>`
# 
# The script is optimized to run in a GitLab pipeline 
# and therefore uses environment variables which are
# defined there by default.
# 
# It requires an additional `GITLAB_TOKEN` variable, which
# contains a valid GitLab token with permissions to delete
# Terraform states.
# 

GITLAB_BASE_TF_ADDRESS="${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state"

cat - | while read -r line; do
    echo "Processing $(echo "$line" | tr -d '\n')"

    TF_ADDRESS="${GITLAB_BASE_TF_ADDRESS}/$(echo "$line" | cut -d, -f1)"
    curl --header "Private-Token: $GITLAB_TOKEN" --request DELETE "$TF_ADDRESS"
done
