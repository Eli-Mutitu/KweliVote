#!/bin/bash

# Deploy all contracts in the KweliVote frontend/contracts directory
# Following the steps in the README.md

echo "=== Deploying All KweliVote Smart Contracts ==="
echo "This script will compile and deploy all contracts in the contracts directory"
echo ""

# Navigate to the frontend directory
cd "$(dirname "$0")/kwelivote-app/frontend"

# Make sure we have the required dependencies
echo "Installing required dependencies..."
npm install --save-dev @nomiclabs/hardhat-ethers @nomiclabs/hardhat-waffle @nomiclabs/hardhat-etherscan hardhat-deploy dotenv ethereum-waffle

# Compile the contracts
echo "Compiling contracts..."
npx hardhat compile

# Check if compilation was successful
if [ ! -d "./src/artifacts/contracts" ]; then
  echo "Error: Contract compilation failed or artifacts not found"
  exit 1
fi

echo "Contracts compiled successfully!"
echo ""

# Create deploy scripts for each contract
echo "Creating deployment scripts for each contract..."

# 1. VoterDID Contract
cat > scripts/deploy_voterDID.js << 'EOF'
const hre = require("hardhat");

async function main() {
  console.log("Deploying VoterDID contract to APEChain Curtis Testnet...");
  
  // Get the ContractFactory
  const VoterDID = await hre.ethers.getContractFactory("VoterDID");
  
  // Get current gas price from the network
  const provider = hre.ethers.provider;
  const gasPrice = await provider.getGasPrice();
  
  // Calculate a lower gas price (60% of current)
  const lowerGasPrice = gasPrice.mul(60).div(100);
  
  console.log(`Using lower gas price: ${hre.ethers.utils.formatUnits(lowerGasPrice, 'gwei')} gwei`);
  
  // Deploy with custom gas settings
  const deploymentOptions = {
    gasPrice: lowerGasPrice,
    gasLimit: 3000000
  };
  
  // Deploy it
  const voterDID = await VoterDID.deploy(deploymentOptions);
  
  // Wait for deployment to finish
  await voterDID.deployed();

  console.log(`VoterDID deployed to: ${voterDID.address}`);
  console.log(`Transaction hash: ${voterDID.deployTransaction.hash}`);
  
  // Update .env file with the contract address
  const fs = require('fs');
  const path = require('path');
  const envFile = path.join(__dirname, '..', '.env');
  
  if (fs.existsSync(envFile)) {
    let envContent = fs.readFileSync(envFile, 'utf8');
    
    // Replace or add the contract address
    if (envContent.includes('REACT_APP_VOTER_DID_CONTRACT_ADDRESS=')) {
      envContent = envContent.replace(
        /REACT_APP_VOTER_DID_CONTRACT_ADDRESS=.*/,
        `REACT_APP_VOTER_DID_CONTRACT_ADDRESS=${voterDID.address}`
      );
    } else {
      envContent += `\nREACT_APP_VOTER_DID_CONTRACT_ADDRESS=${voterDID.address}\n`;
    }
    
    fs.writeFileSync(envFile, envContent);
    console.log(`Updated .env file with VoterDID contract address: ${voterDID.address}`);
  }

  return voterDID;
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Deployment failed:", error);
    process.exit(1);
  });
EOF

# 2. VoterDIDLite Contract
cat > scripts/deploy_voterDIDLite.js << 'EOF'
const hre = require("hardhat");

