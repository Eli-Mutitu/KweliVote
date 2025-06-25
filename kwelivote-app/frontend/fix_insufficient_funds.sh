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
