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

// import {PRBMathUD60x18} from "@prb/math/contracts/PRBMathUD60x18.sol";

import "prb-math/contracts/PRBMathUD60x18.sol";

import './FullMath.sol';
import './FixedPoint96.sol';
import './TickMath.sol';
import './ISwapRouter.sol';

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

struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
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

    mapping(uint=>mapping(uint=>uint128)) public liquidityForUserInPoolAtState; // nft --> state --> liquidity 

    mapping(uint => mapping(uint => uint)) public statesIdsForPosition;

    mapping(uint => uint) public totalStatesForPosition;

    mapping(uint => uint) public lastClaimForPosition;

    mapping(uint => uint) public totalClaimedforPosition;

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

    function safeMint(uint _uniswapNftId, address _receiver, uint128 _liquidity, uint _state) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_receiver, tokenId);
        userNftPerPool[_receiver][_uniswapNftId] = tokenId;   
        updateLiquidityForUser(tokenId, _liquidity, _state);
    }

    function getUserNftPerPool(address receiver, uint uniswapNftId) view public returns (uint) {
        return userNftPerPool[receiver][uniswapNftId];
    }

    function updateLiquidityForUser(uint positionNftId, uint128 _liquidity, uint _state)public onlyRole(MINTER_ROLE) {
        liquidityForUserInPoolAtState[positionNftId][_state] = _liquidity;
        if(statesIdsForPosition[positionNftId][totalStatesForPosition[positionNftId]] < _state){
            totalStatesForPosition[positionNftId]++;
        }
        statesIdsForPosition[positionNftId][totalStatesForPosition[positionNftId]] = _state;
    }

    // function incrementTotalStatesForUserPosition(uint positionNftId)public onlyRole(MINTER_ROLE) {
    //     return;
    //     // totalStatesForPosition[positionNftId]++;
    // }

    function updateLastClaimForPosition(uint _positionNftId, uint _state)public onlyRole(MINTER_ROLE) {
        lastClaimForPosition[_positionNftId] = _state;
    }

    function updateTotalClaimForPosition(uint _positionNftId, uint _totalClaim)public onlyRole(MINTER_ROLE) {
        totalClaimedforPosition[_positionNftId] = _totalClaim;
    }

    function getLiquidityForUserInPoolAtState(uint _userPositionNft, uint _state) public view returns(uint128 liquidity){
        liquidity = liquidityForUserInPoolAtState[_userPositionNft][_state];
        return liquidity;
    }

    function getStatesIdsForPosition(uint _userPositionNft, uint _stateId) public view returns(uint id){
        id = statesIdsForPosition[_userPositionNft][_stateId];
        return id;
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

    address public factory;

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

contract Factory {

    // mapping(address => mapping(address => mapping(uint24 => address))) public  getPool;
    function getPool(address _token0, address _token1, uint24 _fee) public returns (address) {}
}

contract Pool {
        struct Slot0 {
        // the current price
        uint160 sqrtPriceX96;
        // the current tick
        int24 tick;
        // the most-recently updated index of the observations array
        uint16 observationIndex;
        // the current maximum number of observations that are being stored
        uint16 observationCardinality;
        // the next maximum number of observations to store, triggered in observations.write
        uint16 observationCardinalityNext;
        // the current protocol fee as a percentage of the swap fee taken on withdrawal
        // represented as an integer denominator (1/x)%
        uint8 feeProtocol;
        // whether the pool is locked
        bool unlocked;
    }
    
    Slot0 public slot0;

    int24 public tickSpacing;
}

/// @title YF SC : dynamic liquidity for uniswap V3
/// @author zak_ch
/// @notice Serves to track users liquidity and allocate fees
contract YfSc{
    /// @notice Deployer of the smart contract
    /// @return owner the address of this smart contract's deployer
    address public owner;

    /// fees distribution 
    uint public statesCounter = 1; 

    // last state the liquidty of a uniswap nft was updated 
    mapping(uint=>uint) public liquidityLastStateUpdate; // nft --> last State Update for liquidity for Uni3 NFT

    // for a given uniswap nft, and a given state, returns the corresponding liquidty 
    mapping(uint => mapping(uint => uint128)) public totalLiquidityAtStateForNft; 

    // for a given uniswap nft, and a given state, returns the claimed reward for token 0
    mapping(uint => mapping(uint => uint)) public rewardAtStateForNftToken0; 
    // for a given uniswap nft, and a given state, returns the claimed reward for token 1
    mapping(uint => mapping(uint => uint)) public rewardAtStateForNftToken1; 

    // for a given uniswap nft, returns the total claimed reward for token 0
    mapping(uint => uint) public totalRewardForNftToken0; 

    // for a given uniswap nft, returns the total claimed reward for token 1
    mapping(uint => uint) public totalRewardForNftToken1; 

    // for a given uniswap nft, returns the total paid reward for token 0
    mapping(uint => uint) public totalRewardPaidForNftToken0; 

    // for a given uniswap nft, returns the total paid reward for token 1
    mapping(uint => uint) public totalRewardPaidForNftToken1; 

    // since the smart contract will be traking states for different pools, we need a counter for each pool
    mapping(uint => mapping(uint => uint)) public statesIdsForNft; 

    // to be able to loop through states of a given uniswap nft 
    mapping(uint => uint) public totalStatesForNft; 

    int24 public tickLower; 
    int24 public tickUpper;

    // deadline for transactions to be validated, otherwise reject
    uint public deadline = 600; 

    uint public slippageToken0 = 500; // => 5 % 
    uint public slippageToken1 = 500; // => 5 % 

    // quotitnt for slippage calculation
    uint public quotient = 10000; 

    // big number used to collect all the rewards from the pool in a given transaction 
    uint128 public max_collect = 1e27; 

    uint public liquidityLockTime = 3600 * 24 * 30; // one month liquidty lock time 
    
    // track last deposit time for each user position, to be able to enforce the lock time 
    mapping(uint => uint) public liquidityLastDepositTime; // position nft => timestamp 

    // Position NFT contract, to generate and track users positions
    PositionsNFT public positionsNFT; 

    // Uniswap v3 position manager
    NonfungiblePositionManager public nonfungiblePositionManager; 

    // Uniswap v3 router for internal swaps
    ISwapRouter public iSwapRouter;

    // The current pool nft id
    mapping(address => mapping(address => mapping(uint => uint))) public poolNftIds; // [token0][token1][fee] 
    
    // The first nft id to be minted for a given pool configuration (token0, token1, fee)
    mapping(address => mapping(address => mapping(uint => uint))) public originalPoolNftIds; // [token0][token1][fee] = Original nft Id 

    mapping(address => uint) public totalRewards; 

    // Events
    event NftMinted(uint tokenId, uint liquidityInPool, uint amount0, uint amount1);
    event IncreaseLiquidity(uint128 liquidity, uint _amount0, uint _amount1, uint uniNft, uint yfNft);
  
    /**
     * Contract initialization.
     */

    /// @notice Deploys the smart 
    /// @dev Assigns `msg.sender` to the owner state variable
    constructor(PositionsNFT _positionsNFT, NonfungiblePositionManager _nonfungiblePositionManager, ISwapRouter _iSwapRouter) {
        positionsNFT = _positionsNFT;
        nonfungiblePositionManager = _nonfungiblePositionManager;
        iSwapRouter = _iSwapRouter;
        owner = msg.sender;

        tickLower = -887220;
        tickUpper = 887220;

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

    /// @notice external method 
    /// Allow to fixe the ticks for liquidity create/update operations 
    /// the values of the ticks are converted to price range using uniswap v3 tick formula: 
    /// Price (tick) = 1,0001 exp(tick)
    /// @dev external method to be called only by the owner 
    /// @param _tickLower lower price range tick
    /// @param _tickUpper upper roce range tick
    function setTicks(int24 _tickLower, int24 _tickUpper) public onlyOwner{
    
    }

    function setRates(address _token0, address _token1, uint24 _fee, int24 _ticksUp, int24 _ticksDown) public onlyOwner {
    }

    function currentTicksForPosition(address _token0, address _token1, uint _fee) view public returns (int24 _tickLower, int24 _tickUpper){
        (,,,,, _tickLower,_tickUpper,,,,,) = nonfungiblePositionManager.positions(poolNftIds[_token1][_token0][_fee] );
    }

    function getTotalLiquidityAtStateForPosition(uint _position, uint _state) public view returns(uint){
        return totalLiquidityAtStateForNft[_position][_state];
    }

    /// @notice external method 
    /// Allow to fixe the slippage for token0 and token1 in all the liquidity related operations
    /// the default denominator is 10000, so 100 corresponds to a 1 % slippage value
    /// @dev external method to be called only by the owner 
    /// @param _slippageToken0 slippage for token 0
    /// @param _slippageToken1 slippage for token 1
    function setSilppageToken0(uint _slippageToken0, uint _slippageToken1) external onlyOwner{
        slippageToken0 = _slippageToken0;
        slippageToken1 = _slippageToken1;
    }

    /// @notice external method 
    /// Allow o update the lock time for liquidity. 
    /// The counter is initialised for a given user in each deposit
    /// @dev external method to be called only by the owner 
    /// @param _liquidityLockTime new lock time in seconds
    function setLockTime(uint _liquidityLockTime) external onlyOwner{
        liquidityLockTime = _liquidityLockTime;
    }

    /// @notice external function 
    /// Allow o update the ticks of a given position,
    /// you should call setTicks before to update ticks values to the new price range
    /// @dev external method to be called only by the owner 
    /// @param _token0 The first token of the liquidity pool pair
    /// @param _token1 The second token of the liquidity pool pair
    /// @param _fee The desired fee for the pool 
    function updatePosition(address _token0, address _token1, uint24 _fee) external onlyOwner {
    }

    /// @notice internal function used to create new uniswap v3 position
    /// @dev internal function
    /// @param _token0 The first token of the liquidity pool pair
    /// @param _token1 The second token of the liquidity pool pair
    /// @param _fee The desired fee for the pool  
    /// @param _amount0 desired amount of token 0 to be deposited
    /// @param _amount1 desired amount of token 1 to be deposited
    /// @param _amount0Min minimum accepted amount of token 0
    /// @param _amount1Min minimum accepted amount of token 1
    /// @return liquidity the total amount of liquidity added
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
                        ) internal returns(uint128 liquidity){

        return 1;
    }

    /// @notice internal function used to increase liquidity in a given uniswap v3 pool
    /// @dev internal function
    /// @param _token0 The first token of the liquidity pool pair
    /// @param _token1 The second token of the liquidity pool pair
    /// @param _fee The desired fee for the pool  
    /// @param _amount0 desired amount of token 0 to be deposited
    /// @param _amount1 desired amount of token 1 to be deposited
    /// @param _amount0Min minimum accepted amount of token 0
    /// @param _amount1Min minimum accepted amount of token 1
    /// @return _liquidity liquidity the total amount of liquidity added
    function increaseUni3Nft(
                                address _token0, 
                                address _token1, 
                                uint _fee, 
                                uint _amount0, 
                                uint _amount1, 
                                uint _amount0Min, 
                                uint _amount1Min) 
                            internal returns(uint128 _liquidity){
        return 1;
    }

    /// @notice Allow user to deposit liquidity, mint corresponding uniswap NFT and position NFT, 
    /// if the position is already open by a precedent deposit, no uniswap NFT will be created. 
    /// The position wil be increaserd
    /// if the user already have a position in this pool, his liquidity will be increased, 
    /// and no position NFT will be minted
    /// @dev Public function
    /// @param _token0 The first token of the liquidity pool pair
    /// @param _token1 The second token of the liquidity pool pair
    /// @param _fee The desired fee for the pool  
    /// @param _amount0 desired amount of token 0 to be deposited
    /// @param _amount1 desired amount of token 1 to be deposited, 
    /// if the amounts doesn't correspondant to the pool configuration, 
    /// internal swap will take place to match the right amounts
    // To avoid being stuck with random erc20, bettre put weth address as _token1
    function mintNFT(
    address _token0, 
    address _token1, 
    uint24 _fee, 
    uint _amount0,
    uint _amount1
    ) public {

    }

    /// @notice Allow user to withdraw liquidity from a given position, 
    /// It will burn the liquidity and send the tokens to the depositer
    /// @dev Public function
    /// @param _token0 The first token of the liquidity pool pair
    /// @param _token1 The second token of the liquidity pool pair
    /// @param _fee The desired fee for the pool  
    /// @param _purcentage desired % of the users liquidity to be removed
    /// @param _notYetpdated always set to true, it is set to false only internally
    function decreaseLiquidity(address _token0, address _token1, uint24 _fee, uint128 _purcentage, bool _notYetpdated) public {

    }
    
    /// @notice returns the pending rewards for a user in a given pool
    /// @dev Public function
    /// @param _token0 The first token of the liquidity pool pair
    /// @param _token1 The second token of the liquidity pool pair
    /// @param _fee The desired fee for the pool  
    function getPendingrewardForPosition(address _token0, address _token1, uint _fee) view public returns (uint reward0, uint reward1){

    }

    /// @notice collect pending reward for the whole position, send the caller shares, 
    /// and store the reste in the smart contract
    /// @dev Public function
    /// @param _token0 The first token of the liquidity pool pair
    /// @param _token1 The second token of the liquidity pool pair
    /// @param _fee The desired fee for the pool  
    /// @param _tokensOwed0 external caller should enter 0, a positive value is used in case of decreaseliquidity internal call
    /// @param _tokensOwed1 external caller should enter 0, a positive value is used in case of decreaseliquidity internal call
    function collect(address _token0, address _token1, uint _fee, uint128 _tokensOwed0, uint128 _tokensOwed1) public {

    }

    /// @notice Computes the required amount of token1 for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param _tickLower tick lower
    /// @param _tickUpper tick upper
    /// @param amount0 The amount0 being sent in
    /// @return amount1 The amount of returned liquidity
    function getAmount1ForAmount0(
        int24 _tickLower,
        int24 _tickUpper,
        uint256 amount0
    ) public pure returns (uint256 amount1) {
        return amount1;
    }

    function checkTick(int24 _tick)public view returns (uint160){
        return 1;
    }

    function computeTick(uint160 sqrtPriceX96) public view returns (int24){
        return -887220;
    }

    function _sqrt(uint _x) internal pure returns(uint y) {  
    }
    
    function getSqrtPriceX96(uint priceA, uint priceB) public view returns (uint) {
        return 1;
    }

    /// @dev Rounds tick down towards negative infinity so that it's a multiple
    /// of `tickSpacing`.
    function _floor(int24 tick, int24 tickSpacing) internal view returns (int24) {
        return 1;
    }

}