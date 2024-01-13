require("@nomicfoundation/hardhat-toolbox");

const INFURA_API_KEY = "b6271a54103e430fbc6d2ec56ff98755";

const SEPOLIA_PRIVATE_KEY2 = "a89f7441836ce5818eb957dcd43256211749ee0e7b775d57022de8728d5964f7";

const SEPOLIA_PRIVATE_KEY = "a89f7441836ce5818eb957dcd43256211749ee0e7b775d57022de8728d5964f7";

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
      accounts: [SEPOLIA_PRIVATE_KEY, SEPOLIA_PRIVATE_KEY2],
      // gasPrice: 20000,
    }
  },
  etherscan: {
    apiKey: "EN61ZAFUFED9F6NPYJJXP75M6SPJN8DC74"
  }
  
};