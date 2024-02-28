#!/bin/bash

#STEP 1: Give inputs topic_name and find json_filename and access Git

#check whether the entered topic name correct or not
while true; do
    read -p "Enter the topic name: " topic_name
    read -p "Is the topic name '$topic_name' correct? (y/n): " confirm
    if [[ $confirm == "y" || $confirm == "Y" ]]; then
        break
    fi
done

#check for environment type
if echo "$topic_name" | grep -q "nonprod"; then
   env_type="nonprod"
   echo "$env_type"
   
elif echo "$topic_name" | grep -q "prod"; then
  env_type="prod"
  echo "$env_type"
  
else
  echo "Neither prod nor nonprod found.so it might be preprod"
  env_type="preprod"
fi


# Assume topic_name as inputed as below
#topic_name="dataservicesnonprod/seq-weekend-rds-nonprod/weekend_db.analytics.calendly_event_data/us-east4.gcp"

# Replaceing slashes with hyphens and ignore everything after the first dot
formatted_topic_name=$(echo "$topic_name" | sed 's/\//-/g' | sed 's/\..*$//')

#using formated topic name we try to check if json file exists or not 
echo "$formatted_topic_name"

#formatted_topic_name="dataservicesnonprod-seq-weekend-rds-nonprod-weekend_db"

# The path to your json file that maps topics to consumers
file_path="topic_and_consume_file_id.json"

# Use jq to search and extract the corresponding .json file name
json_filename=$(jq -r --arg fn "$formatted_topic_name" '.[$fn]' "$file_path")

# Check if a file name was found
if [[ $json_filename == "null" ]] || [[ -z $json_filename ]]; then
  echo "No JSON file matching the topic name was found.You need to create new Json File "
  exit 1
else
  echo "Matching JSON file found : $json_filename"
fi


#=================================

#clone, create_branch, and Modify JSON
#cloning the repo
#test#git clone https://github.com/$GITHUB_REPO.git
cd bie-kafka-consumer/deployment_configurations/$env_type/consumers

#==================================================================================
#STEP2: create new branch and added new topic if not present in the json file"

# Move forward with the confirmed topic_name and json filename
echo "Proceeding with topic name: $topic_name and json filename: $json_filename"
#test#branch_name="Add_topic_${topic_name}"

# Checkout to a new branch
#test#git checkout -b "$branch_name"


# Check if the topic already exists
exists=$(jq --arg new_topic "$topic_name" '.env.KAFKA_TOPICS | contains($new_topic)' "$json_filename")

if [[ $exists == "true" ]]; then
    echo "The topic '$topic_name' already exists in KAFKA_TOPICS."
    
else
    # Append the new topic if it does not already exist
    jq --arg new_topic "$topic_name" '
      if .env.KAFKA_TOPICS | endswith(",") then
        .env.KAFKA_TOPICS += $new_topic
      else
        .env.KAFKA_TOPICS += "," + $new_topic
      end' "$json_filename" > temp.json && mv temp.json "$json_filename"
    echo "The topic '$topic_name' has been added successfully to KAFKA_TOPICS."
fi


# Add, commit, and push changes
#test#git add .
#test#git commit -m "Add topic ${topic_name} to ${json_filename}"
#git push --set-upstream origin "$branch_name"


# Push the branch to GitHub and capture the output
#test#output=$(git push --set-upstream origin "$branch_name" 2>&1)

# Get url that first match
#test#pr_url=$(echo "$output" | grep -o 'https://github.com/[^ ]*/pull/new/[^ ]*' | head -n 1)

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

