#!/bin/bash

#STEP 1: Give inputs topic_name and find json_filename and access Git

#check whether the entered topic name correct or not
while true; do
    read -p "Enter the topic_name: " topic_name
	echo ""
    read -p "Is this topic_name  :  '$topic_name' correct? (y/n): " confirm
	echo ""
    if [[ $confirm == "y" || $confirm == "Y" ]]; then
        break
    fi
done
echo "-----------------------------------------------------------------------------------------------"
echo "Topic name is confirmed "
echo "-----------------------------------------------------------------------------------------------"

#check for environment type
echo "ennvironment detected is : "
if echo "$topic_name" | grep -q "nonprod"; then
   env_type="nonprod"
   
   echo "  $env_type"
   
elif echo "$topic_name" | grep -q "prod"; then
  env_type="prod"
  echo "   $env_type"
  
elif echo "$topic_name" | grep -q "preprod"; then
  env_type="preprod"
  echo "   $env_type"
  
else
  echo "Neither prod nor nonprod found.So it might be preprod"
  echo ""
  env_type="preprod"
  echo "   $env_type"
fi


# Assume topic_name as inputed as below
#topic_name="dataservicesnonprod/seq-weekend-rds-nonprod/weekend_db.analytics.calendly_event_data/us-east4.gcp"

# Replaceing slashes with hyphens and ignore everything after the first dot
formatted_topic_name=$(echo "$topic_name" | sed 's/\//-/g' | sed 's/\..*$//')

#using formated topic name we try to check if json file exists or not 
#echo " formatted topic name we try to check if json file exists or not : $formatted_topic_name"

#formatted_topic_name="dataservicesnonprod-seq-weekend-rds-nonprod-weekend_db"

# The path to your json file that maps topics to consumers
file_path="topic_and_consume_file_id.json"

# Use jq to search and extract the corresponding .json file name
json_filename=$(jq -r --arg fn "$formatted_topic_name" '.[$fn]' "$file_path")

# Check if a file name was found
if [[ $json_filename == "null" ]] || [[ -z $json_filename ]]; then
  echo "-----------------------------------------------------------------------------------------------"
  echo "No JSON file matching the topic name was found.You need to create new Json File "
  echo "-----------------------------------------------------------------------------------------------"
  echo ""
  exit 1
else
echo "-----------------------------------------------------------------------------------------------"
  echo "Matching JSON file found : "
 echo "-----------------------------------------------------------------------------------------------"
  echo ""
  echo "   $json_filename"
  echo ""
fi


#=================================

#clone, create_branch, and Modify JSON
#cloning the repo
#test#git clone https://github.com/$GITHUB_REPO.git
cd bie-kafka-consumer/deployment_configurations/$env_type/consumers

#==================================================================================
#STEP2: create new branch and added new topic if not present in the json file"

# Replace slashes with hyphens and remove the "/us-east4.gcp" at the end
topic_to_be_added=$(echo "$topic_name" | sed 's/\//-/g' | sed 's/-us-east4.gcp$//')

# Move forward with the confirmed topic_name and json filename
echo "-----------------------------------------------------------------------------------------------"
echo "Proceeding with topic name: ";
echo "-----------------------------------------------------------------------------------------------"
echo "topic to be added to json file :-  $topic_to_be_added"
echo ""
echo "   The json file is            :-  $json_filename"
echo ""
echo "-----------------------------------------------------------------------------------------------"
#test#branch_name="Add_topic_${topic_to_be_added}"

# Checkout to a new branch
#test#git checkout -b "$branch_name"



#echo "$formatted_name"
# Check if the topic already exists
exists=$(jq --arg new_topic "$topic_to_be_added" '.env.KAFKA_TOPICS | contains($new_topic)' "$json_filename")

if [[ $exists == "true" ]]; then
    #echo "-----------------------------------------------------------------------------------------------"
	echo ""
    echo "The topic '$topic_to_be_added' already exists in KAFKA_TOPICS."
	echo ""
	#echo "-----------------------------------------------------------------------------------------------"
    
else
    # Append the new topic if it does not already exist
    jq --arg new_topic "$topic_to_be_added" '
      if .env.KAFKA_TOPICS | endswith(",") then
        .env.KAFKA_TOPICS += $new_topic
      else
        .env.KAFKA_TOPICS += "," + $new_topic
      end' "$json_filename" > temp.json && mv temp.json "$json_filename"
	#echo "-----------------------------------------------------------------------------------------------"
	echo ""
    echo "The topic '$topic_to_be_added' has been added successfully to KAFKA_TOPICS."
	#echo "-----------------------------------------------------------------------------------------------"
	echo ""
fi


# Add, commit, and push changes
#T#git add .
#T#git commit -m "Add topic ${topic_name} to ${json_filename}"
#git push --set-upstream origin "$branch_name"


# Push the branch to GitHub and capture the output
#T#output=$(git push --set-upstream origin "$branch_name" 2>&1)

# Get url that first match
#T#pr_url=$(echo "$output" | grep -o 'https://github.com/[^ ]*/pull/new/[^ ]*' | head -n 1)

# Checking if a PR URL was found
echo "-----------------------------------------------------------------------------------------------"
if [ -n "$pr_url" ]; then
    echo "Creating automated pull request by visiting:"
    echo "$pr_url"
else
    echo ""
    echo "Failed to extract the pull request URL."
fi

#==================================================================================
#STEP 3: Create PR
# Create PR

