//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import './FullMath.sol';
import './FixedPoint96.sol';
import './TickMath.sol';

import "hardhat/console.sol";

struct IncreaseLiquidityParams {
    uint256 tokenId;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
}

// Uniswap V3 mint params 
// struct MintParams {
//     uint24 uni3NftId;
//     address user;
//     uint totalLiquidity;
// }

struct MintParams {
    address token0;
    address token1; 
    uint24 fee;
    int24 tickLower; 
    int24 tickUpper; 
    uint256 amount0;
    uint256 amount1; 
    uint256 amount0Min; 
    uint256 amount1Min; 
    address receiver; 
    uint256 deadline;
}

struct DecreaseLiquidityParams {
    uint256 tokenId;
    uint128 liquidity;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
}

struct CollectParams {
    uint256 tokenId;
    address recipient;
    uint128 amount0Max;
    uint128 amount1Max;
}

// details about the uniswap position
// struct Univ3Position {
//     // the nonce for permits
//     uint96 nonce;
//     // the address that is approved for spending this token
//     address operator;
//     // the ID of the pool with which this token is connected
//     uint80 poolId;
//     // the tick range of the position
//     int24 tickLower;
//     int24 tickUpper;
//     // the liquidity of the position
//     uint128 liquidity;
//     // the fee growth of the aggregate position as of the last action on the individual position
//     uint256 feeGrowthInside0LastX128;
//     uint256 feeGrowthInside1LastX128;
//     // how many uncollected tokens are owed to the position, as of the last computation
//     uint128 tokensOwed0;
//     uint128 tokensOwed1;
// }
contract Token is ERC20 ("Test Token", "TT"){

}
contract PositionsNFT is ERC721, Pausable, AccessControl, ERC721Burnable {
    using Counters for Counters.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;

    mapping(address => mapping(uint=>uint)) public userNftPerPool;

    mapping(uint=>uint128) public liquidityForUserInPool; // nft --> liquidity 

    mapping(uint=>uint) public liquidityLastDepositTime; // nft --> liquidity 

    constructor() ERC721("Yf Sc Positions NFT", "YSP_NFT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _tokenIdCounter.increment(); // to start from 1
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function safeMint(uint uniswapNftId, address receiver, uint128 liquidity) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(receiver, tokenId);
        userNftPerPool[receiver][uniswapNftId] = tokenId;
        liquidityForUserInPool[tokenId] = liquidity;
        liquidityLastDepositTime[tokenId] = block.timestamp;
    }

    function getUserNftPerPool(address receiver, uint uniswapNftId) view public returns (uint) {
        return userNftPerPool[receiver][uniswapNftId];
    }


    function updateLiquidityForUser(uint positionNftId, uint128 liquidity)public onlyRole(MINTER_ROLE) {
        liquidityForUserInPool[positionNftId] = liquidityForUserInPool[positionNftId] + liquidity;
        liquidityLastDepositTime[positionNftId] = block.timestamp;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

contract NonfungiblePositionManager {

    function mint(MintParams calldata params)
        external
        payable
        // override
        // checkDeadline(params.deadline)
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        ){}
    
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        // override
        // checkDeadline(params.deadline)
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        ){}

    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        // override
        // isAuthorizedForToken(params.tokenId)
        // checkDeadline(params.deadline)
        returns (uint256 amount0, uint256 amount1){}

    function collect(CollectParams calldata params)
        external
        payable
        // override
        // isAuthorizedForToken(params.tokenId)
        returns (uint256 amount0, uint256 amount1){}

    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable {}

    function positions(uint256 tokenId)
        external
        view
        // override
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {}
}

