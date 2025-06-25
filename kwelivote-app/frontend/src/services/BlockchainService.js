import { ethers } from 'ethers';
// Import compiled artifacts for VoterDID contract
import VoterDIDArtifact from '../artifacts/contracts/VoterDID.sol/VoterDID.json';

/**
 * BlockchainService - Simple service for interacting with APEChain Curtis Testnet
 * 
 * This service provides basic functionality for:
 * 1. Connecting to the APEChain Curtis Testnet
 * 2. Managing private keys
 * 3. Deploying and interacting with smart contracts
 * 4. Verifying voter DIDs on the blockchain
 */
class BlockchainService {
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
  }
  constructor() {
    // APEChain Curtis Testnet Configuration from environment variables
    this.network = {
      name: process.env.REACT_APP_APECHAIN_NETWORK_NAME || 'APEChain Curtis Testnet',
      chainId: parseInt(process.env.REACT_APP_APECHAIN_CHAIN_ID || '33111'),
      rpcUrl: process.env.REACT_APP_APECHAIN_RPC_ENDPOINT || 'https://curtis.rpc.caldera.xyz/http',
      explorer: process.env.REACT_APP_APECHAIN_EXPLORER_URL || 'https://curtis.apescan.io',
    };

    this.provider = null;
    this.signer = null;
    this.voterDIDContract = null;
    this.voterDIDContractAddress = process.env.REACT_APP_VOTER_DID_CONTRACT_ADDRESS || null;
    this.isInitialized = false;
  }

  /**
   * Initialize the blockchain service and connection to APEChain Curtis Testnet
   * @returns {boolean} Whether initialization was successful
   */
  async initialize() {
    try {
      console.log('Initializing BlockchainService with network:', this.network);
      
      // Create an ethers provider for APEChain Curtis Testnet
      this.provider = new ethers.providers.JsonRpcProvider(this.network.rpcUrl);
      console.log('Provider created with RPC URL:', this.network.rpcUrl);
      
      // Test the connection
      console.log('Testing network connection...');
      const networkInfo = await this.provider.getNetwork();
      console.log('Connected to network:', networkInfo);
      
      // Check if we're connected to the correct network
      if (networkInfo.chainId !== this.network.chainId) {
        console.error(`Connected to wrong network. Expected chainId: ${this.network.chainId}, got: ${networkInfo.chainId}`);
        return false;
      }
      
      // Check for existing local configuration
      const storedContractAddr = localStorage.getItem('voterDIDContractAddress');
      if (storedContractAddr) {
        console.log('Found stored contract address:', storedContractAddr);
        this.voterDIDContractAddress = storedContractAddr;
      } else {
        console.log('No stored contract address found. Using address from environment:', process.env.REACT_APP_VOTER_DID_CONTRACT_ADDRESS);
      }
      
      console.log('BlockchainService initialization completed successfully');
      this.isInitialized = true;
      return true;
    } catch (error) {
      console.error('Failed to initialize blockchain connection:', error);
      this.isInitialized = false;
      return false;
    }
  }

  /**
   * Import a private key for signing transactions
   * @param {string} privateKey - The private key as a hex string
   * @returns {Object} Information about the imported key
   */
  importPrivateKey(privateKey) {
    try {
      console.log('Importing private key...');
      
      // Validate the private key
      if (!privateKey || typeof privateKey !== 'string' || privateKey.trim() === '') {
        console.error('Private key validation failed: Empty or invalid key');
        return {
          success: false,
          error: 'Private key cannot be empty'
        };
      }

      // Make sure it starts with 0x if it doesn't already
      const formattedKey = privateKey.startsWith('0x') ? privateKey : `0x${privateKey}`;
      console.log('Private key formatted correctly');
      
      try {
        // Create wallet from private key
        const wallet = new ethers.Wallet(formattedKey, this.provider);
        this.signer = wallet;
        
        console.log('Wallet created successfully with address:', wallet.address);
        return {
          success: true,
          address: wallet.address
        };
      } catch (walletError) {
        console.error('Error creating wallet:', walletError);
        return {
          success: false,
          error: `Invalid private key: ${walletError.message}`
        };
      }
    } catch (error) {
      console.error('Failed to import private key:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Deploy a VoterDID smart contract
   * @returns {Object} Deployment result information
   */
  async deployVoterDIDContract() {
    if (!this.isInitialized || !this.signer) {
      return { 
        success: false,
        error: 'Blockchain not initialized or no private key provided' 
      };
    }

    try {
      // Load ABI and bytecode from the compiled artifact
      const { abi, bytecode } = VoterDIDArtifact;
      
      // Deploy the contract
      const factory = new ethers.ContractFactory(abi, bytecode, this.signer);
      const contract = await factory.deploy();
      
      // Wait for deployment to complete
      await contract.deployed();
      
      // Save the contract address
      this.voterDIDContractAddress = contract.address;
      localStorage.setItem('voterDIDContractAddress', this.voterDIDContractAddress);
      
      // Initialize contract instance
      this.voterDIDContract = new ethers.Contract(
        this.voterDIDContractAddress,
        abi,
        this.signer
      );
      
      return {
        success: true,
        contractAddress: this.voterDIDContractAddress,
        transactionHash: contract.deployTransaction.hash
      };
    } catch (error) {
      console.error('Failed to deploy contract:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Store a DID on the blockchain
   * @param {string} nationalId - The voter's national ID
   * @param {string} did - The DID to store
   * @returns {Object} Transaction result information
   */
  async storeDID(nationalId, did) {
    console.log(`StoreDID called with nationalId: ${nationalId}, did: ${did}`);
    
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
    
    if (!this.isInitialized || !this.signer) {
      console.error('StoreDID failed: Blockchain not initialized or no signer available');
      return { 
        success: false,
        error: 'Blockchain not initialized or no private key provided' 
      };
    }
    
    // Check wallet balance before attempting transaction
    try {
      const balance = await this.provider.getBalance(this.signer.address);
      console.log(`Wallet balance: ${ethers.utils.formatEther(balance)} APE`);
      
      // If balance is too low, return an error
      if (balance.lt(ethers.utils.parseEther("0.01"))) {
        console.error('StoreDID failed: Insufficient funds for transaction');
        return {
          success: false,
          error: 'Insufficient APE tokens to pay for transaction fees. Please fund the wallet with APE tokens.',
          errorCode: 'INSUFFICIENT_FUNDS',
          walletAddress: this.signer.address,
          balance: ethers.utils.formatEther(balance)
        };
      }
    } catch (balanceError) {
      console.error('Error checking wallet balance:', balanceError);
      // Continue with the transaction attempt even if balance check fails
    }

    if (!this.voterDIDContract) {
      console.log('No contract instance exists, attempting to create one');
      // If contract instance doesn't exist but we have an address, create one
      if (this.voterDIDContractAddress) {
        console.log(`Using existing contract address: ${this.voterDIDContractAddress}`);
        const { abi } = VoterDIDArtifact;
        this.voterDIDContract = new ethers.Contract(
          this.voterDIDContractAddress,
          abi,
          this.signer
        );
        console.log('Contract instance created successfully');
      } else {
        console.error('StoreDID failed: No contract address available');
        return { 
          success: false,
          error: 'VoterDID contract not deployed' 
        };
      }
    }

    try {
      console.log('About to call contract.registerDID method');
      console.log('Contract address:', this.voterDIDContractAddress);
      console.log('Signer address:', this.signer.address);
      
      // Estimate gas for the transaction
      const gasEstimate = await this.voterDIDContract.estimateGas.registerDID(nationalId, did);
      console.log('Estimated gas for transaction:', gasEstimate.toString());
      
      // Add some buffer to the gas limit to ensure transaction success
      const gasLimit = gasEstimate.mul(120).div(100); // 20% buffer
      
      // Call the contract to store the DID with explicit gas limit
      const tx = await this.voterDIDContract.registerDID(nationalId, did, {
        gasLimit
      });
      console.log('Transaction sent:', tx.hash);
      
      // Wait for transaction to be confirmed
      console.log('Waiting for transaction confirmation...');
      const receipt = await tx.wait();
      console.log('Transaction confirmed in block:', receipt.blockNumber);
      
      return {
        success: true,
        transactionHash: receipt.transactionHash,
        blockNumber: receipt.blockNumber
      };
    } catch (error) {
      console.error('Failed to store DID:', error);
      // Log detailed error information to help debugging
      if (error.code) {
        console.error('Error code:', error.code);
      }
      if (error.reason) {
        console.error('Error reason:', error.reason);
      }
      if (error.transaction) {
        console.error('Failed transaction:', error.transaction);
      }
      
      // Format a more user-friendly error message based on the error type
      let errorMessage = error.message;
      if (error.code === 'INSUFFICIENT_FUNDS') {
        errorMessage = 'Insufficient APE tokens to pay for blockchain transaction. Please fund the wallet with APE tokens.';
      } else if (error.code === 'UNPREDICTABLE_GAS_LIMIT') {
        errorMessage = 'Unable to estimate gas for transaction. The contract may be rejecting the operation.';
      } else if (error.code === 'TIMEOUT') {
        errorMessage = 'Transaction timed out. The network may be congested.';
      }
      
      return {
        success: false,
        error: errorMessage,
        errorCode: error.code || 'UNKNOWN_ERROR'
      };
    }
  }

  /**
   * Verify a voter's DID on the blockchain
   * @param {string} nationalId - The voter's national ID
   * @returns {Object} Verification result
   */
  async verifyVoterDID(nationalId) {
    if (!this.isInitialized) {
      return { 
        success: false,
        error: 'Blockchain not initialized' 
      };
    }

    if (!this.voterDIDContractAddress) {
      return { 
        success: false,
        error: 'VoterDID contract not deployed' 
      };
    }

    try {
      // Create a read-only contract instance
      const { abi } = VoterDIDArtifact;
      const contract = new ethers.Contract(
        this.voterDIDContractAddress,
        abi,
        this.provider
      );
      
      // Get the stored DID for the national ID
      const storedDID = await contract.getDID(nationalId);
      
      // Check if the DID exists
      const isVerified = storedDID && storedDID.length > 0;
      
      let transactionInfo = null;
      
      // If verified, make a thorough attempt to get transaction information
      if (isVerified) {
        try {
          // First approach: Look for DIDRegistered events related to this national ID
          const registerFilter = contract.filters.DIDRegistered(nationalId);
          const registerEvents = await contract.queryFilter(registerFilter);
          
          if (registerEvents.length > 0) {
            // Sort by block number (descending) to get the most recent
            registerEvents.sort((a, b) => b.blockNumber - a.blockNumber);
            
            // Get the most recent event
            const latestEvent = registerEvents[0];
            
            // Get transaction info and block details
            const tx = await this.provider.getTransaction(latestEvent.transactionHash);
            const receipt = await this.provider.getTransactionReceipt(latestEvent.transactionHash);
            const block = await this.provider.getBlock(latestEvent.blockNumber);
            
            transactionInfo = {
              hash: latestEvent.transactionHash,
              blockNumber: latestEvent.blockNumber,
              timestamp: block.timestamp ? new Date(block.timestamp * 1000).toISOString() : null,
              confirmations: tx.confirmations,
              from: receipt.from,
              eventName: 'DIDRegistered'
            };
          } else {
            // Second approach: If no specific events found, check contract transactions with this address
            console.log('No DIDRegistered events found, searching contract transactions');
            
            // Get the most recent block with transactions to this contract
            const blockHeight = await this.provider.getBlockNumber();
            const lookbackBlocks = 10000; // Look back through the last 10,000 blocks
            const startBlock = Math.max(0, blockHeight - lookbackBlocks);
            
            // Query for all contract events in this range
            const allEvents = await contract.queryFilter('*', startBlock, blockHeight);
            
            for (const event of allEvents) {
              try {
                // For each event, get the transaction
                const tx = await this.provider.getTransaction(event.transactionHash);
                if (tx && tx.to && tx.to.toLowerCase() === this.voterDIDContractAddress.toLowerCase()) {
                  const callData = tx.data;
                  
                  // Check if this transaction might be related to this national ID
                  // This is a simplification and might not work for all contract implementations
                  if (callData && callData.includes(nationalId.replace(/0x/g, ''))) {
                    const receipt = await this.provider.getTransactionReceipt(event.transactionHash);
                    const block = await this.provider.getBlock(event.blockNumber);
                    
                    transactionInfo = {
                      hash: event.transactionHash,
                      blockNumber: event.blockNumber,
                      timestamp: block.timestamp ? new Date(block.timestamp * 1000).toISOString() : null,
                      confirmations: tx.confirmations,
                      from: receipt.from,
                      eventName: 'ContractInteraction'
                    };
                    break; // Use the first matching transaction
                  }
                }
              } catch (innerError) {
                console.warn('Error processing transaction:', innerError);
                // Continue to the next transaction
              }
            }
          }
        } catch (eventError) {
          console.warn('Could not fetch transaction events:', eventError);
          // Continue without transaction info
        }
      }
      
      return {
        success: true,
        isVerified,
        nationalId,
        did: storedDID,
        transactionInfo,
        message: isVerified ? 'Voter identity verified on blockchain' : 'No identity found for this voter'
      };
    } catch (error) {
      console.error('Failed to verify voter DID:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Verify a voter's DID using their fingerprint
   * @param {string} nationalId - The voter's national ID
   * @param {object} fingerprintTemplate - The fingerprint template from a fresh scan
   * @returns {Object} Verification result
   */
  async verifyVoterDIDWithFingerprint(nationalId, fingerprintTemplate) {
    if (!this.isInitialized) {
      return { 
        success: false,
        error: 'Blockchain not initialized' 
      };
    }

    if (!this.voterDIDContractAddress) {
      return { 
        success: false,
        error: 'VoterDID contract not deployed' 
      };
    }

    try {
      // Import the verifyVoterDID function dynamically to avoid circular dependencies
      const { verifyVoterDID } = await import('../utils/biometricToDID');
      
      // Create a read-only contract instance
      const { abi } = VoterDIDArtifact;
      const contract = new ethers.Contract(
        this.voterDIDContractAddress,
        abi,
        this.provider
      );
      
      // Get the stored DID for the national ID
      const storedDID = await contract.getDID(nationalId);
      
      // Check if a DID exists on the blockchain
      if (!storedDID || storedDID.length === 0) {
        return {
          success: true,
          isVerified: false,
          nationalId,
          did: null,
          message: 'No identity found for this voter'
        };
      }

      // Verify the fingerprint against the stored DID
      const isMatch = verifyVoterDID(fingerprintTemplate, storedDID);
      
      return {
        success: true,
        isVerified: isMatch,
        nationalId,
        did: storedDID,
        message: isMatch 
          ? 'Voter identity verified with fingerprint match' 
          : 'Fingerprint does not match stored identity'
      };
    } catch (error) {
      console.error('Failed to verify voter DID with fingerprint:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Setup blockchain infrastructure
   * @param {Object} config - Configuration for blockchain setup
   * @returns {Object} Setup result information
   */
  async setupBlockchainInfrastructure(config) {
    if (!this.isInitialized || !this.signer) {
      return { 
        success: false,
        error: 'Blockchain not initialized or no private key provided' 
      };
    }
    
    try {
      // Deploy the VoterDID contract if not already deployed
      if (!this.voterDIDContractAddress) {
        const deployResult = await this.deployVoterDIDContract();
        if (!deployResult.success) {
          return deployResult;
        }
      }
      
      return {
        success: true,
        network: this.network.name,
        chainId: this.network.chainId,
        contractAddress: this.voterDIDContractAddress,
        message: 'Blockchain infrastructure setup complete'
      };
    } catch (error) {
      console.error('Failed to setup blockchain infrastructure:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Get blockchain network information
   * @returns {Object} Network information
   */
  getNetworkInfo() {
    return {
      name: this.network.name,
      chainId: this.network.chainId,
      rpcUrl: this.network.rpcUrl,
      explorer: this.network.explorer,
      isConnected: this.isInitialized
    };
  }

  /**
   * Get transaction URL in block explorer
   * @param {string} txHash - Transaction hash
   * @returns {string} URL to the transaction in block explorer
   */
  getTransactionUrl(txHash) {
    return `${this.network.explorer}/tx/${txHash}`;
  }

  /**
   * Get contract URL in block explorer
   * @param {string} address - Contract address
   * @returns {string} URL to the contract in block explorer
   */
  getContractUrl(address) {
    return `${this.network.explorer}/address/${address}`;
  }

  /**
   * Get account balance in APE
   * @param {string} address - Account address
   * @returns {string} Account balance in APE
   */
  async getAccountBalance(address) {
    if (!this.isInitialized) {
      throw new Error('Blockchain not initialized');
    }

    try {
      // Get balance in wei
      const balance = await this.provider.getBalance(address);
      
      // Convert from wei to APE (1 APE = 10^18 wei)
      const balanceInApe = ethers.utils.formatEther(balance);
      
      return balanceInApe;
    } catch (error) {
      console.error('Failed to get account balance:', error);
      throw error;
    }
  }
}

// Export singleton instance
const blockchainService = new BlockchainService();
export default blockchainService;