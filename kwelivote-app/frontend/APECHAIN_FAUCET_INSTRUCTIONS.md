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
