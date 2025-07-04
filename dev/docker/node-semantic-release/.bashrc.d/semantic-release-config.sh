#!/bin/bash

# Node.js and semantic-release configuration

# Set NPM to save exact versions by default
npm config set save-exact true

# Set NPM to not generate package-lock.json by default in CI environments
if [ "$CI" = "true" ]; then
  npm config set package-lock false
fi

# Add useful Node.js aliases
alias nr='npm run'
alias ni='npm install'
alias nid='npm install --save-dev'
alias nig='npm install -g'
alias ns='npm start'
alias nt='npm test'
alias nb='npm run build'

# Add semantic-release aliases that use the wrapper
alias sr='semantic-release-wrapper'
alias sr-dry='semantic-release-wrapper --dry-run'
alias sr-debug='DEBUG=semantic-release:* semantic-release-wrapper'

# Add commitlint aliases
alias cl='commitlint'
alias cl-last='commitlint --from HEAD~1 --to HEAD'
alias cl-config='commitlint --print-config'

# Function to run semantic-release without modifying package.json
function run-semantic-release() {
    echo "Running semantic-release with global configuration..."
    semantic-release-wrapper "$@"
}

# Function to validate commit message using commitlint
function validate-commit-msg() {
    local commit_msg="$1"
    
    if [ -z "$commit_msg" ]; then
        echo "❌ Error: No commit message provided"
        echo "Usage: validate-commit-msg \"your commit message\""
        echo "Example: validate-commit-msg \"feat: add new feature\""
        return 1
    fi
    
    # Check if commitlint is available
    if ! command -v commitlint &> /dev/null; then
        echo "❌ Error: commitlint is not installed"
        echo "Install it with: npm install -g @commitlint/cli @commitlint/config-conventional"
        return 1
    fi
    
    # Validate the commit message
    echo "🔍 Validating commit message: \"$commit_msg\""
    echo "$commit_msg" | commitlint
    
    if [ $? -eq 0 ]; then
        echo "✅ Commit message is valid!"
        return 0
    else
        echo "❌ Commit message does not follow Conventional Commits format"
        echo ""
        echo "📝 Examples of valid commit messages:"
        echo "  feat: add new feature"
        echo "  fix: resolve bug in authentication"
        echo "  docs: update API documentation"
        echo "  style: format code with prettier"
        echo "  refactor: restructure user service"
        echo "  test: add unit tests for utils"
        echo "  chore: update dependencies"
        echo ""
        echo "📖 Learn more about Conventional Commits: https://conventionalcommits.org/"
        return 1
    fi
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
        echo "Install it with: npm install -g @commitlint/cli @commitlint/config-conventional"
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


# Export Node.js version
export NODE_VERSION=$(node --version)
echo "Node.js version: $NODE_VERSION"
echo "NPM version: $(npm --version)"
echo "Semantic-release version: $(semantic-release --version)"

# Print available commands
echo "Available Node.js commands:"
echo "  nr - npm run"
echo "  ni - npm install"
echo "  nid - npm install --save-dev"
echo "  nig - npm install -g"
echo "  ns - npm start"
echo "  nt - npm test"
echo "  nb - npm run build"
echo "  sr - semantic-release (using global config)"
echo "  sr-dry - semantic-release --dry-run"
echo "  sr-debug - DEBUG=semantic-release:* semantic-release"
echo "  run-semantic-release - Run semantic-release without touching package.json"
echo ""
echo "Available commitlint commands:"
echo "  cl - commitlint"
echo "  cl-last - validate last commit message"
echo "  cl-config - print commitlint configuration"
echo "  validate-commit-msg \"message\" - validate a specific commit message"
echo "  check-last-commit - check if last commit follows conventions"
echo "  check-commits [from] [to] - check multiple commits (default: last 5)"