const { BigNumber } = require("ethers");

async function approveIfNeeded(token, owner, spender, requiredAmount) {
    const currentAllowance = BigNumber.from(await token.allowance(owner, spender));

    console.log("Current allowance : ", currentAllowance.toString());
    console.log("Required allowance : ", requiredAmount.toString());
    console.log("");
  
    if (currentAllowance.lt(requiredAmount)) {
        const amountToApprove = requiredAmount.sub(currentAllowance);
        await token.connect(owner).approve(spender, amountToApprove);
    } else {
        console.log("Already approved");
    }
}

module.exports = {
    approveIfNeeded,
};