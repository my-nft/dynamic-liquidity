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
// const SEPOLIA_PRIVATE_KEY = "e49be725e2a3a4326689d859144df26ea3dd06c758d5adcf854c61aa5ee0e631";
const SEPOLIA_PRIVATE_KEY = "85fc564b8127eb40f2ea39bd3e3c3f6cfd8c5f89e18cad8e5101ced015504c70"

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
      }
    ]
  },
  // solidity: {
  //   compilers: [
  //     {
  //       version: "0.8.19",
  //       viaIR: true,
  //       // settings: {
  //       //   viaIR: true,
  //       // },
  //       optimizer: {
  //         enabled: true,
  //         runs: 2000,
  //       },
  //     },
  //     {
  //       version: "0.6.6",
  //       // settings: {
  //       //   viaIR: true,
  //       // },
  //     },
  //   ],
  // },
  networks: {
    goerli: {
      url: `https://goerli.infura.io/v3/${INFURA_API_KEY}`,
      chainId: 5,
      accounts: [SEPOLIA_PRIVATE_KEY],
      // gasPrice: 20000,
    }
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: "EN61ZAFUFED9F6NPYJJXP75M6SPJN8DC74"
  }
  
};