async function main() {
  console.log("Deploying VoterDIDLite contract to APEChain Curtis Testnet...");
  
  // Get the ContractFactory
  const VoterDIDLite = await hre.ethers.getContractFactory("VoterDIDLite");
  
  // Get current gas price from the network
  const provider = hre.ethers.provider;
  const gasPrice = await provider.getGasPrice();
  
  // Calculate a lower gas price (40% of current)
  const lowerGasPrice = gasPrice.mul(40).div(100);
  
  console.log(`Using ultra-low gas price: ${hre.ethers.utils.formatUnits(lowerGasPrice, 'gwei')} gwei`);
  
  // Deploy with custom gas settings
  const deploymentOptions = {
    gasPrice: lowerGasPrice,
    gasLimit: 2000000 // Lower limit for optimized contract
  };
  
  // Deploy it
  const voterDIDLite = await VoterDIDLite.deploy(deploymentOptions);
  
  // Wait for deployment to finish
  await voterDIDLite.deployed();

  console.log(`VoterDIDLite deployed to: ${voterDIDLite.address}`);
  console.log(`Transaction hash: ${voterDIDLite.deployTransaction.hash}`);
  
  // Update .env file with the contract address
  const fs = require('fs');
  const path = require('path');
  const envFile = path.join(__dirname, '..', '.env');
  
  if (fs.existsSync(envFile)) {
    let envContent = fs.readFileSync(envFile, 'utf8');
    
    // Replace or add the contract address
    if (envContent.includes('REACT_APP_VOTER_DID_LITE_CONTRACT_ADDRESS=')) {
      envContent = envContent.replace(
        /REACT_APP_VOTER_DID_LITE_CONTRACT_ADDRESS=.*/,
        `REACT_APP_VOTER_DID_LITE_CONTRACT_ADDRESS=${voterDIDLite.address}`
      );
    } else {
      envContent += `\nREACT_APP_VOTER_DID_LITE_CONTRACT_ADDRESS=${voterDIDLite.address}\n`;
    }
    
    fs.writeFileSync(envFile, envContent);
    console.log(`Updated .env file with VoterDIDLite contract address: ${voterDIDLite.address}`);
  }

  return voterDIDLite;
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Deployment failed:", error);
    process.exit(1);
  });
EOF

# 3. BallotValidation Contract
cat > scripts/deploy_ballotValidation.js << 'EOF'
const hre = require("hardhat");

async function main() {
  console.log("Deploying BallotValidation contract to APEChain Curtis Testnet...");
  
  // Get the ContractFactory
  const BallotValidation = await hre.ethers.getContractFactory("BallotValidation");
  
  // Get current gas price from the network
  const provider = hre.ethers.provider;
  const gasPrice = await provider.getGasPrice();
  
  // Calculate a lower gas price (60% of current)
  const lowerGasPrice = gasPrice.mul(60).div(100);
  
  console.log(`Using lower gas price: ${hre.ethers.utils.formatUnits(lowerGasPrice, 'gwei')} gwei`);
  
  // Deploy with custom gas settings
  const deploymentOptions = {
    gasPrice: lowerGasPrice,
    gasLimit: 3000000
  };
  
  // Deploy it
  const ballotValidation = await BallotValidation.deploy(deploymentOptions);
  
  // Wait for deployment to finish
  await ballotValidation.deployed();

  console.log(`BallotValidation deployed to: ${ballotValidation.address}`);
  console.log(`Transaction hash: ${ballotValidation.deployTransaction.hash}`);
  
  // Update .env file with the contract address
  const fs = require('fs');
  const path = require('path');
  const envFile = path.join(__dirname, '..', '.env');
  
  if (fs.existsSync(envFile)) {
    let envContent = fs.readFileSync(envFile, 'utf8');
    
    // Replace or add the contract address
    if (envContent.includes('REACT_APP_BALLOTVALIDATION_CONTRACT_ADDRESS=')) {
      envContent = envContent.replace(
        /REACT_APP_BALLOTVALIDATION_CONTRACT_ADDRESS=.*/,
        `REACT_APP_BALLOTVALIDATION_CONTRACT_ADDRESS=${ballotValidation.address}`
      );
    } else {
      envContent += `\nREACT_APP_BALLOTVALIDATION_CONTRACT_ADDRESS=${ballotValidation.address}\n`;
    }
    
    fs.writeFileSync(envFile, envContent);
    console.log(`Updated .env file with BallotValidation contract address: ${ballotValidation.address}`);
  }

  return ballotValidation;
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Deployment failed:", error);
    process.exit(1);
  });
EOF

# Deploy contracts
echo ""
echo "Starting deployment process..."
echo "==========================="

