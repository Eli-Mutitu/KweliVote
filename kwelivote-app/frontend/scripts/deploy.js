// Deployment script for VoterDID and BallotValidation contracts
const hre = require("hardhat");

async function main() {
  // Get the deployer's address
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  
  // Deploy VoterDID contract
  console.log("Deploying VoterDID contract...");
  const VoterDID = await hre.ethers.getContractFactory("VoterDID");
  const voterDID = await VoterDID.deploy();
  await voterDID.deployed();
  
  console.log("VoterDID contract deployed to:", voterDID.address);
  console.log("Transaction hash:", voterDID.deployTransaction.hash);
  
  // Wait for confirmations
  console.log("Waiting for confirmations...");
  await voterDID.deployTransaction.wait(2);
  console.log("VoterDID deployment confirmed!");
  
  // Deploy BallotValidation contract
  console.log("\nDeploying BallotValidation contract...");
  const BallotValidation = await hre.ethers.getContractFactory("BallotValidation");
  const ballotValidation = await BallotValidation.deploy();
  await ballotValidation.deployed();
  
  console.log("BallotValidation contract deployed to:", ballotValidation.address);
  console.log("Transaction hash:", ballotValidation.deployTransaction.hash);
  
  // Wait for confirmations
  console.log("Waiting for confirmations...");
  await ballotValidation.deployTransaction.wait(2);
  console.log("BallotValidation deployment confirmed!");
  
  // Print summary
  console.log("\nDeployment Summary:");
  console.log("-------------------");
  console.log("Network:              ", hre.network.name);
  console.log("VoterDID:             ", voterDID.address);
  console.log("BallotValidation:     ", ballotValidation.address);
  console.log("-------------------");
  console.log("Don't forget to update your .env file with these contract addresses!");
}

// Execute the deployment
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Deployment failed:", error);
    process.exit(1);
  });