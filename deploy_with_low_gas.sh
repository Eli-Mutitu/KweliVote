#!/bin/bash

# Script to deploy a new VoterDID contract with lower gas fees
# This helps when you're facing insufficient funds errors

echo "=== VoterDID Contract Deployment with Low Gas Settings ==="
echo "This script will deploy a new contract with minimal gas fees"
echo ""

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

# Navigate to the frontend directory
cd kwelivote-app/frontend

# Check if the needed files exist
if [ ! -f "./scripts/deploy_with_low_gas.js" ]; then
  echo "Error: deploy_with_low_gas.js script not found"
  exit 1
fi

# Verify environment variables
if [ ! -f "./.env" ]; then
  echo "Warning: .env file not found. Will use .env.development if available."
  if [ -f "./.env.development" ]; then
    echo "Using .env.development for environment variables"
    # Copy .env.development to .env temporarily
    cp .env.development .env
    COPIED_ENV=true
  else
    echo "Error: No environment files found (.env or .env.development)"
    exit 1
  fi
fi

# Check if private key is set
PRIVATE_KEY=$(grep REACT_APP_ADMIN_PRIVATE_KEY .env | cut -d= -f2)
if [ -z "$PRIVATE_KEY" ]; then
  echo "Error: REACT_APP_ADMIN_PRIVATE_KEY not set in .env file"
  echo "Please set a valid private key in your .env file"
  exit 1
fi

echo "Environment setup complete"
echo "Deploying contract with low gas settings..."
echo ""

# Compile contracts if needed
if [ ! -d "./artifacts" ]; then
  echo "Compiling contracts..."
  npx hardhat compile
fi

# Run the deployment script
npx hardhat run scripts/deploy_with_low_gas.js --no-compile

# Get the result status
RESULT=$?

# Clean up temporary .env if we created it
if [ "$COPIED_ENV" = true ]; then
  rm .env
fi

# Check if deployment was successful
if [ $RESULT -eq 0 ]; then
  echo ""
  echo "✅ Deployment was successful!"
  echo "Please update your .env file with the new contract address shown above."
  echo ""
  echo "To use the new contract address:"
  echo "1. Edit the .env file or .env.development file"
  echo "2. Update REACT_APP_VOTER_DID_CONTRACT_ADDRESS with the new address"
  echo "3. Restart your application"
else
  echo ""
  echo "❌ Deployment failed. Please check the error messages above."
  echo ""
  echo "Common issues:"
  echo "1. Insufficient funds - Your wallet needs APE tokens"
  echo "2. Network issues - Check your connection to the APEChain network"
  echo "3. Environment configuration - Make sure all required variables are set"
fi

exit $RESULT