# Make sure PRIVATE_KEY is set correctly in hardhat.config.js
echo "Checking for private key..."
if grep -q "PRIVATE_KEY = process.env.PRIVATE_KEY" hardhat.config.js; then
  # Update hardhat.config.js to use REACT_APP_ADMIN_PRIVATE_KEY
  echo "Updating hardhat.config.js to use REACT_APP_ADMIN_PRIVATE_KEY..."
  sed -i 's/PRIVATE_KEY = process.env.PRIVATE_KEY/PRIVATE_KEY = process.env.REACT_APP_ADMIN_PRIVATE_KEY/g' hardhat.config.js
fi

# Check wallet balance first
echo "Checking wallet balance..."
BALANCE_SCRIPT=$(cat << 'EOF'
const { ethers } = require('ethers');
require('dotenv').config();

async function checkBalance() {
  const rpcUrl = process.env.REACT_APP_APECHAIN_RPC_ENDPOINT || 'https://curtis.rpc.caldera.xyz/http';
  const privateKey = process.env.REACT_APP_ADMIN_PRIVATE_KEY;
  
  if (!privateKey) {
    console.error('Error: No admin private key provided in environment variables');
    process.exit(1);
  }
  
  try {
    const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
    const formattedKey = privateKey.startsWith('0x') ? privateKey : `0x${privateKey}`;
    const wallet = new ethers.Wallet(formattedKey, provider);
    
    console.log(`Wallet address: ${wallet.address}`);
    
    const balance = await provider.getBalance(wallet.address);
    const balanceInEth = ethers.utils.formatEther(balance);
    
    console.log(`Balance: ${balanceInEth} APE`);
    
    if (balance.eq(0)) {
      console.error('Warning: Wallet has zero balance');
      console.error('The wallet needs APE tokens to pay for gas fees');
      console.error('Get tokens from a testnet faucet before proceeding');
      process.exit(1);
    }
    
    process.exit(0);
  } catch (error) {
    console.error('Error checking balance:', error);
    process.exit(1);
  }
}

checkBalance();
EOF
)

echo "$BALANCE_SCRIPT" > check_balance_temp.js
node check_balance_temp.js
if [ $? -ne 0 ]; then
  echo "Error checking wallet balance. Please ensure your wallet has APE tokens."
  rm check_balance_temp.js
  exit 1
fi
rm check_balance_temp.js

# Display deployment menu
echo ""
echo "Which contracts would you like to deploy?"
echo "1) Deploy all contracts"
echo "2) Deploy VoterDID only"
echo "3) Deploy VoterDIDLite only (gas-optimized)"
echo "4) Deploy BallotValidation only"
echo "5) Exit without deploying"
read -p "Enter your choice (1-5): " choice

case $choice in
  1)
    echo "Deploying all contracts..."
    echo ""
    echo "1. Deploying VoterDID contract..."
    npx hardhat run scripts/deploy_voterDID.js --network apechain_curtis
    echo ""
    
    echo "2. Deploying VoterDIDLite contract..."
    npx hardhat run scripts/deploy_voterDIDLite.js --network apechain_curtis
    echo ""
    
    echo "3. Deploying BallotValidation contract..."
    npx hardhat run scripts/deploy_ballotValidation.js --network apechain_curtis
    ;;
  2)
    echo "Deploying VoterDID contract only..."
    npx hardhat run scripts/deploy_voterDID.js --network apechain_curtis
    ;;
  3)
    echo "Deploying VoterDIDLite contract only..."
    npx hardhat run scripts/deploy_voterDIDLite.js --network apechain_curtis
    ;;
  4)
    echo "Deploying BallotValidation contract only..."
    npx hardhat run scripts/deploy_ballotValidation.js --network apechain_curtis
    ;;
  5)
    echo "Exiting without deployment."
    exit 0
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac

echo ""
echo "=== Deployment Process Complete ==="
echo "Check the .env file for updated contract addresses."
echo ""

# Clean up
rm -f scripts/deploy_voterDID.js
rm -f scripts/deploy_voterDIDLite.js
rm -f scripts/deploy_ballotValidation.js

# Return to original directory
cd - > /dev/null
