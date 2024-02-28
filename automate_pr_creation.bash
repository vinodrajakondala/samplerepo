#!/bin/bash

#STEP 1: Give inputs topic_name,json_filename and access Git
## Input Variables
#read -p "Enter the topic name: " topic_name
#read -p "Enter the json filename: " json_filename


while true; do
    read -p "Enter the topic name: " topic_name
    read -p "Is the topic name '$topic_name' correct? (y/n): " confirm
    if [[ $confirm == "y" || $confirm == "Y" ]]; then
        break
    fi
done

while true; do
    read -p "Enter the json filename: " json_filename
    read -p "Is the json filename '$json_filename' correct? (y/n): " confirm
    if [[ $confirm == "y" || $confirm == "Y" ]]; then
        break
    fi
done

# Move forward with the confirmed topic_name and json_filename
echo "Proceeding with topic name: $topic_name and json filename: $json_filename"
env_type=$(echo "$topic_name" | grep -q "prod" && echo "prod" || echo "nonprod")
branch_name="Add_topic_${topic_name}"

# GitHub Variables
GITHUB_USER="vinodktest"
GITHUB_TOKEN="vinodtest_github_token"
GITHUB_REPO="vinod_digital/vinod_kafka_consumer"
GITHUB_API_URL="https://api.github.com/repos/$GITHUB_REPO"

#clone, create_branch, and Modify JSON
#cloning the repo
git clone https://github.com/$GITHUB_REPO.git
cd vinod_kafka_consumer

#==================================================================================
#STEP2: create new branch and added new topic if not present in the json file"

# Checkout to a new branch
git checkout -b "$branch_name"


# Check if the topic already exists
exists=$(jq --arg new_topic "$topic_name" '.test4.KAFKA_TOPICS | contains($new_topic)' "$json_filename")

if [[ $exists == "true" ]]; then
    echo "The topic '$topic_name' already exists in KAFKA_TOPICS."
    exit 1
else
    # Append the new topic if it does not already exist
    jq --arg new_topic "$topic_name" '
      if .test4.KAFKA_TOPICS | endswith(",") then
        .test4.KAFKA_TOPICS += $new_topic
      else
        .test4.KAFKA_TOPICS += "," + $new_topic
      end' "$json_filename" > temp.json && mv temp.json "$json_filename"
    echo "The topic '$topic_name' has been added successfully to KAFKA_TOPICS."
fi


# Add, commit, and push changes
git add .
git commit -m "Add topic ${topic_name} to ${json_filename}"
#git push --set-upstream origin "$branch_name"


# Push the branch to GitHub and capture the output
output=$(git push --set-upstream origin "$branch_name" 2>&1)

# Get url that first match
pr_url=$(echo "$output" | grep -o 'https://github.com/[^ ]*/pull/new/[^ ]*' | head -n 1)

# Checking if a PR URL was found
if [ -n "$pr_url" ]; then
    echo "Creating automated pull request by visiting:"
    echo "$pr_url"
else
    echo "Failed to extract the pull request URL."
fi

#==================================================================================
#STEP 3: Create PR
# Create PR
PR_DATA=$(cat <<EOF
{
  "title": "Adding new topic ${topic_name}",
  "head": "$branch_name",
  "base": "staging",
  "body": "Automated PR to add topic ${topic_name} to ${json_filename}"
}
EOF
)

# Use curl to create PR and capture the response
response=$(curl -s -u "$GITHUB_USER:$GITHUB_TOKEN" \
     -X POST \
     -H "Accept: application/vnd.github.v3+json" \
     $GITHUB_API_URL/pulls \
     -d "$PR_DATA")

# Extract PR link from response
pr_link=$(echo $response | jq -r .html_url)

# Checking if the PR link is null or not
if [ "$pr_link" != "null" ]; then
    echo "PR created successfully: $pr_link"
else
    echo "Failed to create PR. Response from GitHub API: $response"
fi