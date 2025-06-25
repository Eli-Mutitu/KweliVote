import { ethers } from 'ethers';
import VoterDIDArtifact from '../artifacts/contracts/VoterDID.sol/VoterDID.json';

/**
 * This script verifies the APEChain contract deployment and configuration
 * It checks that the contract is deployed and accessible
 * It also verifies that the admin private key is correctly configured
 */

// APEChain configuration from .env.development
const config = {
  networkName: process.env.REACT_APP_APECHAIN_NETWORK_NAME || 'APEChain Curtis Testnet',
  chainId: parseInt(process.env.REACT_APP_APECHAIN_CHAIN_ID || '33111'),
  rpcUrl: process.env.REACT_APP_APECHAIN_RPC_ENDPOINT || 'https://curtis.rpc.caldera.xyz/http',
  explorerUrl: process.env.REACT_APP_APECHAIN_EXPLORER_URL || 'https://curtis.apescan.io',
  contractAddress: process.env.REACT_APP_VOTER_DID_CONTRACT_ADDRESS,
  adminPrivateKey: process.env.REACT_APP_ADMIN_PRIVATE_KEY,
};

async function verifyContractDeployment() {
  console.log('=== APEChain Contract Verification ===');
  console.log('Network:', config.networkName);
  console.log('Chain ID:', config.chainId);
  console.log('RPC URL:', config.rpcUrl);
  
  if (!config.contractAddress) {
    console.error('Error: No contract address provided in environment variables');
    console.error('Set REACT_APP_VOTER_DID_CONTRACT_ADDRESS in .env.development');
    return false;
  }
  
  console.log('Contract Address:', config.contractAddress);
  
  try {
    // Create provider
    const provider = new ethers.providers.JsonRpcProvider(config.rpcUrl);
    
    // Verify network connection
    const network = await provider.getNetwork();
    console.log('Connected to network:', network.name, `(${network.chainId})`);
    
    // Verify contract exists
    const code = await provider.getCode(config.contractAddress);
    if (code === '0x') {
      console.error('Error: No contract deployed at the specified address');
      console.error('Verify that the contract address is correct and the contract is deployed');
      return false;
    }
    
    console.log('Contract code verified at the specified address');
    
    // Create contract instance
    const { abi } = VoterDIDArtifact;
    const contract = new ethers.Contract(config.contractAddress, abi, provider);
    
    // Try to call a view function
    const admin = await contract.admin();
    console.log('Contract admin address:', admin);
    
    // Verify private key is configured
    if (!config.adminPrivateKey) {
      console.error('Error: No admin private key provided in environment variables');
      console.error('Set REACT_APP_ADMIN_PRIVATE_KEY in .env.development');
      return false;
    }
    
    // Verify private key format
    try {
      const formattedKey = config.adminPrivateKey.startsWith('0x') 
        ? config.adminPrivateKey 
        : `0x${config.adminPrivateKey}`;
      
      const wallet = new ethers.Wallet(formattedKey, provider);
      console.log('Admin wallet address:', wallet.address);
      
      // Check if wallet address matches contract admin
      if (wallet.address.toLowerCase() === admin.toLowerCase()) {
        console.log('✅ Admin private key matches contract admin address');
      } else {
        console.warn('⚠️ Warning: Admin private key does not match contract admin address');
        console.warn('  - Wallet address:', wallet.address);
        console.warn('  - Contract admin:', admin);
        console.warn('The configured private key may not have permission to register DIDs');
      }
      
      // Check wallet balance
      const balance = await provider.getBalance(wallet.address);
      const balanceInEth = ethers.utils.formatEther(balance);
      console.log('Admin wallet balance:', balanceInEth, 'APE');
      
      if (balance.eq(0)) {
        console.warn('⚠️ Warning: Admin wallet has zero balance');
        console.warn('The wallet needs APE tokens to pay for gas fees');
      }
    } catch (error) {
      console.error('Error verifying private key:', error.message);
      return false;
    }
    
    console.log('✅ Contract verification completed successfully');
    return true;
  } catch (error) {
    console.error('Error verifying contract:', error.message);
    return false;
  }
}

verifyContractDeployment()
  .then(result => {
    if (result) {
      console.log('All checks passed. The contract is properly deployed and configured.');
    } else {
      console.error('Some checks failed. Please fix the issues before proceeding.');
    }
  })
  .catch(error => {
    console.error('Verification failed with error:', error);
  });
