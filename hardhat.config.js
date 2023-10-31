require("@nomicfoundation/hardhat-toolbox");

// Go to https://infura.io, sign up, create a new API key
// in its dashboard, and replace "KEY" with it
const INFURA_API_KEY = "b6271a54103e430fbc6d2ec56ff98755";

// Replace this private key with your Sepolia account private key
// To export your private key from Coinbase Wallet, go to
// Settings > Developer Settings > Show private key
// To export your private key from Metamask, open Metamask and
// go to Account Details > Export Private Key
// Beware: NEVER put real Ether into testing accounts
const SEPOLIA_PRIVATE_KEY2 = "";
const SEPOLIA_PRIVATE_KEY = "";

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.19",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          },
          viaIR: true
        }
      },
      {
        version: "0.6.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          },
        }
      },
      {
        version: "0.4.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          },
        }
      },
      {
        version: "0.8.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          },
        }
      }
    ]
  },
  defaultNetwork: "goerli",
  networks: {
    goerli: {
      url: `https://goerli.infura.io/v3/${INFURA_API_KEY}`,
      chainId: 5,
      accounts: [SEPOLIA_PRIVATE_KEY],
    },
    bsc: {
      url: "https://binance.llamarpc.com",
      chainId: 56, 
      accounts: [SEPOLIA_PRIVATE_KEY],
    },
    arbitrum: {
      url: "https://arbitrum.llamarpc.com",
      chainId: 42161, 
      accounts: [SEPOLIA_PRIVATE_KEY],
    },
    optimism: {
      url: "https://optimism.llamarpc.com",
      chainId: 10, 
      accounts: [SEPOLIA_PRIVATE_KEY],
    },
    polygon: {
      url: "https://polygon.llamarpc.com",
      chainId: 137, 
      accounts: [SEPOLIA_PRIVATE_KEY],
    },
    sepolia: {
      url: "https://sepolia.publicgoods.network",
      chainId: 58008, 
      accounts: [SEPOLIA_PRIVATE_KEY],
    },
    celo: {
      url: "https://1rpc.io/celo",
      chainId: 42220, 
      accounts: [SEPOLIA_PRIVATE_KEY],
    },
    goerli: {
      url: `https://goerli.infura.io/v3/${INFURA_API_KEY}`,
      chainId: 5,
      accounts: [SEPOLIA_PRIVATE_KEY],
      // gasPrice: 20000,
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${INFURA_API_KEY}`,
      chainId: 1,
      accounts: [SEPOLIA_PRIVATE_KEY],
    },
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: "EN61ZAFUFED9F6NPYJJXP75M6SPJN8DC74"
  }
  
};
