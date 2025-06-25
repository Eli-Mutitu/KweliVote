#!/bin/bash

# Deploy New Contracts with Lower Gas Settings
# This script helps deploy contracts with minimal gas fees to APEChain Curtis Testnet

echo "=== Deploy New Contracts with Lower Gas Settings ==="
echo "This script helps deploy contracts when you have limited APE tokens"
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

# Check for Node.js
if ! command -v node &> /dev/null; then
  echo "Error: Node.js is not installed"
  echo "Please install Node.js to use this script"
  exit 1
fi

# Navigate to the frontend directory
cd kwelivote-app/frontend

# Check wallet balance first
check_balance() {
  echo "Checking wallet balance..."
  
  # Create a temporary script to check balance
  cat > check_balance.js << 'EOF'
const { ethers } = require('ethers');
require('dotenv').config();

async function checkBalance() {
  const rpcUrl = process.env.REACT_APP_APECHAIN_RPC_ENDPOINT || 'https://curtis.rpc.caldera.xyz/http';
  const privateKey = process.env.REACT_APP_ADMIN_PRIVATE_KEY;
  
  if (!privateKey) {
    console.error('Error: No admin private key provided in environment variables');
    return false;
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
      return false;
    }
    
    return true;
  } catch (error) {
    console.error('Error checking balance:', error);
    return false;
  }
}

checkBalance()
  .then(hasBalance => {
    process.exit(hasBalance ? 0 : 1);
  })
  .catch(error => {
    console.error('Error:', error);
    process.exit(1);
  });
EOF

  # Run the script
  node check_balance.js
  local result=$?
  
  # Clean up
  rm check_balance.js
  
  return $result
}

# Deploy the standard contract with lower gas
deploy_standard_contract() {
  echo "Deploying standard VoterDID contract with lower gas settings..."
  
  # Check if deploy script exists, create if not
  if [ ! -f "./scripts/deploy_with_low_gas.js" ]; then
    echo "Creating deployment script..."
    
    mkdir -p scripts
    
    cat > scripts/deploy_with_low_gas.js << 'EOF'
const { ethers } = require('ethers');
require('dotenv').config();
const VoterDIDArtifact = require('../artifacts/contracts/VoterDID.sol/VoterDID.json');

async function main() {
  console.log('=== Deploying VoterDID Contract with Low Gas Settings ===');
  
  const config = {
    rpcUrl: process.env.REACT_APP_APECHAIN_RPC_ENDPOINT || 'https://curtis.rpc.caldera.xyz/http',
    chainId: parseInt(process.env.REACT_APP_APECHAIN_CHAIN_ID || '33111'),
    privateKey: process.env.REACT_APP_ADMIN_PRIVATE_KEY
  };
  
  if (!config.privateKey) {
    console.error('Error: No admin private key provided');
    process.exit(1);
  }
  
  try {
    const provider = new ethers.providers.JsonRpcProvider(config.rpcUrl);
    const formattedKey = config.privateKey.startsWith('0x') ? config.privateKey : `0x${config.privateKey}`;
    const wallet = new ethers.Wallet(formattedKey, provider);
    
    console.log(`Deploying from wallet address: ${wallet.address}`);
    
    const gasPrice = await provider.getGasPrice();
    const lowerGasPrice = gasPrice.mul(60).div(100);
    
    console.log(`Using lower gas price: ${ethers.utils.formatUnits(lowerGasPrice, 'gwei')} gwei`);
    
    const { abi, bytecode } = VoterDIDArtifact;
    const factory = new ethers.ContractFactory(abi, bytecode, wallet);
    
    const deploymentOptions = {
      gasPrice: lowerGasPrice,
      gasLimit: 3000000
    };
    
    const contract = await factory.deploy(deploymentOptions);
    console.log(`Transaction hash: ${contract.deployTransaction.hash}`);
    
    await contract.deployed();
    
    console.log('✅ Contract deployed successfully!');
    console.log(`Contract address: ${contract.address}`);
    
    return contract.address;
  } catch (error) {
    console.error('Error deploying contract:', error);
    process.exit(1);
  }
}

main()
  .then(contractAddress => {
    console.log(`\nDeployment successful. New contract: ${contractAddress}`);
    process.exit(0);
  })
  .catch(error => {
    console.error('Deployment failed:', error);
    process.exit(1);
  });
EOF
  fi
  
  # Compile if needed
  if [ ! -d "./artifacts" ] || [ ! -f "./artifacts/contracts/VoterDID.sol/VoterDID.json" ]; then
    echo "Compiling contracts..."
    npx hardhat compile
  fi
  
  # Deploy
  npx hardhat run scripts/deploy_with_low_gas.js --no-compile
  return $?
}

