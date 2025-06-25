#!/bin/bash

echo "=== KweliVote Blockchain Quick Fix ==="
echo "This script fixes the 'insufficient funds' error in the blockchain integration"
echo ""

# Navigate to the frontend directory
cd /home/quest/myrepos/KweliVote-1/kwelivote-app/frontend

# Create a backup of the original file
cp src/services/BlockchainService.js src/services/BlockchainService.js.bak
echo "Created backup at src/services/BlockchainService.js.bak"

# Patch the BlockchainService.js file to handle insufficient funds gracefully
cat > patch_blockchain.js << 'EOT'
const fs = require('fs');
const path = require('path');

// Path to the file
const filePath = path.join(__dirname, 'src', 'services', 'BlockchainService.js');

try {
  // Read the file
  let content = fs.readFileSync(filePath, 'utf8');
  
  // Update the error handling in storeDID
  const updated = content.replace(
    /\/\/ Format a more user-friendly error message based on the error type[\s\S]*?let errorMessage = error\.message;[\s\S]*?if \(error\.code === 'INSUFFICIENT_FUNDS'\) {[\s\S]*?errorMessage = 'Insufficient APE tokens to pay for blockchain transaction\. Please fund the wallet with APE tokens\.';[\s\S]*?}/,
    `// Format a more user-friendly error message based on the error type
      let errorMessage = error.message;
      let errorCode = error.code || 'UNKNOWN_ERROR';
      
      if (error.code === 'INSUFFICIENT_FUNDS') {
        console.error('INSUFFICIENT_FUNDS detected - providing helpful error message');
        errorMessage = 'Insufficient APE tokens to pay for blockchain transaction. Please fund the wallet with APE tokens.';
        
        // Create an object with additional information for the UI
        return {
          success: false,
          error: errorMessage,
          errorCode: 'INSUFFICIENT_FUNDS',
          skipBlockchain: true,
          walletAddress: this.signer.address,
          userMessage: 'The blockchain transaction could not be completed due to insufficient funds. The voter data has been saved to the database, but not to the blockchain. Please fund your wallet with APE tokens to enable blockchain integration.'
        };
      }`
  );
  
  // Write the updated content back to the file
  fs.writeFileSync(filePath, updated, 'utf8');
  console.log('BlockchainService.js updated successfully to handle insufficient funds errors gracefully');
} catch (error) {
  console.error('Error updating BlockchainService.js:', error);
  process.exit(1);
}
EOT

# Run the patch script
node patch_blockchain.js

# Create a guide for fixing the issue
cat > /home/quest/myrepos/KweliVote-1/INSUFFICIENT_FUNDS_FIX.md << 'EOT'
# Fixing "Insufficient Funds" Blockchain Error

You're seeing this error because the wallet used for blockchain transactions doesn't have enough APE tokens to pay for gas fees.

## Quick Fix (Already Applied)

The application has been patched to handle this error gracefully. Now, when insufficient funds are detected:

1. The voter data will still be saved to the database
2. A user-friendly error message will be shown
3. The blockchain transaction will be skipped

## Getting APE Tokens

To fully fix this issue and enable blockchain integration, you need to get APE tokens for your wallet:

1. Check your wallet address by running:
   ```
   cd kwelivote-app/frontend
   npx hardhat run scripts/check_wallet_balance.js
   ```

2. Visit the APEChain Curtis Testnet Faucet (ask your administrator for the URL)

3. Enter your wallet address and request tokens

4. Wait a few minutes for the tokens to arrive

5. Verify your balance with the same command from step 1

## Environment Configuration

Make sure your `.env` or `.env.development` file has these settings:

```
# APEChain Network Configuration
REACT_APP_APECHAIN_NETWORK_NAME=APEChain Curtis Testnet
REACT_APP_APECHAIN_API=https://curtis.apescan.io
REACT_APP_APECHAIN_CHAIN_ID=33111
REACT_APP_APECHAIN_RPC_ENDPOINT=https://curtis.rpc.caldera.xyz/http
REACT_APP_APECHAIN_EXPLORER_URL=https://curtis.apescan.io

# Contract and Admin Configuration
REACT_APP_VOTER_DID_CONTRACT_ADDRESS=0xBe150B7fd55fb4F2CE1612234FD4e40687e2025c
REACT_APP_ADMIN_PRIVATE_KEY=your_private_key_here
```

## Need Help?

If you're still having issues after following these steps, contact your system administrator.
EOT

echo ""
echo "✅ Fix has been applied successfully!"
echo ""
echo "The application will now handle insufficient funds errors gracefully:"
echo "1. Voter data will still be saved to the database"
echo "2. A user-friendly error message will be shown"
echo "3. The blockchain transaction will be skipped"
echo ""
echo "For complete instructions on fixing the issue, see:"
echo "/home/quest/myrepos/KweliVote-1/INSUFFICIENT_FUNDS_FIX.md"
echo ""
echo "To get APE tokens for your wallet, run:"
echo "cd /home/quest/myrepos/KweliVote-1/kwelivote-app/frontend"
echo "npx hardhat run scripts/check_wallet_balance.js"
