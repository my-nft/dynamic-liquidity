const ethers = require('ethers');
const rpc_url = 'https://goerli.infura.io/v3/b7b06ad6a7304e2197efa10b79e1c867';
const token_json_path = 'artifacts/@openzeppelin/contracts/token/ERC20/IERC20.sol/IERC20.json';


const artifacts = {
  NonfungiblePositionManager: require("@uniswap/v3-periphery/artifacts/contracts/NonfungiblePositionManager.sol/NonfungiblePositionManager.json"),
  UniswapV3Factory: require('@uniswap/v3-core/artifacts/contracts/UniswapV3Factory.sol/UniswapV3Factory.json'), 
  UniswapV3Pool: require('@uniswap/v3-core/artifacts/contracts/UniswapV3Pool.sol/UniswapV3Pool.json'),
  WETH: require("../artifacts/contracts/WETH9.sol/WETH9.json"),
  UNI: require("../artifacts/contracts/yfsc.sol/Token.json"),
  YfSc: require("../artifacts/contracts/yfsc.sol/YfSc.json"),
  PositionsNFT: require("../artifacts/contracts/yfsc.sol/PositionsNFT.json"),
  SwapRouter: require("../artifacts/contracts/ISwapRouter.sol/ISwapRouter.json"),
};

const getAddresses = (network) => {
  switch (network) {
    case "hardhat":
      return {
        UNI: "",
        DAI: "0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063",
        WETH: "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619",
        POSITION_MANAGER_ADDRESS: "",
        ISWAP_ROUTER: "",
        UniswapV3Factory: "0x1F98431c8aD98523631AE4a59f267346ea31F984",
      };
    case "mainnet":
      return {
        UNI: "",
        DAI: "0x6B175474E89094C44Da98b954EedeAC495271d0F",
        WETH: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
        POSITION_MANAGER_ADDRESS: "",
        ISWAP_ROUTER: "",
        UniswapV3Factory: "0x1F98431c8aD98523631AE4a59f267346ea31F984",
      };
    case "polygon":
      return {
        UNI: "",
        DAI: "0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063",
        WETH: "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619",
        POSITION_MANAGER_ADDRESS: "",
        ISWAP_ROUTER: "",
        UniswapV3Factory: "0x1F98431c8aD98523631AE4a59f267346ea31F984",
      };
    case "optimism":
      return {
        UNI: "",
        DAI: "0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1",
        WETH: "0x4200000000000000000000000000000000000006",
        POSITION_MANAGER_ADDRESS: "",
        ISWAP_ROUTER: "",
        UniswapV3Factory: "0x1F98431c8aD98523631AE4a59f267346ea31F984",
      };
    case "arbitrum":
      return {
        UNI: "",
        DAI: "0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1",
        WETH: "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
        POSITION_MANAGER_ADDRESS: "",
        ISWAP_ROUTER: "",
        UniswapV3Factory: "0x1F98431c8aD98523631AE4a59f267346ea31F984",
      };
    case "goerli":
      return {
        UNI: "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984",
        DAI: "0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844",
        WETH: "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6",

        YF_SC: "0x7D6E270b09B6F6aA879445eEF81CFF63b22F29AC",
        YF_POSITION_NFT: "0xef7c4edC7A440C8157a7721371e1062E05b3BAF0",

        POSITION_MANAGER_ADDRESS: "0xC36442b4a4522E871399CD717aBDD847Ab11FE88",
        ISWAP_ROUTER: "0xE592427A0AEce92De3Edee1F18E0157C05861564",
        
        UniswapV3Factory: "0x1F98431c8aD98523631AE4a59f267346ea31F984",
      };
    default:
      throw new Error(`No addresses for Network: ${network}`);
  }
};

const params = {
    config1: {
        feeTiers            : 500,
        tickDeltaByFeeTier  : 1800,
        tickSpacingByFeeTier: 10
    },
    config2: {
        feeTiers            : 3000,
        tickDeltaByFeeTier  : 6900,
        tickSpacingByFeeTier: 60
    }
};

module.exports = {
  getAddresses,
  artifacts,
  rpc_url,
  token_json_path,
  params,
};
