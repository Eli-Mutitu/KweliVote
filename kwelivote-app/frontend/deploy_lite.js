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
