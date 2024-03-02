const ethers = require('ethers');
const { getAddresses } = require("./addresses.js");
const addresses = getAddresses(hre.network.name);

const artifacts = {
    NonfungiblePositionManager: require("@uniswap/v3-periphery/artifacts/contracts/NonfungiblePositionManager.sol/NonfungiblePositionManager.json"),
    UniswapV3Factory: require('@uniswap/v3-core/artifacts/contracts/UniswapV3Factory.sol/UniswapV3Factory.json'), 
    UniswapV3Pool: require('@uniswap/v3-core/artifacts/contracts/UniswapV3Pool.sol/UniswapV3Pool.json'),
    WETH: require("../artifacts/contracts/WETH9.sol/WETH9.json"),
    UNI: require("../artifacts/contracts/yfsc.sol/Token.json"),
    yfsc_wrapper: require("../artifacts/contracts/yfsc_wrapper.sol/yfsc_wrapper.json"),
    yfsc_wrapper_deployer: require("../artifacts/contracts/yfsc_wrapper_deployer.sol/yfsc_wrapper_deployer.json"),
    YfSc: require("../artifacts/contracts/yfsc.sol/YfSc.json"),
    PositionsNFT: require("../artifacts/contracts/yfsc.sol/PositionsNFT.json"),
    SwapRouter: require("../artifacts/contracts/ISwapRouter.sol/ISwapRouter.json"),
  };

  async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    // Deploy yfsc_wrapper_deployer
    const deployerFactory = new ethers.ContractFactory(
        artifacts.yfsc_wrapper_deployer.abi, 
        artifacts.yfsc_wrapper_deployer.bytecode, 
        deployer
    );

    const deployerContract = await deployerFactory.deploy();
    await deployerContract.deployed();
    console.log('yfsc_wrapper_deployer Contract Address:', deployerContract.address);

    // Prepare parameters for yfsc_wrapper
    const UniswapV3Factory = addresses['UniswapV3Factory'];
    const T0 = addresses["UNI"];
    const T1 = addresses["WETH"];
    const feeTier = 3000;
    const tickSpacing = 60;

    // Deploy yfsc_wrapper using yfsc_wrapper_deployer
    const deployTx = await deployerContract.deploy(
        UniswapV3Factory, 
        T0, 
        T1, 
        feeTier, 
        tickSpacing
    );
    const receipt = await deployTx.wait();
    const event = receipt.events.find(event => event.event === 'PoolDeployed');
    const wrapperAddress = event.args.pool;
    console.log('yfsc_wrapper Contract Address:', wrapperAddress);

    // Interact with the deployed yfsc_wrapper contract
    const wrapperContract = new ethers.Contract(wrapperAddress, artifacts.yfsc_wrapper.abi, deployer);

    // Example of interaction: calling a function from the yfsc_wrapper contract
    // Replace `someFunction` and `args` with actual function and parameters
    // const result = await wrapperContract.someFunction(args);
    // console.log('Result from function call:', result);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

