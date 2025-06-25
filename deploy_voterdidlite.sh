#!/bin/bash

# Direct script to compile and deploy VoterDIDLite contract
echo "=== Direct VoterDIDLite Contract Deployment ==="

# Navigate to the frontend directory
cd /home/quest/myrepos/KweliVote-1/kwelivote-app/frontend

# Install dependencies if needed
echo "Checking dependencies..."
npm install --silent

# Compile the contracts
echo "Compiling contracts..."
npx hardhat compile

# Check if compilation was successful
if [ $? -ne 0 ]; then
  echo "Compilation failed. Trying to install missing dependencies..."
  npm install --save-dev @nomiclabs/hardhat-ethers @nomiclabs/hardhat-waffle @nomiclabs/hardhat-etherscan hardhat-deploy ethereum-waffle
  echo "Retrying compilation..."
  npx hardhat compile
  
  if [ $? -ne 0 ]; then
    echo "Compilation failed again. Exiting."
    exit 1
  fi
fi

echo "Compilation successful!"

# Create a simple deployment script
echo "Creating deployment script..."
cat > deploy_lite.js << 'EOF'
// Simple script to deploy VoterDIDLite contract
const hre = require("hardhat");

async function main() {
  console.log("Deploying VoterDIDLite contract...");
  
  const VoterDIDLite = await hre.ethers.getContractFactory("VoterDIDLite");
  console.log("Contract factory created");
  
  // Get gas price
  const provider = hre.ethers.provider;
  const gasPrice = await provider.getGasPrice();
  console.log(`Current gas price: ${hre.ethers.utils.formatUnits(gasPrice, 'gwei')} gwei`);
  
  // Lower gas price
  const lowerGasPrice = gasPrice.mul(40).div(100);
  console.log(`Using lower gas price: ${hre.ethers.utils.formatUnits(lowerGasPrice, 'gwei')} gwei`);
  
  // Deploy with options
  const deploymentOptions = {
    gasPrice: lowerGasPrice,
    gasLimit: 2000000
  };
  
  const contract = await VoterDIDLite.deploy(deploymentOptions);
  console.log(`Transaction hash: ${contract.deployTransaction.hash}`);
  
  await contract.deployed();
  console.log(`Contract deployed to: ${contract.address}`);
  
  return contract.address;
}

main()
  .then((address) => {
    console.log(`Deployment successful: ${address}`);
    process.exit(0);
  })
  .catch((error) => {
    console.error("Deployment failed:", error);
    process.exit(1);
  });
EOF

# Deploy the contract
echo "Deploying VoterDIDLite contract..."
npx hardhat run deploy_lite.js --network apechain_curtis

echo "Deployment process complete!"
