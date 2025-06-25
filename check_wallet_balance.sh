#!/bin/bash

# Check APEChain wallet balance
# This script helps check the balance of the wallet used for blockchain transactions

echo "=== APEChain Wallet Balance Checker ==="
echo "Checking the balance of your APEChain wallet..."
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

# Navigate to the frontend directory
cd kwelivote-app/frontend

# Create a temporary script to check balance
cat > check_wallet_balance.js << 'EOF'
const { ethers } = require('ethers');
require('dotenv').config();

async function checkWalletBalance() {
  try {
    // Get configuration from environment variables
    const config = {
      rpcUrl: process.env.REACT_APP_APECHAIN_RPC_ENDPOINT || 'https://curtis.rpc.caldera.xyz/http',
      chainId: parseInt(process.env.REACT_APP_APECHAIN_CHAIN_ID || '33111'),
      networkName: process.env.REACT_APP_APECHAIN_NETWORK_NAME || 'APEChain Curtis Testnet',
      privateKey: process.env.REACT_APP_ADMIN_PRIVATE_KEY,
      explorerUrl: process.env.REACT_APP_APECHAIN_EXPLORER_URL || 'https://curtis.apescan.io'
    };
    
    console.log(`Network: ${config.networkName} (Chain ID: ${config.chainId})`);
    
    if (!config.privateKey) {
      console.error('Error: No admin private key provided in environment variables');
      console.error('Set REACT_APP_ADMIN_PRIVATE_KEY in .env file');
      return false;
    }
    
    // Create provider
    const provider = new ethers.providers.JsonRpcProvider(config.rpcUrl);
    
    // Create wallet
    const formattedKey = config.privateKey.startsWith('0x') ? config.privateKey : `0x${config.privateKey}`;
    const wallet = new ethers.Wallet(formattedKey, provider);
    
    console.log(`Wallet address: ${wallet.address}`);
    console.log(`Explorer URL: ${config.explorerUrl}/address/${wallet.address}`);
    
    // Get current gas price
    const gasPrice = await provider.getGasPrice();
    console.log(`Current gas price: ${ethers.utils.formatUnits(gasPrice, 'gwei')} gwei`);
    
    // Calculate estimated transaction cost
    const estimatedGasLimit = 100000; // Basic transaction
    const estimatedCost = gasPrice.mul(estimatedGasLimit);
    
    // Check wallet balance
    const balance = await provider.getBalance(wallet.address);
    const balanceInEth = ethers.utils.formatEther(balance);
    
    console.log(`\nWallet balance: ${balanceInEth} APE`);
    
    // Check if balance is sufficient for transactions
    if (balance.eq(0)) {
      console.log('\n❌ Status: NO FUNDS');
      console.log('Your wallet has zero balance. You cannot perform any blockchain transactions.');
      console.log('Please fund your wallet with APE tokens from a testnet faucet.');
      return false;
    } else if (balance.lt(estimatedCost)) {
      const requiredBalance = ethers.utils.formatEther(estimatedCost);
      console.log(`\n⚠️ Status: LOW FUNDS`);
      console.log(`Your wallet has insufficient balance for typical transactions.`);
      console.log(`Estimated minimum required: ${requiredBalance} APE`);
      console.log(`You need approximately ${(parseFloat(requiredBalance) - parseFloat(balanceInEth)).toFixed(6)} more APE.`);
      return false;
    } else {
      // Calculate how many transactions can be performed with current balance
      const txCount = Math.floor(balance.div(estimatedCost).toNumber());
      console.log(`\n✅ Status: FUNDED`);
      console.log(`Your wallet has sufficient balance for approximately ${txCount} transactions.`);
      return true;
    }
  } catch (error) {
    console.error('Error checking wallet balance:', error);
    return false;
  }
}

checkWalletBalance()
  .then(success => {
    console.log('\n-----------------------------------');
    if (success) {
      console.log('Your wallet is ready for blockchain transactions.');
    } else {
      console.log('Action required: Get testnet APE tokens for your wallet.');
    }
    process.exit(0);
  })
  .catch(error => {
    console.error('Script failed:', error);
    process.exit(1);
  });
EOF

# Run the script
node check_wallet_balance.js

# Clean up
rm check_wallet_balance.js
