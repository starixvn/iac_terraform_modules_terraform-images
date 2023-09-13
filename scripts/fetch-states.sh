#!/usr/bin/env sh

#
# Script to fetch all Terraform States of a project,
# optionally filter states which are older than a given
# date time.
# 
# The output is in CSV and contains a header line
# containing the names of the columns.
# You can easily store it as CSV using:
# `fetch-states.sh > states.csv`
# or stream it to another script, e.g. without the header line:
# `fetch-states.sh | sed -n '1d;p' | ...`
#
# The script is optimized to run in a GitLab pipeline 
# and therefore uses environment variables which are
# defined there by default.
# 
# It requires an additional `GITLAB_TOKEN` variable, which
# contains a valid GitLab token with permissions to read
# Terraform states.
# 

GITLAB_GRAPHQL_API_URL=${CI_SERVER_URL}/api/graphql

if [ -z "$FETCH_OLDER_THAN" ]; then
    FETCH_OLDER_THAN=$(date "+%Y-%m-%dT%H:%M:%SZ")
fi

after="null"
has_next_page=true

echo "state,updatedAt"
while $has_next_page; do
    # shellcheck disable=SC2016
    data=$(curl --silent --show-error --fail -H "Authorization: Bearer $GITLAB_TOKEN" -H "Content-Type: application/json" \
        "$GITLAB_GRAPHQL_API_URL" \
        -X POST \
        --data '[{ "operationName": "getStates", "variables": { "projectPath": "gitlab-org/terraform-images", "first": 100, "after":'"$after"', "last": null, "before": null }, "query": "query getStates($projectPath: ID!, $first: Int, $last: Int, $before: String, $after: String) { project(fullPath: $projectPath) { id terraformStates(first: $first, last: $last, before: $before, after: $after) { count nodes { name updatedAt } pageInfo { hasNextPage endCursor } } } } " } ] '
    )

    echo "$data" | jq --arg date "$FETCH_OLDER_THAN" -r '.[0]["data"]["project"]["terraformStates"]["nodes"][] | select(.updatedAt < $date) | "\(.name),\(.updatedAt)"'

    has_next_page=$(echo "$data" | jq -r '.[0]["data"]["project"]["terraformStates"]["pageInfo"]["hasNextPage"] == true')
    after='"'$(echo "$data" | jq -r '.[0]["data"]["project"]["terraformStates"]["pageInfo"]["endCursor"]')'"'
done
