#!/bin/bash

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

echo "=== KweliVote Blockchain Troubleshooter ==="
echo "This script will help you fix your blockchain integration issues."
echo ""

cd kwelivote-app/frontend

# Check for the blockchain error message
echo "1. Checking for insufficient funds error..."

# Create a script to update the blockchain service to fix insufficient funds error
cat > update_blockchain_service.js << 'EOF'
const fs = require('fs');
const path = require('path');

// Path to the BlockchainService.js file
const filePath = path.join(__dirname, 'src', 'services', 'BlockchainService.js');

try {
  let content = fs.readFileSync(filePath, 'utf8');
  
  // Check if we need to add the skipBlockchain flag
  if (!content.includes('skipBlockchainOnInsufficientFunds')) {
    console.log('Updating BlockchainService.js to handle insufficient funds gracefully...');
    
    // Add the skipBlockchain function
    const storeDIDMethodRegex = /async storeDID\(nationalId, did\) {/;
    if (storeDIDMethodRegex.test(content)) {
      // Add a function to check if the transaction should be skipped
      content = content.replace(
        'class BlockchainService {',
        `class BlockchainService {
  // Helper function to determine if blockchain transactions should be skipped
  skipBlockchainOnInsufficientFunds() {
    // Get setting from localStorage or default to false
    const skipSetting = localStorage.getItem('skipBlockchainOnInsufficientFunds');
    return skipSetting === 'true';
  }
  
  // Helper to set the skip blockchain setting
  setSkipBlockchainOnInsufficientFunds(skip) {
    localStorage.setItem('skipBlockchainOnInsufficientFunds', skip ? 'true' : 'false');
    return skip;
  }`
      );
      
      // Add a check at the beginning of storeDID
      content = content.replace(
        /async storeDID\(nationalId, did\) {[\s\S]*?if \(!this\.isInitialized \|\| !this\.signer\) {/,
        `async storeDID(nationalId, did) {
    console.log(\`StoreDID called with nationalId: \${nationalId}, did: \${did}\`);
    
    // Check if blockchain transactions should be skipped due to insufficient funds
    if (this.skipBlockchainOnInsufficientFunds()) {
      console.log('Skipping blockchain transaction due to insufficient funds setting');
      return { 
        success: false, 
        error: 'Blockchain transactions are disabled due to insufficient funds',
        errorCode: 'BLOCKCHAIN_DISABLED',
        skipped: true
      };
    }
    
    if (!this.isInitialized || !this.signer) {`
      );
      
      fs.writeFileSync(filePath, content, 'utf8');
      console.log('✅ BlockchainService.js updated successfully');
    } else {
      console.log('⚠️ Could not find storeDID method in BlockchainService.js');
    }
  } else {
    console.log('✅ BlockchainService.js already has the skip functionality');
  }
} catch (error) {
  console.error('Error updating BlockchainService.js:', error);
}
EOF

# Create a temporary node file to update VoterRegister.js
cat > update_voter_register.js << 'EOF'
const fs = require('fs');
const path = require('path');

// Path to the VoterRegister.js file
const filePath = path.join(__dirname, 'src', 'components', 'voter', 'VoterRegister.js');

try {
  let content = fs.readFileSync(filePath, 'utf8');
  
  // Check if we need to add the skipBlockchain option
  if (!content.includes('Skip blockchain')) {
    console.log('Updating VoterRegister.js to handle insufficient funds gracefully...');
    
    // Look for the saveToBlockchain function
    const saveToBlockchainRegex = /\/\/ Function to handle saving voter DID to the blockchain\s+const saveToBlockchain = async \(nationalId, did\) => {/;
    if (saveToBlockchainRegex.test(content)) {
      // Add a check for the skip setting and update error handling
      content = content.replace(
        /const saveToBlockchain = async \(nationalId, did\) => {[\s\S]*?try {/,
        `const saveToBlockchain = async (nationalId, did, options = {}) => {
    try {
      // Check if blockchain should be skipped
      if (options.skipBlockchain) {
        console.log('Skipping blockchain storage due to configuration');
        return { 
          success: false, 
          error: 'Blockchain storage skipped', 
          skipped: true 
        };
      }

      // Check if there's a global setting to skip blockchain
      if (blockchainService.skipBlockchainOnInsufficientFunds && blockchainService.skipBlockchainOnInsufficientFunds()) {
        console.log('Skipping blockchain storage due to insufficient funds setting');
        return { 
          success: false, 
          error: 'Blockchain transactions are disabled due to insufficient funds',
          errorCode: 'BLOCKCHAIN_DISABLED',
          skipped: true
        };
      }`
      );
      
      // Update blockchain error handling to show user-friendly message
      content = content.replace(
        /setError\(err\.message \|\| 'An error occurred while saving the voter record'\);/,
        `let errorMessage = err.message || 'An error occurred while saving the voter record';
      
      // Check for blockchain-specific errors
      if (errorMessage.includes('insufficient funds') || 
          (err.error && err.error.includes('insufficient funds')) ||
          errorMessage.includes('INSUFFICIENT_FUNDS')) {
        
        // Show more user-friendly error
        errorMessage = 'Insufficient funds to execute blockchain transaction. Voter data was saved to the database, but not to the blockchain.';
        
        // Offer option to disable blockchain temporarily
        if (confirm('Blockchain transaction failed due to insufficient funds. Would you like to disable blockchain transactions temporarily and continue with database-only storage?')) {
          // Set global flag to skip blockchain
          blockchainService.setSkipBlockchainOnInsufficientFunds(true);
          errorMessage += ' Blockchain transactions have been disabled for this session.';
        }
      }
      
      setError(errorMessage);`
      );
      
      // Update error handling for blockchain storage
      content = content.replace(
        /console\.error\('Error during blockchain storage:', blockchainError\);/g,
        `console.error('Error during blockchain storage:', blockchainError);
          
          // Handle insufficient funds errors specially
          if (blockchainError.message && blockchainError.message.includes('insufficient funds') ||
              (blockchainError.error && blockchainError.error.includes('insufficient funds')) || 
              blockchainError.code === 'INSUFFICIENT_FUNDS') {
            
            setError('Insufficient funds to execute blockchain transaction. Voter data was saved to the database, but not to the blockchain.');
            
            // Ask user if they want to disable blockchain
            if (window.confirm('Blockchain transaction failed due to insufficient funds. Would you like to disable blockchain transactions temporarily and continue with database-only storage?')) {
              // Set global flag to skip blockchain
              blockchainService.setSkipBlockchainOnInsufficientFunds(true);
            }
          }`
      );
      
      fs.writeFileSync(filePath, content, 'utf8');
      console.log('✅ VoterRegister.js updated successfully');
    } else {
      console.log('⚠️ Could not find saveToBlockchain function in VoterRegister.js');
    }
  } else {
    console.log('✅ VoterRegister.js already has the skip functionality');
  }
} catch (error) {
  console.error('Error updating VoterRegister.js:', error);
}
EOF

# Execute the update scripts
echo "2. Updating code to handle insufficient funds gracefully..."
node update_blockchain_service.js
node update_voter_register.js

# Clean up
rm update_blockchain_service.js update_voter_register.js

echo ""
echo "3. Adding APEChain faucet information..."

# Create a simple README file with instructions
cat > APECHAIN_FAUCET_INSTRUCTIONS.md << 'EOF'
# APEChain Faucet Instructions

If you're encountering "insufficient funds" errors when trying to save voter DIDs to the blockchain, you need to fund your wallet with APE tokens.

## Current Wallet Address

The wallet address used for blockchain transactions is derived from the private key in your `.env` or `.env.development` file.

Check your wallet address by running:
```
cd kwelivote-app/frontend
npx hardhat run scripts/check_wallet_balance.js
```

## Getting Testnet APE Tokens

To get free testnet APE tokens:

1. Visit the APEChain Curtis Testnet Faucet (ask your administrator for the URL)
2. Enter your wallet address 
3. Submit the request
4. Wait for the tokens to arrive (usually takes a few minutes)

## Alternatives

If you can't access the faucet:

1. Temporarily disable blockchain integration by checking the "Skip blockchain due to insufficient funds" checkbox in the admin settings.
2. This will allow registration to continue, saving data to the database only.
3. Once the wallet is funded, you can re-enable blockchain integration.

## Checking Your Balance

You can check your wallet balance anytime with:
```
cd kwelivote-app/frontend
npx hardhat run scripts/check_wallet_balance.js
```

Or view it on the APEChain explorer: https://curtis.apescan.io/address/YOUR_WALLET_ADDRESS
EOF

echo "Created APECHAIN_FAUCET_INSTRUCTIONS.md with instructions on how to get testnet tokens"

echo ""
echo "4. Creating a temporary fix solution..."

# Create a temporary HTML page with a fix
cat > wallet_fixer.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>KweliVote Blockchain Fixer</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      max-width: 800px;
      margin: 0 auto;
      padding: 20px;
      line-height: 1.6;
    }
    h1 { color: #2563eb; }
    h2 { color: #1e40af; margin-top: 30px; }
    .card {
      border: 1px solid #e5e7eb;
      border-radius: 8px;
      padding: 20px;
      margin-bottom: 20px;
      box-shadow: 0 1px 3px rgba(0,0,0,0.1);
    }
    .warning {
      background-color: #fff7ed;
      border-left: 4px solid #f97316;
      padding: 10px 15px;
    }
    .success {
      background-color: #ecfdf5;
      border-left: 4px solid #10b981;
      padding: 10px 15px;
    }
    button {
      background-color: #2563eb;
      color: white;
      border: none;
      padding: 10px 15px;
      border-radius: 6px;
      cursor: pointer;
      font-weight: 500;
    }
    button:hover {
      background-color: #1d4ed8;
    }
    code {
      background-color: #f1f5f9;
      padding: 2px 5px;
      border-radius: 4px;
      font-family: Menlo, Monaco, Consolas, "Liberation Mono", monospace;
    }
    .toggle {
      margin-top: 10px;
    }
    #status {
      margin-top: 20px;
    }
  </style>
</head>
<body>
  <h1>KweliVote Blockchain Fixer</h1>
  <p>This tool helps you fix blockchain integration issues, particularly the "insufficient funds" error.</p>
  
  <div class="card">
    <h2>Current Blockchain Status</h2>
    <div id="status">Checking status...</div>
  </div>
  
  <div class="card">
    <h2>Temporary Fix</h2>
    <p>If you're getting insufficient funds errors, you can temporarily disable blockchain integration:</p>
    
    <div class="toggle">
      <input type="checkbox" id="skipBlockchain"> 
      <label for="skipBlockchain">Skip blockchain due to insufficient funds</label>
    </div>
    
    <p>When this option is enabled:</p>
    <ul>
      <li>Voter registration will continue to work</li>
      <li>Voter data will be saved to the database</li>
      <li>Blockchain integration will be skipped</li>
      <li>You can re-enable it once you've funded your wallet</li>
    </ul>
    
    <button id="saveSettings">Save Settings</button>
  </div>
  
  <div class="card">
    <h2>Permanent Fix</h2>
    <p>To fix this issue permanently, you need to fund your wallet with APE tokens:</p>
    
    <ol>
      <li>Get your wallet address (shown above)</li>
      <li>Visit the APEChain Curtis Testnet Faucet</li>
      <li>Request free testnet tokens</li>
      <li>Wait for tokens to arrive (typically a few minutes)</li>
      <li>Return to KweliVote and re-enable blockchain integration</li>
    </ol>
    
    <div class="warning">
      <strong>Note:</strong> These are testnet tokens with no real value, used only for testing.
    </div>
  </div>

  <script>
    // Function to check localStorage
    function checkStatus() {
      const skipBlockchain = localStorage.getItem('skipBlockchainOnInsufficientFunds') === 'true';
      document.getElementById('skipBlockchain').checked = skipBlockchain;
      
      const statusDiv = document.getElementById('status');
      if (skipBlockchain) {
        statusDiv.innerHTML = `
          <div class="warning">
            <strong>Blockchain Integration: DISABLED</strong><br>
            Blockchain storage is currently disabled due to insufficient funds.
            Voter registration will work, but DIDs will not be stored on the blockchain.
          </div>
        `;
      } else {
        statusDiv.innerHTML = `
          <div class="success">
            <strong>Blockchain Integration: ENABLED</strong><br>
            Voter DIDs will be stored on the blockchain if funds are available.
          </div>
        `;
      }
    }
    
    // Save settings
    document.getElementById('saveSettings').addEventListener('click', function() {
      const skipBlockchain = document.getElementById('skipBlockchain').checked;
      localStorage.setItem('skipBlockchainOnInsufficientFunds', skipBlockchain ? 'true' : 'false');
      
      alert(skipBlockchain 
        ? 'Blockchain integration has been disabled. Voters will be registered in the database only.' 
        : 'Blockchain integration has been enabled. Make sure your wallet has sufficient funds.');
      
      checkStatus();
    });
    
    // Initialize
    checkStatus();
  </script>
</body>
</html>
EOF

echo "Created wallet_fixer.html - a simple tool to enable/disable blockchain integration"
echo "Open this file in a browser to use the tool"

# Create a bash script to fix insufficient funds
cat > fix_insufficient_funds.sh << 'EOF'
#!/bin/bash

echo "=== KweliVote Blockchain Fix ==="
echo "This script will help you fix insufficient funds errors"
echo ""

# Function to check if node is installed
check_node() {
  if ! command -v node &> /dev/null; then
    echo "Node.js is not installed. Please install Node.js and try again."
    exit 1
  fi
}

# Function to check wallet balance
check_balance() {
  echo "Checking wallet balance..."
  cd kwelivote-app/frontend
  npx hardhat run scripts/check_wallet_balance.js --no-compile
  cd ../..
}

# Function to temporarily disable blockchain
disable_blockchain() {
  echo "Temporarily disabling blockchain integration..."
  
  # Create a simple script to set localStorage
  cat > disable_blockchain.js << 'EOT'
  const fs = require('fs');
  
  // Create a script that sets localStorage
  const script = `
  <script>
    // Disable blockchain integration
    localStorage.setItem('skipBlockchainOnInsufficientFunds', 'true');
    console.log('Blockchain integration disabled due to insufficient funds');
    document.write('<h3>Blockchain integration has been disabled</h3>');
    document.write('<p>You can now continue using the application without blockchain integration.</p>');
    document.write('<p>Voter data will be saved to the database only.</p>');
    document.write('<p>Close this window and return to the application.</p>');
  </script>
  `;
  
  // Write to a file
  fs.writeFileSync('disable_blockchain.html', script);
  console.log('Created disable_blockchain.html');
  EOT
  
  node disable_blockchain.js
  
  echo ""
  echo "Created disable_blockchain.html"
  echo "Open this file in a browser to disable blockchain integration"
  echo ""
}

# Function to modify environment variable
fund_wallet() {
  echo "Opening instructions for funding your wallet..."
  # Open the instructions
  if [ -f "APECHAIN_FAUCET_INSTRUCTIONS.md" ]; then
    cat APECHAIN_FAUCET_INSTRUCTIONS.md
  else
    echo "Could not find instructions file."
  fi
}

# Main menu
show_menu() {
  echo "Choose an option:"
  echo "1) Check wallet balance"
  echo "2) Temporarily disable blockchain integration"
  echo "3) Get instructions for funding your wallet"
  echo "4) Exit"
  read -p "Enter your choice (1-4): " choice
  
  case $choice in
    1) check_balance; show_menu ;;
    2) disable_blockchain; show_menu ;;
    3) fund_wallet; show_menu ;;
    4) exit 0 ;;
    *) echo "Invalid choice"; show_menu ;;
  esac
}

# Start by checking node
check_node

# Show the menu
show_menu
EOF

chmod +x fix_insufficient_funds.sh

echo ""
echo "Created fix_insufficient_funds.sh - run this script for an interactive fix"
echo ""
echo "=== Fix Complete ==="
echo "You now have several options to fix the insufficient funds error:"
echo "1. Run ./fix_insufficient_funds.sh for an interactive fix"
echo "2. Open wallet_fixer.html in a browser to enable/disable blockchain integration"
echo "3. Follow the instructions in APECHAIN_FAUCET_INSTRUCTIONS.md to fund your wallet"
echo ""
echo "To run the interactive fix tool:"
echo "  ./fix_insufficient_funds.sh"
