#!/bin/bash

# Node.js and semantic-release configuration

# Add local node_modules/.bin to PATH for local packages
#export PATH="/home/bashuser/node_modules/.bin:$PATH"


# Function to run semantic-release without modifying package.json
function run-semantic-release() {
    echo "Running semantic-release with global configuration..."
    semantic-release-wrapper "$@"
}


# Function to check the last commit message
function check-last-commit() {
    local last_commit_msg
    last_commit_msg=$(git log -1 --pretty=format:"%s")

    if [ -z "$last_commit_msg" ]; then
        echo "❌ Error: No commit found"
        return 1
    fi

    echo "🔍 Checking last commit message..."
    validate-commit-msg "$last_commit_msg"
}

# Function to check multiple commits
function check-commits() {
    local from_commit="${1:-HEAD~5}"
    local to_commit="${2:-HEAD}"

    echo "🔍 Checking commits from $from_commit to $to_commit..."

    if ! command -v commitlint &> /dev/null; then
        echo "❌ Error: commitlint is not installed"
        echo "Install it with: npm install @commitlint/cli @commitlint/config-conventional"
        return 1
    fi

    commitlint --from "$from_commit" --to "$to_commit"

    if [ $? -eq 0 ]; then
        echo "✅ All commits are valid!"
        return 0
    else
        echo "❌ Some commits do not follow Conventional Commits format"
        return 1
    fi
}


