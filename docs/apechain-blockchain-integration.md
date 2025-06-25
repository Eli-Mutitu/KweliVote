# KweliVote APEChain Blockchain Integration

## Overview

This document outlines the integration of KweliVote's voter registration system with the APEChain blockchain platform, specifically the Curtis Testnet. This integration enables secure, immutable storage of voter Decentralized Identifiers (DIDs) on a blockchain, enhancing transparency and trust in the electoral process.

## Architecture

The KweliVote blockchain integration follows a layered architecture:

1. **Frontend Layer**: React components for user interaction
2. **Service Layer**: Blockchain service for APEChain interactions
3. **Smart Contract Layer**: Solidity contracts deployed on APEChain Curtis Testnet
4. **Blockchain Layer**: APEChain Curtis Testnet

## APEChain Curtis Testnet Configuration

The application connects to the APEChain Curtis Testnet with the following configuration:

- **Network Name**: APEChain Curtis Testnet
- **Chain ID**: 33111
- **RPC Endpoint**: https://curtis.rpc.caldera.xyz/http
- **Block Explorer URL**: https://curtis.apescan.io
- **API**: https://curtis.apescan.io

## Components

### 1. Smart Contracts

#### VoterDID Contract

The `VoterDID` smart contract serves as the on-chain registry for voter DIDs. It maps national IDs to their corresponding DIDs and provides verification mechanisms.

Key functions:
- `registerVoter(string did, string nationalId)`: Registers or updates a voter's DID
- `getVoterDID(string nationalId)`: Retrieves a voter's DID
- `verifyDID(string nationalId, string did)`: Verifies if a DID matches what's recorded for a voter

#### BallotValidation Contract

The `BallotValidation` contract provides a mechanism for multiple election officials to validate ballot counts, enhancing the transparency and integrity of the vote counting process.

Key functions:
- `submitResult(string resultId, string candidateId, string pollingStation, uint256 votes)`: Submit a new election result
- `validateResultPO(string resultId)`: Validation by Presiding Officer
- `validateResultDPO(string resultId)`: Validation by Deputy Presiding Officer
- `validateResultPartyAgent(string resultId)`: Validation by Party Agent
- `finalizeResult(string resultId)`: Finalize a result after sufficient validations

### 2. Blockchain Service (BlockchainService.js)

This service provides a high-level API for interacting with the APEChain blockchain, abstracting away the complexities of direct blockchain operations.

Key functions:
- `initialize()`: Set up connections to the APEChain network
- `importPrivateKey(privateKey)`: Import an admin private key for signing transactions
- `deployVoterDIDContract()`: Deploy the VoterDID smart contract
- `registerVoterDID(voterDID, nationalId)`: Record a voter's DID on the blockchain
- `verifyVoterDID(nationalId, did)`: Verify if a given DID matches what's stored for a national ID
- `getAccountBalance(address)`: Check the balance of an APEChain account

### 3. React Components

- **BlockchainAccountSetup**: Interface for configuring APEChain account settings
- **BlockchainSetup**: Admin interface for deploying and managing smart contracts
- **BlockchainExplorer**: Interface for verifying voter DIDs on the blockchain
- **VoterRegister** (Enhanced): Integrated with blockchain functionality to store DIDs when registering voters

## Integration Steps

### 1. Environment Configuration

1. Create or update your `.env` file with APEChain configuration:
   ```
   # APEChain Network Configuration
   REACT_APP_APECHAIN_NETWORK_NAME=APEChain Curtis Testnet
   REACT_APP_APECHAIN_API=https://curtis.apescan.io
   REACT_APP_APECHAIN_CHAIN_ID=33111
   REACT_APP_APECHAIN_RPC_ENDPOINT=https://curtis.rpc.caldera.xyz/http
   REACT_APP_APECHAIN_EXPLORER_URL=https://curtis.apescan.io
   
   # Smart Contract Configuration
   REACT_APP_VOTER_DID_CONTRACT_ADDRESS=your_deployed_contract_address
   REACT_APP_BALLOTVALIDATION_CONTRACT_ADDRESS=your_deployed_contract_address
   
   # Admin Configuration
   REACT_APP_ADMIN_PRIVATE_KEY=your_private_key_without_0x_prefix
   ```

### 2. Update Blockchain Service

