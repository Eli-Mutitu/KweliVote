// Hardhat configuration for KweliVote smart contracts (VoterDID.sol and BallotValidation.sol)
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("hardhat-deploy");

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
const PRIVATE_KEY = process.env.PRIVATE_KEY || "0x0000000000000000000000000000000000000000000000000000000000000000"; // Default dummy key
const APECHAIN_API_KEY = process.env.APECHAIN_API_KEY || ""; // API key for verification

module.exports = {
  // Configure Solidity versions for contracts:
  // - VoterDID.sol and BallotValidation.sol require at least 0.8.4
  solidity: {
    compilers: [
      {
        version: "0.8.4",
      },
      {
        version: "0.8.28",
      }
    ]
  },
  paths: {
    artifacts: './src/artifacts',
    cache: './cache',
    sources: './contracts',
    tests: './test',
  },
  networks: {
    hardhat: {
      chainId: 31337,
    },
    // Primary network for KweliVote contracts deployment
    apechain_curtis: {
      url: 'https://curtis.rpc.caldera.xyz/http',
      chainId: 33111,
      accounts: [PRIVATE_KEY],
      gasPrice: 225000000000,
      // This network is configured for deploying VoterDID and BallotValidation contracts
    },
    fuji: {
      url: 'https://api.avax-test.network/ext/bc/C/rpc',
      chainId: 43113,
      accounts: [PRIVATE_KEY],
      gasPrice: 225000000000,
    },
    mainnet: {
      url: 'https://api.avax.network/ext/bc/C/rpc',
      chainId: 43114,
      accounts: [PRIVATE_KEY],
      gasPrice: 225000000000,
    }
  },
  etherscan: {
    apiKey: {
      apechain_curtis: APECHAIN_API_KEY
    },
    customChains: [
      {
        network: "apechain_curtis",
        chainId: 33111,
        urls: {
          apiURL: "https://explorer.caldera.xyz/api",
          browserURL: "https://explorer.caldera.xyz"
        }
      }
    ]
  },
  namedAccounts: {
    deployer: {
      default: 0
    }
  },
  // Configuration for VoterDID and BallotValidation contract deployments
  deployments: {
    // Deploy directories specify where deployment artifacts are stored
    directory: './deployments',
    // Configured contract deployments
    deploymentTargets: {
      VoterDID: true,
      BallotValidation: true
    }
  }
};
