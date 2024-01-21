require("@nomicfoundation/hardhat-toolbox");

// Go to https://infura.io, sign up, create a new API key
// in its dashboard, and replace "KEY" with it
// const INFURA_API_KEY = "b6271a54103e430fbc6d2ec56ff98755";

const INFURA_API_KEY = "9c7e70b4bf234955945ff87b8149926e";

// Replace this private key with your Sepolia account private key
// To export your private key from Coinbase Wallet, go to
// Settings > Developer Settings > Show private key
// To export your private key from Metamask, open Metamask and
// go to Account Details > Export Private Key
// Beware: NEVER put real Ether into testing accounts

// 0x62f77aDEc6273aB0d44Ebb08ea53464abec70A69
const SEPOLIA_PRIVATE_KEY = "";

// 0x80520E99aDD46c642052Ca5B476a1Dd40dB973B0
const SEPOLIA_PRIVATE_KEY1 = "";

// 0x72DDbDc341BBFc00Fe4F3f49695532841965bF0E
const SEPOLIA_PRIVATE_KEY2 = ""

const HARDHAT_PRIVATE_KEY = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
const HARDHAT_PRIVATE_KEY2 = "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d";

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 2000
          },
          viaIR: true
        }
      },
      {
        version: "0.8.19",
        settings: {
          optimizer: {
            enabled: true,
            runs: 2000
          },
          viaIR: true
        }
      },
      {
        version: "0.6.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 2000
          },
        }
      },
      {
        version: "0.4.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 2000
          },
        }
      },
      {
        version: "0.8.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 2000
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
      accounts: [SEPOLIA_PRIVATE_KEY, SEPOLIA_PRIVATE_KEY1, SEPOLIA_PRIVATE_KEY2],
      // gasPrice: 20000,
    },
    hardhat: {
      forking: {
        url: `https://goerli.infura.io/v3/${INFURA_API_KEY}`,
        accounts: [HARDHAT_PRIVATE_KEY, HARDHAT_PRIVATE_KEY2, SEPOLIA_PRIVATE_KEY, SEPOLIA_PRIVATE_KEY2],
      }
    }
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: "EN61ZAFUFED9F6NPYJJXP75M6SPJN8DC74"
  }
  
};