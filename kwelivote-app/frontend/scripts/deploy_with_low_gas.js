const { ethers } = require('ethers');
require('dotenv').config({ path: '.env' });
const VoterDIDArtifact = require('../artifacts/contracts/VoterDID.sol/VoterDID.json');

/**
 * This script deploys the VoterDID contract to APEChain Curtis Testnet
 * with optimized gas settings to minimize the cost
 */

async function main() {
  console.log('=== Deploying VoterDID Contract with Low Gas Settings ===');
  
  // Get configuration from environment variables
  const config = {
    rpcUrl: process.env.REACT_APP_APECHAIN_RPC_ENDPOINT || 'https://curtis.rpc.caldera.xyz/http',
    chainId: parseInt(process.env.REACT_APP_APECHAIN_CHAIN_ID || '33111'),
    networkName: process.env.REACT_APP_APECHAIN_NETWORK_NAME || 'APEChain Curtis Testnet',
    privateKey: process.env.REACT_APP_ADMIN_PRIVATE_KEY
  };
  
  if (!config.privateKey) {
    console.error('Error: No admin private key provided in environment variables');
    console.error('Set REACT_APP_ADMIN_PRIVATE_KEY in .env file');
    process.exit(1);
  }
  
  console.log(`Network: ${config.networkName} (Chain ID: ${config.chainId})`);
  console.log(`RPC URL: ${config.rpcUrl}`);
  
  try {
    // Create provider
    const provider = new ethers.providers.JsonRpcProvider(config.rpcUrl);
    
    // Verify network connection
    const network = await provider.getNetwork();
    console.log(`Connected to network: ${network.name} (${network.chainId})`);
    
    // Create wallet
    const formattedKey = config.privateKey.startsWith('0x') 
      ? config.privateKey 
      : `0x${config.privateKey}`;
    
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
    
    // Get current gas price from the network
    const gasPrice = await provider.getGasPrice();
    
    // Calculate a lower gas price (75% of current)
    const lowerGasPrice = gasPrice.mul(75).div(100);
    
    console.log(`Current network gas price: ${ethers.utils.formatUnits(gasPrice, 'gwei')} gwei`);
    console.log(`Using lower gas price: ${ethers.utils.formatUnits(lowerGasPrice, 'gwei')} gwei`);
    
    // Deploy contract with custom gas settings
    console.log('Deploying VoterDID contract with low gas settings...');
    const { abi, bytecode } = VoterDIDArtifact;
    
    const factory = new ethers.ContractFactory(abi, bytecode, wallet);
    
    // Set gas price and limit for deployment
    const deploymentOptions = {
      gasPrice: lowerGasPrice,
      gasLimit: 3000000 // Explicit reasonable gas limit
    };
    
    console.log(`Deployment options: ${JSON.stringify(deploymentOptions)}`);
    
    const contract = await factory.deploy(deploymentOptions);
    
    console.log(`Transaction hash: ${contract.deployTransaction.hash}`);
    console.log('Waiting for deployment to complete...');
    
    // Wait for contract to be deployed
    await contract.deployed();
    
    console.log('✅ Contract deployed successfully!');
    console.log(`Contract address: ${contract.address}`);
    console.log(`Transaction hash: ${contract.deployTransaction.hash}`);
    console.log(`Block number: ${contract.deployTransaction.blockNumber}`);
    console.log(`Gas used: ${contract.deployTransaction.gasLimit.toString()}`);
    console.log(`Gas price: ${ethers.utils.formatUnits(contract.deployTransaction.gasPrice, 'gwei')} gwei`);
    
    console.log('\nUpdate your .env file with:');
    console.log(`REACT_APP_VOTER_DID_CONTRACT_ADDRESS=${contract.address}`);
    
    // Return the contract address
    return contract.address;
  } catch (error) {
    console.error('Error deploying contract:', error);
    if (error.code === 'INSUFFICIENT_FUNDS') {
      console.error('\nINSUFFICIENT FUNDS ERROR: Your wallet does not have enough APE tokens');
      console.error('Even with lower gas settings, you need some tokens to deploy a contract');
      console.error('Please fund your wallet with APE tokens from a testnet faucet');
    } else if (error.code === 'UNPREDICTABLE_GAS_LIMIT') {
      console.error('\nGAS ESTIMATION ERROR: Could not estimate gas for deployment');
      console.error('This could be due to contract initialization issues or network congestion');
    }
    process.exit(1);
  }
}

// Execute the deployment
main()
  .then(contractAddress => {
    console.log(`\nDeployment successful. New contract: ${contractAddress}`);
    process.exit(0);
  })
  .catch(error => {
    console.error('Deployment failed:', error);
    process.exit(1);
  });
