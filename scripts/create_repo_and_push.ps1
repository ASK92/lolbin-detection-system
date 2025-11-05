# PowerShell script to create GitHub repo and push
# This opens GitHub in browser for manual creation, then pushes code

param(
    [string]$RepoName = "lolbin-detection-system",
    [string]$Username = "ASK92"
)

Write-Host "Creating GitHub Repository and Pushing Code" -ForegroundColor Green
Write-Host ""

# Step 1: Open GitHub new repository page
Write-Host "[1/3] Opening GitHub repository creation page..." -ForegroundColor Cyan
$githubUrl = "https://github.com/new"
Start-Process $githubUrl

Write-Host ""
Write-Host "Please complete these steps in your browser:" -ForegroundColor Yellow
Write-Host "1. Repository name: $RepoName" -ForegroundColor White
Write-Host "2. Description: Production-grade LOLBin detection system with ML and explainability" -ForegroundColor White
Write-Host "3. Choose Public or Private" -ForegroundColor White
Write-Host "4. DO NOT initialize with README, .gitignore, or license" -ForegroundColor White
Write-Host "5. Click 'Create repository'" -ForegroundColor White
Write-Host ""

$response = Read-Host "Press Enter after you've created the repository on GitHub"

# Step 2: Add remote and push
Write-Host "[2/3] Adding remote repository..." -ForegroundColor Cyan
$repoUrl = "https://github.com/$Username/$RepoName.git"

# Check if remote already exists
$existingRemote = git remote get-url origin 2>$null
if ($existingRemote) {
    Write-Host "Remote 'origin' already exists. Removing..." -ForegroundColor Yellow
    git remote remove origin
}

git remote add origin $repoUrl
Write-Host "Remote added: $repoUrl" -ForegroundColor Green

# Step 3: Rename branch and push
Write-Host "[3/3] Pushing code to GitHub..." -ForegroundColor Cyan
git branch -M main

Write-Host "Pushing to GitHub..." -ForegroundColor Yellow
git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Successfully pushed to GitHub!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Repository URL: https://github.com/$Username/$RepoName" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "ERROR: Failed to push. Please check:" -ForegroundColor Red
    Write-Host "1. Repository was created on GitHub" -ForegroundColor Yellow
    Write-Host "2. Repository name is correct: $RepoName" -ForegroundColor Yellow
    Write-Host "3. You have push access to the repository" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "You can manually push with:" -ForegroundColor Cyan
    Write-Host "  git remote add origin $repoUrl" -ForegroundColor White
    Write-Host "  git branch -M main" -ForegroundColor White
    Write-Host "  git push -u origin main" -ForegroundColor White
}


