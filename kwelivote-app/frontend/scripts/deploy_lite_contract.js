const { ethers } = require('ethers');
require('dotenv').config();

async function main() {
  console.log('=== Deploying VoterDIDLite Contract (Ultra Low Gas) ===');
  
  const config = {
    rpcUrl: process.env.REACT_APP_APECHAIN_RPC_ENDPOINT || 'https://curtis.rpc.caldera.xyz/http',
    chainId: parseInt(process.env.REACT_APP_APECHAIN_CHAIN_ID || '33111'),
    privateKey: process.env.REACT_APP_ADMIN_PRIVATE_KEY
  };
  
  if (!config.privateKey) {
    console.error('Error: No admin private key provided');
    process.exit(1);
  }
  
  try {
    // Use artifacts from compilation
    const VoterDIDLiteArtifact = require('../artifacts/contracts/VoterDIDLite.sol/VoterDIDLite.json');
    
    const provider = new ethers.providers.JsonRpcProvider(config.rpcUrl);
    const formattedKey = config.privateKey.startsWith('0x') ? config.privateKey : `0x${config.privateKey}`;
    const wallet = new ethers.Wallet(formattedKey, provider);
    
    console.log(`Deploying from wallet address: ${wallet.address}`);
    
    const gasPrice = await provider.getGasPrice();
    const lowerGasPrice = gasPrice.mul(40).div(100); // 40% of current price
    
    console.log(`Using ultra-low gas price: ${ethers.utils.formatUnits(lowerGasPrice, 'gwei')} gwei`);
    
    const { abi, bytecode } = VoterDIDLiteArtifact;
    const factory = new ethers.ContractFactory(abi, bytecode, wallet);
    
    const deploymentOptions = {
      gasPrice: lowerGasPrice,
      gasLimit: 2000000 // Lower limit for optimized contract
    };
    
    const contract = await factory.deploy(deploymentOptions);
    console.log(`Transaction hash: ${contract.deployTransaction.hash}`);
    
    await contract.deployed();
    
    console.log('✅ Contract deployed successfully!');
    console.log(`Contract address: ${contract.address}`);
    
    return contract.address;
  } catch (error) {
    console.error('Error deploying contract:', error);
    process.exit(1);
  }
}

main()
  .then(contractAddress => {
    console.log(`\nDeployment successful. New lite contract: ${contractAddress}`);
    process.exit(0);
  })
  .catch(error => {
    console.error('Deployment failed:', error);
    process.exit(1);
  });