/// @title YF SC : dynamic liquidity for uniswap V3
/// @author zak_ch
/// @notice Serves to track users liquidity and allocate fees
contract YfSc{
    /// @notice Deployer of the smart contract
    /// @return owner the address of this smart contract's deployer
    address public owner;

    uint public positionsIndex;

    mapping(uint => address) public positionsPair;
    mapping(uint => address) public positionOwner;

    mapping(address => uint) public balances;
    mapping(address => uint) public paidBalances;

    mapping(uint => address) positionsOwners;

    mapping(address => uint) public userPositionsCount;

    int24 public tickLower = -887220;
    int24 public tickUpper = 887220;

    uint public deadline = 600;

    uint public slippageToken0 = 500; // => 5 %
    uint public slippageToken1 = 500; // => 5 %

    uint public quotient = 10000; 

    uint128 public max_collect = 1e27;

    uint public positionsCounter;

    uint public liquidityLockTime = 3600 * 24 * 30; // one month liquidty lock time 

    PositionsNFT public positionsNFT;
    NonfungiblePositionManager public nonfungiblePositionManager;

    mapping(uint => uint) public totalLiquidity;

    mapping(address => mapping(address => mapping(uint => uint))) public poolNftIds; // [token0][token1][fee] = Original nft Id
    mapping(uint => uint) public updatedlNftId; // to keep track of the position after nft id change in case of change of ticks (remove and add liquidity)

    mapping(address => uint) public tokensBalances;
    mapping(address => uint) public totalRewards;
    mapping(address => uint) public paidRewards;

    int24 public tick_lower_0;
    int24 public tick_upper_0;

    int24 public tick_lower_1;
    int24 public tick_upper_1;

    /**
     * Contract initialization.
     */

    /// @notice Deploys the smart 
    /// @dev Assigns `msg.sender` to the owner state variable
    constructor(PositionsNFT _positionsNFT, NonfungiblePositionManager _nonfungiblePositionManager) {
        positionsNFT = _positionsNFT;
        nonfungiblePositionManager = _nonfungiblePositionManager;
        owner = msg.sender;
    }

    // Modifier to check that the caller is the owner of
    // the contract.
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        // Underscore is a special character only used inside
        // a function modifier and it tells Solidity to
        // execute the rest of the code.
        _;
    }

    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    function setTicks(int24 _tickLower, int24 _tickUpper) public onlyOwner{
        tickLower = _tickLower;
        tickUpper = _tickUpper;
    }

    function setSilppageToken0(uint _slippageToken0, uint _slippageToken1) public onlyOwner{
        slippageToken0 = _slippageToken0;
        slippageToken1 = _slippageToken1;
    }

    function setLockTime(uint _liquidityLockTime) public onlyOwner{
        liquidityLockTime = _liquidityLockTime;
    }

    // you will need to update the ticks first before calling this methods
    function updatePosition(address _token0, address _token1, uint24 _fee) external onlyOwner {
        tick_lower_0 = tickLower;
        tick_upper_0 = tickUpper;

        ERC20 token0 = ERC20(_token0);
        ERC20 token1 = ERC20(_token1);

        decreaseLiquidity(_token0, _token1, _fee, 100);

        uint newBalanceToken0 = token0.balanceOf(address(this));
        uint newBalanceToken1 = token1.balanceOf(address(this));

        poolNftIds[_token0][_token1][_fee] = 0;

        uint _amount0Min = newBalanceToken0 - newBalanceToken0 * slippageToken0 / quotient;
        uint _amount1Min = newBalanceToken1- newBalanceToken1 * slippageToken1 / quotient;

        tickLower = -27060;
        tickUpper = -25680;

        // mintUni3Nft(_token0, _token1, 
        // _fee, 
        // tickLower, tickUpper, 
        // newBalanceToken0, newBalanceToken1, 
        // _amount0Min, _amount1Min);

        // mintNFT(
        //     _token0, 
        //     _token1, 
        //     _fee, 
        //     newBalanceToken0, 
        //     newBalanceToken1
        // );

    }

    function mintUni3Nft(
                            address _token0, 
                            address _token1, 
                            uint24 _fee, 
                            int24 _tickLower, 
                            int24 _tickUpper, 
                            uint _amount0, 
                            uint _amount1, 
                            uint _amount0Min, 
                            uint _amount1Min
                        ) internal {
            MintParams memory mintParams;
            mintParams = MintParams(
                        _token0, 
                        _token1, 
                        _fee, 
                        _tickLower, 
                        _tickUpper, 
                        _amount0, 
                        _amount1, 
                        _amount0Min, 
                        _amount1Min, 
                        address(this), 
                        block.timestamp + deadline 
                        );
            

            (uint256 tokenId, uint128 liquidity, , ) = nonfungiblePositionManager.mint(mintParams);

            poolNftIds[_token0][_token1][_fee] = tokenId;

            poolNftIds[_token1][_token0][_fee] = tokenId;

            updatedlNftId[tokenId] = tokenId;
            positionsNFT.safeMint(tokenId, msg.sender, liquidity);

            totalLiquidity[tokenId] = liquidity; 

    }

    function increaseUni3Nft(
                                address _token0, 
                                address _token1, 
                                uint _fee, 
                                uint _amount0, 
                                uint _amount1, 
                                uint _amount0Min, 
                                uint _amount1Min) 
                            internal{
     
        uint tokenId = poolNftIds[_token0][_token1][_fee] > 0 ? poolNftIds[_token0][_token1][_fee] : poolNftIds[_token1][_token0][_fee];
        
        IncreaseLiquidityParams memory increaseLiquidityParams;
        increaseLiquidityParams = IncreaseLiquidityParams(
                    updatedlNftId[tokenId], 
                    _amount0, 
                    _amount1, 
                    _amount0Min, 
                    _amount1Min, 
                    block.timestamp + deadline ); 
        (uint128 liquidity,,) = nonfungiblePositionManager.increaseLiquidity(increaseLiquidityParams); 

        totalLiquidity[updatedlNftId[tokenId]] = totalLiquidity[updatedlNftId[tokenId]] + liquidity;

        if(positionsNFT.getUserNftPerPool(msg.sender, updatedlNftId[tokenId]) == 0){
            positionsNFT.safeMint(tokenId, msg.sender, liquidity);
        }else{
            positionsNFT.updateLiquidityForUser(positionsNFT.getUserNftPerPool(msg.sender, updatedlNftId[tokenId]), liquidity);
        }
    }

    /// @notice Allow user to deposit liquidity and mint corresponding NFT
    /// @dev Public function
    /// @param _token0 The first token of the liquidity pool pair
    /// @param _token1 The second token of the liquidity pool pair
    /// @param _fee The desired fee for the pool  
    /// @param _amount0 0 for _token0, 1 for _token1
    function mintNFT(
    address _token0, 
    address _token1, 
    uint24 _fee, 
    uint _amount0 
    // uint _amount1
    ) public {
        ERC20 token0 = ERC20(_token0);
        ERC20 token1 = ERC20(_token1);
        uint _amount1 = getAmount1ForAmount0(tickLower, tickUpper, _amount0);
        _amount1 = 10000000000000;
        token0.transferFrom(msg.sender, address(this), _amount0);
        token1.transferFrom(msg.sender, address(this), _amount1);
        token0.approve(address(nonfungiblePositionManager), _amount0);
        token1.approve(address(nonfungiblePositionManager), _amount1);
        
        uint _amount0Min = _amount0 - _amount0 * slippageToken0 / quotient;
        uint _amount1Min = _amount1- _amount1 * slippageToken1 / quotient;

        if(poolNftIds[_token0][_token1][_fee] == 0 && poolNftIds[_token1][_token0][_fee] == 0)
        {
            mintUni3Nft(_token0, _token1, _fee, tickLower, tickUpper, _amount0, _amount1, _amount0Min, _amount1Min);
        }else{
    
            increaseUni3Nft(_token0, _token1, _fee, _amount0, _amount1, _amount0Min, _amount1Min);
        }        
    }

    function decreaseLiquidity(address _token0, address _token1, uint24 _fee, uint128 _purcentage) public {
        uint _poolNftId = poolNftIds[_token0][_token1][_fee];
        uint _userNftId = positionsNFT.getUserNftPerPool(msg.sender, updatedlNftId[_poolNftId]);
        require(positionsNFT.liquidityLastDepositTime(_userNftId) < block.timestamp + liquidityLockTime, "liquidity locked !");
        uint userNft = positionsNFT.getUserNftPerPool(msg.sender, updatedlNftId[_poolNftId]);
        uint128 _userLiquidity = positionsNFT.liquidityForUserInPool(userNft);

        uint128 _liquidityToRemove = _userLiquidity * _purcentage / 100;

        uint _amount0Min = 0; // maybe integrate slippage later
        uint _amount1Min = 0; // maybe integrate slippage later 

        DecreaseLiquidityParams memory decreaseLiquidityParams;
        decreaseLiquidityParams = DecreaseLiquidityParams(
                    updatedlNftId[_poolNftId], 
                    _liquidityToRemove, 
                    _amount0Min, 
                    _amount1Min, 
                    block.timestamp + deadline); 

        ERC20 token0 = ERC20(_token0);
        ERC20 token1 = ERC20(_token1);

        nonfungiblePositionManager.decreaseLiquidity(decreaseLiquidityParams);
   
        collect(_token0, _token1, _fee);
     
        totalLiquidity[updatedlNftId[_poolNftId]] = totalLiquidity[updatedlNftId[_poolNftId]] - _liquidityToRemove;
    }

    function sweepToken(address _token, uint amount, address receiver) public {
        nonfungiblePositionManager.sweepToken(_token, amount, receiver);
    }

    function collect(address _token0, address _token1, uint _fee) public {
        uint _poolNftId = poolNftIds[_token0][_token1][_fee]; // get first pool nft id 
        CollectParams memory collectParams;

        ERC20 token0 = ERC20(_token0);
        ERC20 token1 = ERC20(_token1);

        uint oldBalanceToken0 = token0.balanceOf(address(this));
        uint oldBalanceToken1 = token1.balanceOf(address(this));
        collectParams = CollectParams(
                    updatedlNftId[_poolNftId], 
                    address(this), 
                    max_collect, 
                    max_collect); 
        nonfungiblePositionManager.collect(collectParams);

        uint newBalanceToken0 = token0.balanceOf(address(this));
        uint newBalanceToken1 = token1.balanceOf(address(this));

        uint new_reward0 = newBalanceToken0 - oldBalanceToken0;
        uint new_reward1 = newBalanceToken1 - oldBalanceToken1;

        totalRewards[_token0] = totalRewards[_token0] + new_reward0;

        totalRewards[_token1] = totalRewards[_token1] + new_reward1;
    }

    // rebalance --> burn nft and create new one for new position 

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param _tickLower tick lower
    /// @param _tickUpper tick upper
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        int24 _tickLower,
        int24 _tickUpper,
        uint256 amount0
    ) public pure returns (uint128 liquidity) {
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(_tickLower); //A sqrt price representing the first tick boundary
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(_tickUpper); //A sqrt price representing the second tick boundary
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param _tickLower tick lower
    /// @param _tickUpper tick upper
    /// @param amount0 The amount0 being sent in
    /// @return amount1 The amount of returned liquidity
    function getAmount1ForAmount0(
        int24 _tickLower,
        int24 _tickUpper,
        uint256 amount0
    ) internal pure returns (uint256 amount1) {
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(_tickLower); //A sqrt price representing the first tick boundary
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(_tickUpper); //A sqrt price representing the second tick boundary
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        uint128 liquidity = toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
        return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }


    // add the fees 
    // in rebalance you take just the nft id 
    // user will select the pair he wants 

}