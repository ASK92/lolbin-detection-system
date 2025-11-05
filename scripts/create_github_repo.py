"""
Create GitHub repository and push code
Requires GitHub Personal Access Token
"""

import requests
import subprocess
import sys
import os

def create_github_repo(username, repo_name, description, token, is_private=False):
    """Create a GitHub repository using GitHub API"""
    
    url = "https://api.github.com/user/repos"
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json"
    }
    
    data = {
        "name": repo_name,
        "description": description,
        "private": is_private,
        "auto_init": False
    }
    
    try:
        response = requests.post(url, json=data, headers=headers)
        response.raise_for_status()
        
        repo_data = response.json()
        repo_url = repo_data["clone_url"]
        print(f"Repository created successfully: {repo_url}")
        return repo_url
    except requests.exceptions.HTTPError as e:
        if response.status_code == 401:
            print("ERROR: Invalid GitHub token. Please check your token.")
        elif response.status_code == 422:
            print("ERROR: Repository may already exist or name is invalid.")
        else:
            print(f"ERROR: Failed to create repository: {e}")
        return None

def push_to_github(repo_url):
    """Push code to GitHub repository"""
    
    try:
        # Add remote
        subprocess.run(["git", "remote", "add", "origin", repo_url], check=True)
        print("Remote added successfully")
        
        # Rename branch to main
        subprocess.run(["git", "branch", "-M", "main"], check=True)
        print("Branch renamed to main")
        
        # Push to remote
        subprocess.run(["git", "push", "-u", "origin", "main"], check=True)
        print("Code pushed successfully!")
        return True
    except subprocess.CalledProcessError as e:
        print(f"ERROR: Failed to push: {e}")
        return False

def main():
    username = "ASK92"
    repo_name = "lolbin-detection-system"
    description = "Production-grade LOLBin detection system with ML and explainability"
    
    # Get token from environment or user input
    token = os.getenv("GITHUB_TOKEN")
    
    if not token:
        print("GitHub Personal Access Token required.")
        print("Get one from: https://github.com/settings/tokens")
        print("Required scopes: repo")
        token = input("Enter your GitHub token: ").strip()
    
    if not token:
        print("ERROR: Token is required")
        sys.exit(1)
    
    # Create repository
    repo_url = create_github_repo(username, repo_name, description, token, is_private=False)
    
    if repo_url:
        # Push code
        push_to_github(repo_url)

if __name__ == "__main__":
    main()


