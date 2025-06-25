#!/bin/bash

# Compile and deploy VoterDIDLite contract with lower gas settings
# This script handles the complete process from compilation to deployment

echo "=== Compile and Deploy VoterDIDLite Contract ==="
echo "This script will compile and deploy the gas-optimized VoterDIDLite.sol contract"
echo ""

# Navigate to the frontend directory
cd "$(dirname "$0")/kwelivote-app/frontend"

# Check for wallet private key
if [ -z "$REACT_APP_ADMIN_PRIVATE_KEY" ]; then
  if [ -f .env ]; then
    source .env
  fi
  
  if [ -z "$REACT_APP_ADMIN_PRIVATE_KEY" ]; then
    echo "No wallet private key found in environment variables"
    echo "Please enter your private key (without 0x prefix):"
    read -s PRIVATE_KEY
    
    if [ -z "$PRIVATE_KEY" ]; then
      echo "Error: No private key provided"
      exit 1
    fi
    
    # Update .env file
    if grep -q "REACT_APP_ADMIN_PRIVATE_KEY=" .env; then
      sed -i "s/REACT_APP_ADMIN_PRIVATE_KEY=.*/REACT_APP_ADMIN_PRIVATE_KEY=$PRIVATE_KEY/" .env
    else
      echo "REACT_APP_ADMIN_PRIVATE_KEY=$PRIVATE_KEY" >> .env
    fi
    
    echo "Private key saved to .env file"
  fi
fi

# Step 1: Compile the contract
echo "Compiling contracts with Hardhat..."
npx hardhat compile

# Check if compilation was successful
if [ ! -d "./src/artifacts/contracts/VoterDIDLite.sol" ]; then
  echo "Error: Contract compilation failed or artifacts not found"
  exit 1
fi

# Step 2: Create a temporary deploy script that looks in the right location
echo "Creating deployment script..."
cat > deploy_temp.js << 'EOF'
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
    // Use artifacts from the correct location
    const VoterDIDLiteArtifact = require('./src/artifacts/contracts/VoterDIDLite.sol/VoterDIDLite.json');
    
    const provider = new ethers.providers.JsonRpcProvider(config.rpcUrl);
    const formattedKey = config.privateKey.startsWith('0x') ? config.privateKey : `0x${config.privateKey}`;
    const wallet = new ethers.Wallet(formattedKey, provider);
    
    console.log(`Deploying from wallet address: ${wallet.address}`);
    
    // Check wallet balance
    const balance = await provider.getBalance(wallet.address);
    const balanceInEth = ethers.utils.formatEther(balance);
    console.log(`Wallet balance: ${balanceInEth} APE`);
    
    if (balance.eq(0)) {
      console.error('Error: Wallet has zero balance');
      console.error('The wallet needs APE tokens to pay for gas fees');
      process.exit(1);
    }
    
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
    
    // Update .env file with the new contract address
    const fs = require('fs');
    let envContent = fs.readFileSync('.env', 'utf8');
    envContent = envContent.replace(/REACT_APP_VOTER_DID_CONTRACT_ADDRESS=.*/, `REACT_APP_VOTER_DID_CONTRACT_ADDRESS=${contract.address}`);
    fs.writeFileSync('.env', envContent);
    
    console.log('✅ .env file updated with new contract address');
    
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

# Step 3: Deploy the contract
echo "Deploying VoterDIDLite contract..."
node deploy_temp.js

# Clean up
rm deploy_temp.js

echo "Deployment process completed."
