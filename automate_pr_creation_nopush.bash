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
