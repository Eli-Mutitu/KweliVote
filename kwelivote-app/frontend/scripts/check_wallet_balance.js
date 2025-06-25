import { ethers } from 'ethers';

/**
 * This script checks the balance of the admin wallet on the APEChain network
 * and provides instructions on how to fund the wallet with APE tokens.
 */

// Get environment variables
const adminPrivateKey = process.env.REACT_APP_ADMIN_PRIVATE_KEY;
const rpcEndpoint = process.env.REACT_APP_APECHAIN_RPC_ENDPOINT || 'https://curtis.rpc.caldera.xyz/http';
const explorerUrl = process.env.REACT_APP_APECHAIN_EXPLORER_URL || 'https://curtis.apescan.io';

async function checkWalletBalance() {
  // Validate private key
  if (!adminPrivateKey) {
    console.error('❌ No admin private key found in environment variables');
    console.error('Please set REACT_APP_ADMIN_PRIVATE_KEY in your .env.development file');
    return;
  }

  try {
    // Create provider
    const provider = new ethers.providers.JsonRpcProvider(rpcEndpoint);
    
    // Create wallet
    const formattedKey = adminPrivateKey.startsWith('0x') ? adminPrivateKey : `0x${adminPrivateKey}`;
    const wallet = new ethers.Wallet(formattedKey, provider);
    
    console.log('=== Wallet Information ===');
    console.log('Wallet Address:', wallet.address);
    
    // Get balance
    const balance = await provider.getBalance(wallet.address);
    const balanceInApe = ethers.utils.formatEther(balance);
    
    console.log('Balance:', balanceInApe, 'APE');
    
    // Check if balance is low
    if (balance.lt(ethers.utils.parseEther("0.01"))) {
      console.warn('⚠️ Warning: Low balance detected');
      console.log('\nTo fund your wallet with APE tokens for the APEChain Curtis Testnet:');
      console.log('1. Visit the APEChain Curtis Testnet Faucet');
      console.log('2. Enter your wallet address:', wallet.address);
      console.log('3. Submit the request to receive test APE tokens');
      console.log('\nAlternatively, you can also:');
      console.log(`- Check your address on the explorer: ${explorerUrl}/address/${wallet.address}`);
    } else {
      console.log('✅ Wallet has sufficient balance for transactions');
    }
    
  } catch (error) {
    console.error('Error checking wallet balance:', error);
  }
}

// Run the script
checkWalletBalance()
  .then(() => process.exit(0))
  .catch(error => {
    console.error('Script failed:', error);
    process.exit(1);
  });