2. Modify `BlockchainService.js` to use APEChain configuration:
   ```javascript
   constructor() {
     // APEChain Curtis Testnet Configuration from environment variables
     this.network = {
       name: process.env.REACT_APP_APECHAIN_NETWORK_NAME || 'APEChain Curtis Testnet',
       chainId: parseInt(process.env.REACT_APP_APECHAIN_CHAIN_ID || '33111'),
       rpcUrl: process.env.REACT_APP_APECHAIN_RPC_ENDPOINT || 'https://curtis.rpc.caldera.xyz/http',
       explorer: process.env.REACT_APP_APECHAIN_EXPLORER_URL || 'https://curtis.apescan.io',
     };
     
     // ...rest of constructor
   }
   ```

### 3. Smart Contract Deployment

1. Compile the VoterDID and BallotValidation contracts
2. Deploy contracts to APEChain Curtis Testnet
3. Update the `.env` file with the deployed contract addresses

### 4. Blockchain Account Setup

1. Navigate to the BlockchainAccountSetup component
2. Enter the APEChain private key with sufficient native token balance
3. The system will validate the key and show the account balance
4. Confirm account setup to enable blockchain operations

### 5. Voter Registration Integration

1. Update the `VoterRegister` component to include blockchain integration:
   - After generating a DID from biometric data
   - Register the DID on the APEChain blockchain using `BlockchainService.registerVoterDID`
   - Store the transaction hash in the database with the voter record

### 6. DID Verification

1. Navigate to the BlockchainExplorer component
2. Enter a national ID to verify
3. The system will query the VoterDID contract on APEChain
4. Display the verification result showing whether the DID exists and matches

## Flow of Operations

### Blockchain Setup (Administrator)

1. Admin navigates to the BlockchainAccountSetup component
2. Provides APEChain private key with sufficient token balance
3. System connects to APEChain Curtis Testnet
4. Admin deploys or connects to existing VoterDID smart contract
5. Configuration is saved securely for future use

### Voter Registration with Blockchain Integration

1. Registration officer collects voter information and biometric data
2. System converts biometric data into a DID using the biometricToDID utility
3. System stores the DID in the local database
4. System also stores the DID on the APEChain blockchain
5. The blockchain transaction hash is saved with the voter record
6. Registration is complete with both local and blockchain records

### Verification Process

1. User enters a national ID in the Blockchain Explorer
2. System queries the APEChain blockchain for the DID associated with the ID
3. If found, the system displays the DID and confirmation
4. If not found, the system indicates that no blockchain record exists

## Database Schema Updates

The Voter model includes blockchain-related fields:

```python
class Voter(models.Model):
    # ...existing fields...
    
    # Blockchain fields
    blockchain_tx_id = models.CharField(max_length=255, blank=True, null=True)
    blockchain_subnet_id = models.CharField(max_length=255, blank=True, null=True)
    
    # ...other existing fields...
```

## Security Considerations

1. **Private Key Management**: Private keys are never stored in the database. Admin keys are temporarily stored in localStorage during development but should use a secure key management system in production.

2. **Biometric Privacy**: Biometric data never leaves the client. Only the derived DID (which cannot be reversed to obtain biometrics) is stored on the blockchain.

3. **Blockchain Identity**: The system uses W3C DID:key format, ensuring interoperability with other DID systems.

4. **Smart Contract Access Control**: Only authorized admins can register DIDs on the blockchain using the contract's access control mechanisms.

## Production Deployment Notes

For production deployment, the following enhancements should be made:

1. **Key Management**: Use a secure HSM or key management service for private keys
2. **Transaction Monitoring**: Implement a monitoring system for blockchain transactions
3. **Gas Management**: Implement a system to manage native tokens for gas fees
4. **Disaster Recovery**: Implement backup and recovery procedures for blockchain data
5. **Contract Auditing**: Have the smart contracts audited by a security firm before production deployment

## APEChain-specific Considerations

1. **Gas Fees**: Ensure your account has sufficient APEChain native tokens for transaction fees
2. **Network Performance**: Monitor network performance and adjust gas prices accordingly
3. **Block Finality**: Consider APEChain's block finality time when implementing real-time features
4. **Explorer Integration**: Use the APEChain explorer URL for providing transaction verification links

## Conclusion

The integration of APEChain blockchain technology with the KweliVote system provides a robust, transparent solution for storing voter identities. The APEChain Curtis Testnet offers a reliable environment for testing and development, with a path to production deployment on the APEChain mainnet.

---

*Last updated: June 25, 2025*