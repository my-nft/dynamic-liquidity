const { Contract, ContractFactory } = require("ethers")
const { getAddresses, artifacts } = require("./addresses.js");

const addresses = getAddresses(hre.network.name);

MINTER_ROLE     = "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6"

/// Bsc Testnet Sushi V3
SushiV3Factory = ""

/// Bsc Testnet Cake V3
PancakeV3Factory = "0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865"
ISWAP_ROUTER     = "0x1b81D678ffb9C0263b24A97847620C99d213eB14"
POSITION_MANAGER_ADDRESS = "0x46A15B0b27311cedF172AB29E4f4766fbE7F4364"

/// Goerli UV3
UniswapV3Factory = addresses['UniswapV3Factory']

POSITION_MANAGER_ADDRESS = addresses['POSITION_MANAGER_ADDRESS']
ISWAP_ROUTER             = addresses['ISWAP_ROUTER']

async function main() {
  const signer2 = await ethers.getSigners();
  console.log("signer1:", signer2[0].getAddress());

  PositionsNFTContract = new ContractFactory(artifacts.PositionsNFT.abi, artifacts.PositionsNFT.bytecode, signer2[0]);
  PositionsNFTContract = await PositionsNFTContract.deploy();

  YfScContract = new ContractFactory(artifacts.YfSc.abi, artifacts.YfSc.bytecode, signer2[0]);
  YfScContract = await YfScContract.deploy(PositionsNFTContract.target, POSITION_MANAGER_ADDRESS, ISWAP_ROUTER);

  const tx = await PositionsNFTContract.connect(signer2[0]).grantRole(MINTER_ROLE, YfScContract.target, {gasLimit:'1000000'})
  await tx.wait()

  console.log("YfScContract address        : ", YfScContract.target);
  console.log("PositionsNFTContract address: ", PositionsNFTContract.target);
}

main().then(() => process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
  });