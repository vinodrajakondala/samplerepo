import os
import json
from git import Repo, GitCommandError

# Function to verify input with the user
def verify_input(prompt):
    response = input(prompt + " (yes/no): ").lower()
    while response not in {"yes", "no"}:
        response = input("Please answer 'yes' or 'no': ").lower()
    return response == "yes"

# Inputs
topic_name = input("Enter the topic_name: ")
json_filename_input = input("Enter the json_filename: ")
json_filename = "-".join(topic_name.split("-")[2:4]) + ".json"  # Automated suggestion

# Verify the json_filename
if json_filename_input != json_filename:
    if not verify_input(f"The suggested filename is {json_filename}. Do you want to correct this?"):
        json_filename = json_filename_input

env_type = "prod" if "prod" in topic_name.split("-") else "nonprod"
branch_name = f"Add_topic_{topic_name}"  # Branch name format

# Assuming the repo is already cloned and you're in the correct directory
repo_path = os.getcwd()  # Use current working directory
repo = Repo(repo_path)

try:
    # Create and Checkout New Branch
    repo.git.checkout('HEAD', b=branch_name)
except GitCommandError:
    if not verify_input("Branch already exists, do you want to continue on this branch?"):
        exit("Exiting as per user request.")

# Path to JSON file
json_file_path = os.path.join(repo_path, "deployment_configurations", env_type, "consumers", json_filename)

# Check if file exists
if not os.path.exists(json_file_path):
    exit(f"Error: The file {json_file_path} does not exist.")

# Add Topic to JSON File
with open(json_file_path, 'r+') as file:
    data = json.load(file)
    if topic_name in data['test4']['KAFKA_TOPICS']:
        print(f"The input '{topic_name}' already exists in KAFKA_TOPICS.")
    else:
        data['test4']['KAFKA_TOPICS'] += "," + topic_name
        file.seek(0)
        json.dump(data, file, indent=4)
        file.truncate()
        print(f"Added '{topic_name}' to KAFKA_TOPICS.")

# Git Operations
repo.git.add(json_file_path)
commit_message = f"added new topic to {json_filename}"
repo.git.commit(m=commit_message)
repo.git.push('origin', branch_name)
print(f"Changes pushed to new branch: {branch_name}")

# Create a PR
from github import Github

# Assuming you have an access token set in your environment or replace it with your token
g = Github(os.getenv('GITHUB_TOKEN'))
repo = g.get_repo("vinod_Digital/vinod_kafka_consumer")
pr_title = f"Add topic {topic_name}"
pr_body = f"Automated PR to add topic {topic_name} to {json_filename}"
pr = repo.create_pull(title=pr_title, body=pr_body, base="staging", head=branch_name)
print(f"Pull Request created: {pr.html_url}")
