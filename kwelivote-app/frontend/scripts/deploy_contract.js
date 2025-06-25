import { ethers } from 'ethers';
import VoterDIDArtifact from '../artifacts/contracts/VoterDID.sol/VoterDID.json';

/**
 * This script deploys the VoterDID contract to APEChain Curtis Testnet
 * It uses the admin private key from the environment variable
 * After deployment, it logs the contract address that should be used in .env.development
 */

// APEChain configuration from .env.development
const config = {
  networkName: process.env.REACT_APP_APECHAIN_NETWORK_NAME || 'APEChain Curtis Testnet',
  chainId: parseInt(process.env.REACT_APP_APECHAIN_CHAIN_ID || '33111'),
  rpcUrl: process.env.REACT_APP_APECHAIN_RPC_ENDPOINT || 'https://curtis.rpc.caldera.xyz/http',
  explorerUrl: process.env.REACT_APP_APECHAIN_EXPLORER_URL || 'https://curtis.apescan.io',
  adminPrivateKey: process.env.REACT_APP_ADMIN_PRIVATE_KEY,
};

async function deployContract() {
  console.log('=== APEChain Contract Deployment ===');
  console.log('Network:', config.networkName);
  console.log('Chain ID:', config.chainId);
  console.log('RPC URL:', config.rpcUrl);
  
  if (!config.adminPrivateKey) {
    console.error('Error: No admin private key provided in environment variables');
    console.error('Set REACT_APP_ADMIN_PRIVATE_KEY in .env.development');
    return false;
  }
  
  try {
    // Create provider
    const provider = new ethers.providers.JsonRpcProvider(config.rpcUrl);
    
    // Verify network connection
    const network = await provider.getNetwork();
    console.log('Connected to network:', network.name, `(${network.chainId})`);
    
    // Create wallet
    const formattedKey = config.adminPrivateKey.startsWith('0x') 
      ? config.adminPrivateKey 
      : `0x${config.adminPrivateKey}`;
    
    const wallet = new ethers.Wallet(formattedKey, provider);
    console.log('Deploying from wallet address:', wallet.address);
    
    // Check wallet balance
    const balance = await provider.getBalance(wallet.address);
    const balanceInEth = ethers.utils.formatEther(balance);
    console.log('Wallet balance:', balanceInEth, 'APE');
    
    if (balance.eq(0)) {
      console.error('Error: Wallet has zero balance');
      console.error('The wallet needs APE tokens to pay for gas fees');
      return false;
    }
    
    // Deploy contract
    console.log('Deploying VoterDID contract...');
    const { abi, bytecode } = VoterDIDArtifact;
    
    const factory = new ethers.ContractFactory(abi, bytecode, wallet);
    const contract = await factory.deploy();
    
    console.log('Transaction hash:', contract.deployTransaction.hash);
    console.log('Waiting for deployment to complete...');
    
    // Wait for contract to be deployed
    await contract.deployed();
    
    console.log('✅ Contract deployed successfully!');
    console.log('Contract address:', contract.address);
    console.log('Transaction hash:', contract.deployTransaction.hash);
    console.log('Block number:', contract.deployTransaction.blockNumber);
    console.log('Gas used:', contract.deployTransaction.gasLimit.toString());
    
    console.log('\nUpdate your .env.development file with:');
    console.log(`REACT_APP_VOTER_DID_CONTRACT_ADDRESS=${contract.address}`);
    
    return {
      success: true,
      contractAddress: contract.address,
      transactionHash: contract.deployTransaction.hash
    };
  } catch (error) {
    console.error('Error deploying contract:', error);
    return {
      success: false,
      error: error.message
    };
  }
}

deployContract()
  .then(result => {
    if (result && result.success) {
      console.log('Deployment completed successfully.');
    } else {
      console.error('Deployment failed. Please fix the issues before proceeding.');
    }
    process.exit(0);
  })
  .catch(error => {
    console.error('Deployment failed with error:', error);
    process.exit(1);
  });
