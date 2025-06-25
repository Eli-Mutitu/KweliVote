#!/bin/bash

# Check if we're in the right directory
if [ ! -d "./kwelivote-app/frontend" ]; then
  # Try to find the right directory
  if [ -d "/home/quest/myrepos/KweliVote-1/kwelivote-app/frontend" ]; then
    cd /home/quest/myrepos/KweliVote-1
  else
    echo "Error: Could not find the KweliVote-1 directory"
    exit 1
  fi
fi

echo "=== KweliVote Blockchain Check Tool ==="
echo "Running checks on wallet balance and blockchain configuration..."
echo ""

# Navigate to the frontend directory
cd kwelivote-app/frontend

# Check if node_modules exists
if [ ! -d "./node_modules" ]; then
  echo "Installing dependencies..."
  npm install
fi

# Run the wallet balance checker
echo "Checking wallet balance..."
npx hardhat run scripts/check_wallet_balance.js --no-compile

# Show the current environment configuration
echo ""
echo "=== Current Environment Configuration ==="
echo "Showing blockchain-related environment variables:"

# Function to check if file exists and extract values
check_env_file() {
  if [ -f "$1" ]; then
    echo "From $1:"
    grep -E "REACT_APP_(APECHAIN|ADMIN|VOTER)" "$1" | grep -v "example" | sed 's/=/: /'
  fi
}

# Check environment variables in different potential locations
check_env_file ".env"
check_env_file ".env.development"
check_env_file ".env.local"

echo ""
echo "=== Troubleshooting Guide ==="
echo "If you're seeing 'insufficient funds' errors:"
echo "1. Make sure your wallet has enough APE tokens (minimum 0.01 APE)"
echo "2. Check that the contract address is correct and deployed"
echo "3. Try running a manual deployment with: npx hardhat run scripts/deploy_contract.js"
echo "4. After deploying, update your .env.development file with the new contract address"
echo ""
echo "For additional help, check the documentation in docs/apechain-blockchain-integration.md"
