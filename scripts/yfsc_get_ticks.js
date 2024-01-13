const { Contract  } = require("ethers")
const { artifacts } = require("/Users/armandmorin/Downloads/dynamic-liquidity-main/scripts/addresses.js");

YF_SC =  addresses['YF_SC']

async function main() {

  const signer2 = await ethers.getSigners();
  const user = signer2[0].address;
  console.log("user:", user);

  const YfScContract = new Contract(YF_SC, artifacts.YfSc.abi, user);

  var previousLR = await YfScContract.tickLower();
  var previousUR = await YfScContract.tickUpper();

  console.log("Current tickLower: ", Number(previousLR));
  console.log("Current tickUpper: ", Number(previousUR));
  
}

main().then(() => process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
  });