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
const SEPOLIA_PRIVATE_KEY1 = "21cdb70be910e135dd8611b40b6de5f56ec9e5916b701ce07cfa1e8db7cd3dbd";

// 0x80520E99aDD46c642052Ca5B476a1Dd40dB973B0
const SEPOLIA_PRIVATE_KEY2 = "85fc564b8127eb40f2ea39bd3e3c3f6cfd8c5f89e18cad8e5101ced015504c70";

// 0x72DDbDc341BBFc00Fe4F3f49695532841965bF0E
const SEPOLIA_PRIVATE_KEY3 = "215f466b3e435d7ce15f03dae4d1ef774eb7598945c41d887c1e70d474fdc2b6"

const HARDHAT_PRIVATE_KEY = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
const HARDHAT_PRIVATE_KEY2 = "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d";

const SEPOLIA_PRIVATE_KEY4 = "a97e5aa3c5db50b5530ebe8001aac4ee6576e2349235156bb415c2fb61620be8";

const SEPOLIA_PRIVATE_KEY5 = "73480c840b45b6561c2de7a95d1efa4b87a96a3d51837a72f5b2237e44c4229d";

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
      accounts: [SEPOLIA_PRIVATE_KEY1, SEPOLIA_PRIVATE_KEY2, SEPOLIA_PRIVATE_KEY3],
      // gasPrice: 20000,
    },
    blastSepolia: {
      url: `https://blast-sepolia.blockpi.network/v1/rpc/public`,
      chainId: 168587773,
      accounts: [SEPOLIA_PRIVATE_KEY2, SEPOLIA_PRIVATE_KEY5, SEPOLIA_PRIVATE_KEY2, SEPOLIA_PRIVATE_KEY3],
      // gasPrice: 20000,
    },
    baseSepolia: {
      url: `https://sepolia.base.org`,
      // url: `https://rpc.notadegen.com/base/sepolia`,
      // url: `https://public.stackup.sh/api/v1/node/base-sepolia`,
      // url: `https://sepolia.infura.io/v3/${INFURA_API_KEY}`,
      chainId: 84532,
      accounts: [SEPOLIA_PRIVATE_KEY2, SEPOLIA_PRIVATE_KEY1, SEPOLIA_PRIVATE_KEY2, SEPOLIA_PRIVATE_KEY3],
      // gasPrice: 20000,
    },
    sepolia: {
      url: `https://sepolia.infura.io/v3/${INFURA_API_KEY}`,
      // url: `https://sepolia.drpc.org`,	
      // url: `https://1rpc.io/sepolia`,	
      chainId: 11155111,
      accounts: [SEPOLIA_PRIVATE_KEY2, SEPOLIA_PRIVATE_KEY1, SEPOLIA_PRIVATE_KEY2, SEPOLIA_PRIVATE_KEY3],
      // gasPrice: 20000,
    },
    hardhat: {
      forking: {
        url: `https://goerli.infura.io/v3/${INFURA_API_KEY}`,
        accounts: [HARDHAT_PRIVATE_KEY, HARDHAT_PRIVATE_KEY2, SEPOLIA_PRIVATE_KEY1, SEPOLIA_PRIVATE_KEY2],
      }
    }
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: "EN61ZAFUFED9F6NPYJJXP75M6SPJN8DC74"
  }
  
};