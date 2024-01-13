function getAmount0(sqrtA, sqrtB, liquidity, decimals) {
    if (sqrtA > sqrtB) {
        [sqrtA, sqrtB] = [sqrtB, sqrtA];
    }
    return Math.round((liquidity * 2 ** 96 * (sqrtB - sqrtA) / (sqrtB * sqrtA)) / 10 ** decimals);
}

function getAmount1(sqrtA, sqrtB, liquidity, decimals) {
    if (sqrtA > sqrtB) {
        [sqrtA, sqrtB] = [sqrtB, sqrtA];
    }
    return Math.round(liquidity * (sqrtB - sqrtA) / 2 ** 96 / 10 ** decimals);
}

function getAmounts(asqrt, asqrtA, asqrtB, decimal0, decimal1) {
    const sqrt = Math.sqrt(asqrt * 10 ** (decimal1 - decimal0)) * (2 ** 96);
    let sqrtA = Math.sqrt(asqrtA * 10 ** (decimal1 - decimal0)) * (2 ** 96);
    let sqrtB = Math.sqrt(asqrtB * 10 ** (decimal1 - decimal0)) * (2 ** 96);

    if (sqrtA > sqrtB) {
        [sqrtA, sqrtB] = [sqrtB, sqrtA];
    }

    const liquidity0 = getLiquidity0(sqrt, sqrtB, amount0, decimal0);
    const liquidity1 = getLiquidity1(sqrtA, sqrt, amount1, decimal1);

    const liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;

    const amount0 = getAmount0(sqrt, sqrtB, liquidity, decimal0);
    const amount1 = getAmount1(sqrtA, sqrt, liquidity, decimal1);

    return [amount0, amount1];
}

function getLiquidity0(sqrtA, sqrtB, amount0, decimals) {
    if (sqrtA > sqrtB) {
        [sqrtA, sqrtB] = [sqrtB, sqrtA];
    }
    return amount0 / (2 ** 96 * (sqrtB - sqrtA) / (sqrtB * sqrtA) / 10 ** decimals);
}

function getLiquidity1(sqrtA, sqrtB, amount1, decimals) {
    if (sqrtA > sqrtB) {
        [sqrtA, sqrtB] = [sqrtB, sqrtA];
    }
    return amount1 / ((sqrtB - sqrtA) / 2 ** 96 / 10 ** decimals);
}

module.exports = {
    getAmount0,
    getAmount1,
    getAmounts,
    getLiquidity0,
    getLiquidity1
};
