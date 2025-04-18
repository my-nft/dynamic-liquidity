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
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(_tickLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(_tickUpper);
        tickLower = _tickLower;
        tickUpper = _tickUpper;
    }

    function setRates(address _token0, address _token1, uint24 _fee, int24 _ticksUp, int24 _ticksDown) public onlyOwner {
        address _factoryAddress = nonfungiblePositionManager.factory();
        Factory _factory = Factory(_factoryAddress);
        address _poolAddress = _factory.getPool(_token0, _token1, _fee);
        Pool pool = Pool(_poolAddress);
        (, int24 tick, , , , , ) = pool.slot0();
        int24 tickSpacing = pool.tickSpacing();

        int24 tickFloor = _floor(tick, tickSpacing);

        int24 tickCeil = tickFloor + tickSpacing;

        setTicks(tickFloor - _ticksDown * tickSpacing, tickCeil + _ticksUp * tickSpacing);
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

        // initialise the pool tokens contracts
        ERC20 token0 = ERC20(_token0);
        ERC20 token1 = ERC20(_token1);

        // store the laste state counter value 
        uint oldStateCounter = statesCounter;

        // before updating the position, we first claim all the pending rewards for both tokens
        collect(_token0, _token1, _fee, 0, 0);

        // We store the contract balance of bothe tokens to knwo the precise amount of liquidity tokens removed
        uint oldBalanceToken0 = token0.balanceOf(address(this));
        uint oldBalanceToken1 = token1.balanceOf(address(this));

        // decrease 100% of the liquidity. 'false' to indicate that liquidity sates have not been updated yet 
        decreaseLiquidity(_token0, _token1, _fee, 100, false);

        // pull the new tokens balances to calculate the total received tokens after liquidty being removed, 
        // to add them back using the new ticks
        uint newBalanceToken0 = token0.balanceOf(address(this));
        uint newBalanceToken1 = token1.balanceOf(address(this));
        
        // Get the current nft id to be burned
        uint _nftId = poolNftIds[_token0][_token1][_fee];

        // reset the nft id for the pool to be able to store the new nft id that will be minted 
        poolNftIds[_token0][_token1][_fee] = 0;

        // prepare the values to be added as liquidity in the new price range
        uint _amount0 = newBalanceToken0;

        // calculate the amount of the token1 using this formula to minimize internal swaps 
        uint _amount1 = getAmount1ForAmount0(tickLower, tickUpper, _amount0);

        // apply the slippage params 
        uint _amount0Min = newBalanceToken0 - newBalanceToken0 * slippageToken0 / quotient;
        uint _amount1Min = newBalanceToken1- newBalanceToken1 * slippageToken1 / quotient;

        // Since decrease liquidity sends the tokens back to the owner wallet, we have to transfer them back
        token0.transferFrom(msg.sender, address(this), _amount0);
        token1.transferFrom(msg.sender, address(this), _amount1);

        // approve the uniswap v3 position manager to spend the tokens to mint the position 
        token0.approve(address(nonfungiblePositionManager), _amount0);
        token1.approve(address(nonfungiblePositionManager), _amount1);
        
        // we can apply the slippage formula, but this is better for transactions fees
        _amount0Min = 0 ;
        _amount1Min = 0 ; 

        MintParams memory mintParams;

        // prepare mint params 
        mintParams = MintParams(
                    _token0, 
                    _token1, 
                    _fee, 
                    tickLower, 
                    tickUpper, 
                    _amount0, 
                    _amount1, 
                    0, 
                    0, 
                    address(this), 
                    block.timestamp + deadline 
                    );

        //Mint the new position
        (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        ) = nonfungiblePositionManager.mint(mintParams);

        emit NftMinted(tokenId, liquidity, amount0, amount1);

        // update the uniswap nft 
        poolNftIds[_token0][_token1][_fee] = tokenId;

        // update the uniswap nft 
        poolNftIds[_token1][_token0][_fee] = tokenId;

        uint balanceToken0After = token0.balanceOf(address(this));
        uint balanceToken1After = token1.balanceOf(address(this));

        // in case some tokens wasn t added as liquidity, send back to caller 
        if(balanceToken0After > oldBalanceToken0){
            token0.transfer(msg.sender, balanceToken0After - oldBalanceToken0);
        }

        // in case some tokens wasn t added as liquidity, send back to caller 
        if(balanceToken1After > oldBalanceToken1){
            token1.transfer(msg.sender, balanceToken1After - oldBalanceToken1);
        }

        // get the fist uniswap nft minted for the tokens pair - fee
        uint _originalPositionNft = originalPoolNftIds[_token0][_token1][_fee];

        (,,,,,,,uint128 _liquidity,,,,) = nonfungiblePositionManager.positions(_nftId);

        totalLiquidityAtStateForNft[_nftId][oldStateCounter] = _liquidity; 

        statesIdsForNft[_originalPositionNft][totalStatesForNft[_originalPositionNft]] = statesCounter;
        totalStatesForNft[_originalPositionNft]++;

        liquidityLastStateUpdate[_originalPositionNft] = statesCounter;

        statesCounter++ ;
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

        (uint256 tokenId, uint128 _liquidity , uint __amount0, uint __amount1) = nonfungiblePositionManager.mint(mintParams);

        emit NftMinted(tokenId, liquidity, __amount0, __amount1);

        if (originalPoolNftIds[_token0][_token1][_fee] == 0 && originalPoolNftIds[_token1][_token0][_fee] == 0){
            originalPoolNftIds[_token1][_token0][_fee] = tokenId;
            originalPoolNftIds[_token0][_token1][_fee] = tokenId;
        }

        poolNftIds[_token0][_token1][_fee] = tokenId;

        poolNftIds[_token1][_token0][_fee] = tokenId;

        positionsNFT.safeMint(tokenId, msg.sender, _liquidity, statesCounter);

        liquidity = _liquidity;
        return liquidity;
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

        uint tokenId = poolNftIds[_token0][_token1][_fee] > 0 ? poolNftIds[_token0][_token1][_fee] : poolNftIds[_token1][_token0][_fee];
        uint _nftId = originalPoolNftIds[_token0][_token1][_fee];
        (,,,,,,,uint128 oldLiquidity,,,,) = nonfungiblePositionManager.positions(tokenId);

        IncreaseLiquidityParams memory increaseLiquidityParams; 
        increaseLiquidityParams = IncreaseLiquidityParams( 
                    tokenId, 
                    _amount0, 
                    _amount1, 
                    _amount0Min, 
                    _amount1Min, 
                    block.timestamp + deadline); 
        (uint128 liquidity, uint amount0, uint amount1) = nonfungiblePositionManager.increaseLiquidity(increaseLiquidityParams);
        _liquidity = liquidity;

        totalLiquidityAtStateForNft[tokenId][statesCounter] = liquidity; 
        uint userPositionNft = positionsNFT.getUserNftPerPool(msg.sender, _nftId);
        emit IncreaseLiquidity(liquidity, amount0, amount1, tokenId, userPositionNft);
        
        uint128 userAddedLiquidty = liquidity ; 
        uint lastLiquidityUpdateStateForPosition = positionsNFT.totalStatesForPosition(userPositionNft);
        uint userPositionLastUpdateState = positionsNFT.getStatesIdsForPosition(userPositionNft, lastLiquidityUpdateStateForPosition);
        
        uint128 userOldLiquidityInPool = positionsNFT.getLiquidityForUserInPoolAtState(userPositionNft, userPositionLastUpdateState);
    
        if(positionsNFT.getUserNftPerPool(msg.sender, _nftId) == 0){
            positionsNFT.safeMint(_nftId, msg.sender, userAddedLiquidty, statesCounter);
        }
        // else{
        //     positionsNFT.updateLiquidityForUser(userPositionNft, userAddedLiquidty + userOldLiquidityInPool, statesCounter);
        // }
    
        return liquidity;
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
        
        ERC20 token0 = ERC20(_token0);
        ERC20 token1 = ERC20(_token1); 

        uint oldBalanceToken0 = token0.balanceOf(address(this));
        uint oldBalanceToken1 = token1.balanceOf(address(this));

        token0.transferFrom(msg.sender, address(this), _amount0);
        token1.transferFrom(msg.sender, address(this), _amount1);
        
        token0.approve(address(nonfungiblePositionManager), 2*_amount0);
        token1.approve(address(nonfungiblePositionManager), 2*_amount1);
        
        ISwapRouter.ExactInputSingleParams memory _exactInputSingleParams;
   
        uint _amount0Min = 0;
        uint _amount1Min = 0;

        uint128 _liquidityAdded;

        // setRates(70000000000000000, 90000000000000000);
        
        if(poolNftIds[_token0][_token1][_fee] == 0 && poolNftIds[_token1][_token0][_fee] == 0)
        {
            _liquidityAdded = mintUni3Nft(_token0, _token1, _fee, tickLower, tickUpper, _amount0, _amount1, _amount0Min, _amount1Min);
        }else{
            _liquidityAdded = increaseUni3Nft(_token0, _token1, _fee, _amount0, _amount1, _amount0Min, _amount1Min);
        }  

        collect(_token0, _token1, _fee, 0, 0);

        uint newBalanceToken0 = token0.balanceOf(address(this));
        uint newBalanceToken1 = token1.balanceOf(address(this));

        if(newBalanceToken0 - oldBalanceToken0 > 0){
            uint half = (newBalanceToken0 - oldBalanceToken0)/2;
             _exactInputSingleParams = ISwapRouter.ExactInputSingleParams(
                _token0, 
                _token1, 
                _fee, 
                address(this), 
                block.timestamp + deadline,
                half,
                0,
                0
            );

            token0.approve(address(iSwapRouter), half);
            uint256 amountOut = iSwapRouter.exactInputSingle(_exactInputSingleParams);
            uint _amountMin = 0; 
        
            token0.approve(address(nonfungiblePositionManager), half);
            token1.approve(address(nonfungiblePositionManager), amountOut);
            _liquidityAdded += increaseUni3Nft(_token0, _token1, _fee, half, amountOut, _amountMin, _amountMin);
        }

        if(newBalanceToken1 - oldBalanceToken1 > 0){
            uint half = (newBalanceToken1 - oldBalanceToken1)/2;
             _exactInputSingleParams = ISwapRouter.ExactInputSingleParams(
                _token1, 
                _token0, 
                _fee, 
                address(this), 
                block.timestamp + deadline,
                half,
                0,
                0
            );

            token1.approve(address(iSwapRouter), half);
            uint256 amountOut = iSwapRouter.exactInputSingle(_exactInputSingleParams);
            uint _amountMin = 0; 
        
            token1.approve(address(nonfungiblePositionManager), half);
            token0.approve(address(nonfungiblePositionManager), amountOut);
            _liquidityAdded += increaseUni3Nft(_token0, _token1, _fee, amountOut, half, _amountMin, _amountMin);
        }

        oldBalanceToken0 = token0.balanceOf(address(this));
        oldBalanceToken1 = token1.balanceOf(address(this));
        uint _nftId = originalPoolNftIds[_token0][_token1][_fee];
        uint _poolNftId = poolNftIds[_token0][_token1][_fee];
        (,,,,,,,uint128 _liquidity,,,,) = nonfungiblePositionManager.positions(_poolNftId);
    
        totalLiquidityAtStateForNft[_nftId][statesCounter] = _liquidity; 

        // totalLiquidityAtStateForNft[_nftId][statesCounter] += _liquidityAdded; 
        liquidityLastStateUpdate[_nftId] = statesCounter;

        uint userNft = positionsNFT.getUserNftPerPool(msg.sender, _nftId);
        positionsNFT.updateLiquidityForUser(userNft, _liquidityAdded, statesCounter);
        

        statesIdsForNft[_nftId][totalStatesForNft[_nftId]] = statesCounter;
        totalStatesForNft[_nftId]++;

        statesCounter++ ;
        liquidityLastDepositTime[userNft] = block.timestamp;
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
        
        uint _poolNftId = poolNftIds[_token0][_token1][_fee];
        uint _poolOriginalNftId = originalPoolNftIds[_token0][_token1][_fee];
        uint _userNftId = positionsNFT.getUserNftPerPool(msg.sender, _poolOriginalNftId);
        require(liquidityLastDepositTime[_userNftId] < block.timestamp + liquidityLockTime, "liquidity locked !");

        uint lastLiquidityUpdateStateForPosition = positionsNFT.totalStatesForPosition(_userNftId);
        uint userPositionLastUpdateState = positionsNFT.getStatesIdsForPosition(_userNftId, lastLiquidityUpdateStateForPosition);
        uint128 _userLiquidity = positionsNFT.getLiquidityForUserInPoolAtState(_userNftId, userPositionLastUpdateState);
     
        uint128 _liquidityToRemove = _userLiquidity * _purcentage / 100;

        uint _amount0Min = 0; 
        uint _amount1Min = 0; 

        DecreaseLiquidityParams memory decreaseLiquidityParams;
        decreaseLiquidityParams = DecreaseLiquidityParams(
                    _poolNftId, 
                    _liquidityToRemove, 
                    _amount0Min, 
                    _amount1Min, 
                    block.timestamp + deadline); 

        ERC20 token0 = ERC20(_token0);
        ERC20 token1 = ERC20(_token1);
        (,,,,,,,,,,uint128 tokensOwed0_before,uint128 tokensOwed1_before) = nonfungiblePositionManager.positions(_poolNftId);

        nonfungiblePositionManager.decreaseLiquidity(decreaseLiquidityParams);

        (,,,,,,,,,,uint128 tokensOwed0_after,uint128 tokensOwed1_after) = nonfungiblePositionManager.positions(_poolNftId);

        collect(_token0, _token1, _fee, tokensOwed0_after - tokensOwed0_before, tokensOwed1_after - tokensOwed1_before);

        (,,,,,,,uint128 _liquidity,,,,) = nonfungiblePositionManager.positions(_poolNftId);
        
        uint _nftId = originalPoolNftIds[_token0][_token1][_fee];
        totalLiquidityAtStateForNft[_nftId][statesCounter] = _liquidity; 

        if(_notYetpdated){
            
            liquidityLastStateUpdate[_nftId] = statesCounter;

            positionsNFT.updateLiquidityForUser(_nftId, _userLiquidity - _liquidityToRemove, statesCounter);
            
            statesIdsForNft[_poolOriginalNftId][totalStatesForNft[_nftId]] = statesCounter;
            totalStatesForNft[_poolOriginalNftId]++;

            statesCounter++;
        }
   
    }
    
    /// @notice returns the pending rewards for a user in a given pool
    /// @dev Public function
    /// @param _token0 The first token of the liquidity pool pair
    /// @param _token1 The second token of the liquidity pool pair
    /// @param _fee The desired fee for the pool  
    function getPendingrewardForPosition(address _token0, address _token1, uint _fee) view public returns (uint reward0, uint reward1){
        uint _originalNftId = originalPoolNftIds[_token0][_token1][_fee]; // get first pool nft id 
        uint _poolNftId = poolNftIds [_token0][_token1][_fee]; // get first pool nft id 
        uint _userPositionNft = positionsNFT.getUserNftPerPool(msg.sender, _originalNftId);
        (,,,,,,,uint128 poolLiquidity,,,uint128 tokensOwed0,uint128 tokensOwed1) = nonfungiblePositionManager.positions(_poolNftId);

        uint totalStatesForPosition = positionsNFT.totalStatesForPosition(_userPositionNft);

        uint corresponginPositionNftState = positionsNFT.getStatesIdsForPosition(_userPositionNft, totalStatesForPosition);

        uint128 liquidityAtLastStateForPosition = positionsNFT.getLiquidityForUserInPoolAtState(_userPositionNft, corresponginPositionNftState);
        uint _lastClaimState = positionsNFT.lastClaimForPosition(_userPositionNft);

        uint128 pending_reward0 = tokensOwed0;
        uint128 pending_reward1 = tokensOwed1;

        uint _rewardToken0;
        uint _rewardToken1;
        
        uint _maxStateForNft = totalStatesForNft[_originalNftId];
        _maxStateForNft = _maxStateForNft > 0 ? _maxStateForNft : 1;
        uint _maxStateIdForNft = statesIdsForNft[_originalNftId][_maxStateForNft - 1]; // ? -1 because statesCounter starts at 1, and statesIdsForNft starts at 0
     
        for(uint _state = _lastClaimState; _state <= _maxStateIdForNft ; _state++){

            uint _correspondingNftState = statesIdsForNft[_originalNftId][_state];
            uint128 poolLiquidityAtState = totalLiquidityAtStateForNft[_originalNftId][_correspondingNftState];
            if(poolLiquidityAtState > 0){
                _rewardToken0 += uint256(liquidityAtLastStateForPosition) * uint256(rewardAtStateForNftToken0[_originalNftId][_correspondingNftState])/uint256(poolLiquidityAtState);               
                _rewardToken1 += liquidityAtLastStateForPosition * rewardAtStateForNftToken1[_originalNftId][_correspondingNftState] / poolLiquidityAtState;
            }
        }

        reward0 = _rewardToken0;
        reward1 = _rewardToken1;
   
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
        uint _originalNftId = originalPoolNftIds[_token0][_token1][_fee]; // get first pool nft id 
        uint _poolNftId = poolNftIds [_token0][_token1][_fee]; // get first pool nft id 
        uint _userPositionNft = positionsNFT.getUserNftPerPool(msg.sender, _originalNftId);

        CollectParams memory collectParams;

        ERC20 token0 = ERC20(_token0);
        ERC20 token1 = ERC20(_token1);

        uint oldBalanceToken0 = token0.balanceOf(address(this));
        uint oldBalanceToken1 = token1.balanceOf(address(this));
        (,,,,,,,uint128 poolLiquidity,,,uint128 tokensOwed0,uint128 tokensOwed1) = nonfungiblePositionManager.positions(_poolNftId);
        collectParams = CollectParams(
                    _poolNftId, 
                    address(this), 
                    max_collect, 
                    max_collect); 
        nonfungiblePositionManager.collect(collectParams);

        uint newBalanceToken0 = token0.balanceOf(address(this));
        uint newBalanceToken1 = token1.balanceOf(address(this));

        uint new_reward0 = newBalanceToken0 - oldBalanceToken0 - _tokensOwed0;
        uint new_reward1 = newBalanceToken1 - oldBalanceToken1 - _tokensOwed1;

        totalRewards[_token0] = totalRewards[_token0] + new_reward0;

        totalRewards[_token1] = totalRewards[_token1] + new_reward1;

        totalRewardForNftToken0[_originalNftId] += new_reward0;
        totalRewardForNftToken1[_originalNftId] += new_reward1;

        rewardAtStateForNftToken0[_originalNftId][statesCounter] = new_reward0;
        rewardAtStateForNftToken1[_originalNftId][statesCounter]= new_reward1;

        // totalLiquidityAtStateForNft[_originalNftId][statesCounter] = poolLiquidity;

        uint totalStatesForPosition = positionsNFT.totalStatesForPosition(_userPositionNft);

        uint128 liquidityAtLastStateForPosition = positionsNFT.getLiquidityForUserInPoolAtState(_userPositionNft, totalStatesForPosition - 1);

        uint _lastClaimState = positionsNFT.lastClaimForPosition(_userPositionNft);

        (uint _rewardToken0, uint _rewardToken1) = getPendingrewardForPosition(_token0, _token1, _fee);

        totalRewardPaidForNftToken0[_originalNftId] += _rewardToken0;
        totalRewardPaidForNftToken1[_originalNftId] += _rewardToken1;
        bool claimed = false;
        if (_rewardToken0 + _tokensOwed0 > 0){
            // send maximum the smart contract balance
            token0.transfer(msg.sender, _rewardToken0 + _tokensOwed0);
            claimed = true;
        }
        if (_rewardToken1 + _tokensOwed1 > 0){
            token1.transfer(msg.sender, _rewardToken1 + _tokensOwed1);
            claimed = true;
        }
        if(claimed){
            positionsNFT.updateLastClaimForPosition(_userPositionNft, statesCounter);
        }
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
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(_tickLower); //A sqrt price representing the first tick boundary
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(_tickUpper); //A sqrt price representing the second tick boundary
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        uint128 liquidity = toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
        amount1 = FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
        return amount1;
    }

    // function checkTick(uint256 _tick) public view returns (uint160){
    //     return TickMath.getSqrtRatioAtTick(int24(int256(_tick)));
    // }

    function checkTick(int24 _tick)public view returns (uint160){
        return TickMath.getSqrtRatioAtTick(_tick);
    }

    function computeTick(uint160 sqrtPriceX96) public view returns (int24){
        return -887220;
        return TickMath.getTickAtSqrtRatio(sqrtPriceX96);
    }

    // function getPrice(address tokenIn, address tokenOut)
    // external
    // view
    // returns (uint256 price)
    // {
    //     IUniswapV3Pool pool = IUniswapV3Pool(factory.getPool(tokenIn, tokenOut, FEE);
    //     (uint160 sqrtPriceX96,,,,,,) =  pool.slot0();
    //     return uint(sqrtPriceX96).mul(uint(sqrtPriceX96)).mul(1e18) >> (96 * 2);
    // }

    //   function sqrtPriceX96ToUint(uint160 sqrtPriceX96, uint8 decimalsToken0)
    //     internal
    //     pure
    //     returns (uint256)
    //   {
    //     uint256 numerator1 = uint256(sqrtPriceX96) * uint256(sqrtPriceX96);
    //     uint256 numerator2 = 10**decimalsToken0;
    //     return FullMath.mulDiv(numerator1, numerator2, 1 << 192);
    //   }

    // function getQuoteFromSqrtRatioX96(
    //     uint160 sqrtRatioX96, // same as sqrtPriceX96
    //     uint128 baseAmount,
    //     bool inverse
    // ) internal pure returns (uint256 quoteAmount) {
    //     // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
    //     if (sqrtRatioX96 <= type(uint128).max) {
    //         uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
    //         quoteAmount = !inverse
    //             ? FullMath.mulDiv(ratioX192, baseAmount, 1 << 192)
    //             : FullMath.mulDiv(1 << 192, baseAmount, ratioX192);
    //     } else {
    //         uint256 ratioX128 = FullMath.mulDiv(
    //             sqrtRatioX96,
    //             sqrtRatioX96,
    //             1 << 64
    //         );
    //         quoteAmount = !inverse
    //             ? FullMath.mulDiv(ratioX128, baseAmount, 1 << 128)
    //             : FullMath.mulDiv(1 << 128, baseAmount, ratioX128);
    //     }
    // }

    function _sqrt(uint _x) internal pure returns(uint y) {
        uint z = (_x + 1) / 2;
        y = _x;
        while (z < y) {
            y = z;
            z = (_x / z + z) / 2;
        }
    }
    
    function getSqrtPriceX96(uint priceA, uint priceB) public view returns (uint) {
        uint ratioX192 = (priceA << 192) / priceB;
        return _sqrt(ratioX192);
    }

    // function sqrtPriceX96ToUint(uint160 sqrtPriceX96, uint8 decimalsToken0)
    // internal
    // pure
    // returns (uint256)
    // {
    //     uint256 numerator1 = uint256(sqrtPriceX96) * uint256(sqrtPriceX96);
    //     uint256 numerator2 = 10**decimalsToken0;
    //     return FullMath.mulDiv(numerator1, numerator2, 1 << 192);
    // }
    
    // sqrtPriceX96 = sqrt(price) * 2 ** 96
    // # divide both sides by 2 ** 96
    // sqrtPriceX96 / (2 ** 96) = sqrt(price)
    // # square both sides
    // (sqrtPriceX96 / (2 ** 96)) ** 2 = price
    // # expand the squared fraction
    // (sqrtPriceX96 ** 2) / ((2 ** 96) ** 2)  = price
    // # multiply the exponents in the denominator to get the final expression
    // sqrtRatioX96 ** 2 / 2 ** 192 = price

    /// @dev Rounds tick down towards negative infinity so that it's a multiple
    /// of `tickSpacing`.
    function _floor(int24 tick, int24 tickSpacing) internal view returns (int24) {
        int24 compressed = tick / tickSpacing;
        if (tick < 0 && tick % tickSpacing != 0) compressed--;
        return compressed * tickSpacing;
    }

}