# Deploy the lite (gas optimized) contract
deploy_lite_contract() {
  echo "Deploying lite VoterDIDLite contract (ultra low gas usage)..."
  
  # Check if VoterDIDLite contract exists, create if not
  if [ ! -f "./contracts/VoterDIDLite.sol" ]; then
    echo "Creating VoterDIDLite contract..."
    
    mkdir -p contracts
    
    cat > contracts/VoterDIDLite.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title VoterDIDLite
 * @dev A lightweight version of the VoterDID contract that uses less gas
 */
contract VoterDIDLite {
    address public admin;
    mapping(string => string) private voterDIDs;
    mapping(string => bool) private registeredVoters;
    event DIDRegistered(string nationalId);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }
    
    constructor() {
        admin = msg.sender;
    }
    
    function registerDID(string memory nationalId, string memory did) public onlyAdmin {
        require(bytes(nationalId).length > 0, "Empty ID");
        require(bytes(did).length > 0, "Empty DID");
        voterDIDs[nationalId] = did;
        if (!registeredVoters[nationalId]) {
            registeredVoters[nationalId] = true;
        }
        emit DIDRegistered(nationalId);
    }
    
    function getDID(string memory nationalId) public view returns (string memory) {
        return voterDIDs[nationalId];
    }
    
    function registerVoter(string memory did, string memory nationalId) public onlyAdmin {
        registerDID(nationalId, did);
    }
}
EOF
  fi
  
  # Create deployment script
  cat > scripts/deploy_lite_contract.js << 'EOF'
const { ethers } = require('ethers');
require('dotenv').config();

async function main() {
  console.log('=== Deploying VoterDIDLite Contract (Ultra Low Gas) ===');
  
  const config = {
    rpcUrl: process.env.REACT_APP_APECHAIN_RPC_ENDPOINT || 'https://curtis.rpc.caldera.xyz/http',
    chainId: parseInt(process.env.REACT_APP_APECHAIN_CHAIN_ID || '33111'),
    privateKey: process.env.REACT_APP_ADMIN_PRIVATE_KEY
  };
  
  if (!config.privateKey) {
    console.error('Error: No admin private key provided');
    process.exit(1);
  }
  
  try {
    // Use artifacts from compilation
    const VoterDIDLiteArtifact = require('../artifacts/contracts/VoterDIDLite.sol/VoterDIDLite.json');
    
    const provider = new ethers.providers.JsonRpcProvider(config.rpcUrl);
    const formattedKey = config.privateKey.startsWith('0x') ? config.privateKey : `0x${config.privateKey}`;
    const wallet = new ethers.Wallet(formattedKey, provider);
    
    console.log(`Deploying from wallet address: ${wallet.address}`);
    
    const gasPrice = await provider.getGasPrice();
    const lowerGasPrice = gasPrice.mul(40).div(100); // 40% of current price
    
    console.log(`Using ultra-low gas price: ${ethers.utils.formatUnits(lowerGasPrice, 'gwei')} gwei`);
    
    const { abi, bytecode } = VoterDIDLiteArtifact;
    const factory = new ethers.ContractFactory(abi, bytecode, wallet);
    
    const deploymentOptions = {
      gasPrice: lowerGasPrice,
      gasLimit: 2000000 // Lower limit for optimized contract
    };
    
    const contract = await factory.deploy(deploymentOptions);
    console.log(`Transaction hash: ${contract.deployTransaction.hash}`);
    
    await contract.deployed();
    
    console.log('✅ Contract deployed successfully!');
    console.log(`Contract address: ${contract.address}`);
    
    return contract.address;
  } catch (error) {
    console.error('Error deploying contract:', error);
    process.exit(1);
  }
}

main()
  .then(contractAddress => {
    console.log(`\nDeployment successful. New lite contract: ${contractAddress}`);
    process.exit(0);
  })
  .catch(error => {
    console.error('Deployment failed:', error);
    process.exit(1);
  });
EOF
  
  # Compile contracts
  echo "Compiling contracts..."
  npx hardhat compile
  
  # Deploy
  npx hardhat run scripts/deploy_lite_contract.js --no-compile
  return $?
}

# Update environment variables with new contract address
update_env_files() {
  local contract_address="$1"
  local contract_type="$2"
  
  if [ -z "$contract_address" ]; then
    echo "Error: No contract address provided"
    return 1
  fi
  
  echo "Updating environment files with new $contract_type contract address: $contract_address"
  
  # Update .env if it exists
  if [ -f "./.env" ]; then
    # Check if the variable exists
    if grep -q "REACT_APP_VOTER_DID_CONTRACT_ADDRESS" .env; then
      # Replace existing value
      sed -i "s|REACT_APP_VOTER_DID_CONTRACT_ADDRESS=.*|REACT_APP_VOTER_DID_CONTRACT_ADDRESS=$contract_address|" .env
    else
      # Add new value
      echo "REACT_APP_VOTER_DID_CONTRACT_ADDRESS=$contract_address" >> .env
    fi
    echo "Updated .env file"
  fi
  
  # Update .env.development if it exists
  if [ -f "./.env.development" ]; then
    # Check if the variable exists
    if grep -q "REACT_APP_VOTER_DID_CONTRACT_ADDRESS" .env.development; then
      # Replace existing value
      sed -i "s|REACT_APP_VOTER_DID_CONTRACT_ADDRESS=.*|REACT_APP_VOTER_DID_CONTRACT_ADDRESS=$contract_address|" .env.development
    else
      # Add new value
      echo "REACT_APP_VOTER_DID_CONTRACT_ADDRESS=$contract_address" >> .env.development
    fi
    echo "Updated .env.development file"
  fi
  
  echo "Environment files updated successfully"
  return 0
}

# Main menu
show_menu() {
  echo ""
  echo "Select an option:"
  echo "1) Check wallet balance"
  echo "2) Deploy standard contract with lower gas"
  echo "3) Deploy lite contract (ultra low gas)"
  echo "4) Exit"
  echo ""
  read -p "Enter your choice (1-4): " choice
  
  case $choice in
    1) 
      check_balance
      show_menu
      ;;
    2)
      if check_balance; then
        if deploy_standard_contract; then
          # Extract contract address from output
          contract_address=$(grep -o "New contract: 0x[a-fA-F0-9]*" .hardhat_output.log | cut -d' ' -f3)
          if [ -n "$contract_address" ]; then
            update_env_files "$contract_address" "standard"
          fi
        fi
      else
        echo "Cannot deploy contract: insufficient funds"
      fi
      show_menu
      ;;
    3)
      if check_balance; then
        if deploy_lite_contract; then
          # Extract contract address from output
          contract_address=$(grep -o "New lite contract: 0x[a-fA-F0-9]*" .hardhat_output.log | cut -d' ' -f4)
          if [ -n "$contract_address" ]; then
            update_env_files "$contract_address" "lite"
          fi
        fi
      else
        echo "Cannot deploy contract: insufficient funds"
      fi
      show_menu
      ;;
    4)
      echo "Exiting..."
      exit 0
      ;;
    *)
      echo "Invalid choice. Please enter a number between 1 and 4."
      show_menu
      ;;
  esac
}

# Start the script
show_menu
