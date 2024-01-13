//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// import {PRBMathUD60x18} from "@prb/math/contracts/PRBMathUD60x18.sol";

// import "prb-math/contracts/PRBMathUD60x18.sol";

import './FullMath.sol';
import './FixedPoint96.sol';
import './TickMath.sol';
import './ISwapRouter.sol';
import {SafeCast} from './SafeCast.sol';
import {UnsafeMath} from './UnsafeMath.sol';

struct IncreaseLiquidityParams {
    uint256 tokenId;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
}

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

contract Token is ERC20 ("Test Token", "TT"){

}
contract PositionsNFT is ERC721, Pausable, AccessControl {
    using Counters for Counters.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;

    mapping(address => mapping(uint=>uint)) public userNftPerPool;

    mapping(uint=>mapping(uint=>uint128)) public liquidityForUserInPoolAtState; // nft --> state --> liquidity 
    
    mapping(uint => mapping(uint => uint)) public statesIdsForPosition;

    mapping(uint => uint) public totalStatesForPosition;

    mapping(uint => uint) public lastClaimForPosition;

    mapping(uint => uint) public totalClaimedforPositionToken0;
    mapping(uint => uint) public totalClaimedforPositionToken1;

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

    function updateStatesIdsForPosition(uint positionNftId, uint _state)public onlyRole(MINTER_ROLE) {
        totalStatesForPosition[positionNftId]++;
        statesIdsForPosition[positionNftId][totalStatesForPosition[positionNftId]] = _state;

    }

    // function incrementTotalStatesForUserPosition(uint positionNftId)public onlyRole(MINTER_ROLE) {
    //     return;
    //     // totalStatesForPosition[positionNftId]++;
    // }

    function updateLastClaimForPosition(uint _positionNftId, uint _state)public onlyRole(MINTER_ROLE) {
        lastClaimForPosition[_positionNftId] = _state;
    }

    function updateTotalClaimForPosition(uint _positionNftId, uint _newClaim0, uint _newClaim1)public onlyRole(MINTER_ROLE) {
        totalClaimedforPositionToken0[_positionNftId] += _newClaim0;
        totalClaimedforPositionToken1[_positionNftId] += _newClaim1;
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
    uint private slippageToken0 = 500; // => 5 % 
    uint private slippageToken1 = 500; // => 5 % 
    // quotitnt for slippage calculation
    uint private quotient = 10000; 
    // big number used to collect all the rewards from the pool in a given transaction 
    uint128 private max_collect = 1e27; 
    uint public liquidityLockTime = 3600 * 24 * 30; // one month liquidty lock time 
    // track last deposit time for each user position, to be able to enforce the lock time 
    mapping(uint => uint) public liquidityLastDepositTime; // position nft => timestamp 
    // Position NFT contract, to generate and track users positions
    PositionsNFT private positionsNFT; 
    // Uniswap v3 position manager
    NonfungiblePositionManager private nonfungiblePositionManager; 
    // Uniswap v3 router for internal swaps
    ISwapRouter private iSwapRouter;
    // IQuoter public quoter;
    // The current pool nft id
    mapping(address => mapping(address => mapping(uint => uint))) public poolNftIds; // [token0][token1][fee] 
    // The first nft id to be minted for a given pool configuration (token0, token1, fee)
    mapping(address => mapping(address => mapping(uint => uint))) public originalPoolNftIds; // [token0][token1][fee] = Original nft Id 
    mapping(address => uint) public totalRewards; 
    mapping(uint => mapping(uint => uint)) public poolLiquidityChangeAmount; // pool nft => state => coef /10000 to track liquidity amount change durint rebalance in a given state
    mapping(uint => mapping(uint => uint)) public poolLiquidityChangeDirection; // 1 for decrease, 2 for increase
    // Events
    // event NftMinted(uint tokenId, uint liquidityInPool, uint amount0, uint amount1);
    // event IncreaseLiquidity(uint128 liquidity, uint _amount0, uint _amount1, uint uniNft, uint yfNft);
    uint public public_balance0;
    uint public public_balance1;
    uint public public_amount0;
    uint public public_amount1;
    uint public public_adjustedAmount0;
    uint public public_adjustedAmount1;
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
 
        tickLower = -24000;
        tickUpper = -23040;
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
    function setTicks(int24 _tickLower, int24 _tickUpper) internal {
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(_tickLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(_tickUpper);
        tickLower = _tickLower;
        tickUpper = _tickUpper;
    }

    function withdraw(address _token) public onlyOwner{
        ERC20 token = ERC20(_token);
        uint _balance = token.balanceOf(address(this));
        token.transfer(msg.sender, _balance);
    }

    function setRates(address _token0, address _token1, uint24 _fee, int24 _ticksUp, int24 _ticksDown) internal  {
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

    function sqrtRatios(address _token0, address _token1, uint24 _fee) 
    internal returns (uint160 sqrtRatioX96, uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint160 sqrtPriceX96){
        address _factoryAddress = nonfungiblePositionManager.factory();
        Factory _factory = Factory(_factoryAddress);
        address _poolAddress = _factory.getPool(_token0, _token1, _fee);
        Pool pool = Pool(_poolAddress);
        int24 tick;
        (sqrtPriceX96, tick, , , , , ) = pool.slot0();
        sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);
        sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);
        return (sqrtRatioX96, sqrtRatioAX96, sqrtRatioBX96, sqrtPriceX96);
    }

    function liquidityAmounts(
    uint _amount0, uint _amount1, 
    uint160 _sqrtRatioX96, uint160 _sqrtPriceX96, 
    uint160 _sqrtRatioAX96, uint160 _sqrtRatioBX96) 
    internal 
    returns (uint _adjustedAmount0, uint _adjustedAmount1){
        
        uint128 _liquidityForAmounts = getLiquidityForAmounts(_sqrtRatioX96, _sqrtRatioAX96, _sqrtRatioBX96, _amount0, _amount1);

        _adjustedAmount0 = getAmount0Delta(
                    _sqrtPriceX96,
                    _sqrtRatioBX96,
                    _liquidityForAmounts,
                    true
                );
        _adjustedAmount1 = getAmount1Delta(
                    _sqrtRatioAX96,
                    _sqrtPriceX96,
                    _liquidityForAmounts,
                    true
                );
        return (_adjustedAmount0, _adjustedAmount1);
    }

    /// @notice external function 
    /// Allow o update the ticks of a given position,
    /// you should call setTicks before to update ticks values to the new price range
    /// @dev external method to be called only by the owner 
    /// @param _token0 The first token of the liquidity pool pair
    /// @param _token1 The second token of the liquidity pool pair
    /// @param _fee The desired fee for the pool 
    function updatePosition(address _token0, address _token1, uint24 _fee, int24 _ticksUp, int24 _ticksDown) external onlyOwner {
        // initialise the pool tokens contracts
        ERC20 token0 = ERC20(_token0);
        ERC20 token1 = ERC20(_token1);

        uint oldStateCounter = statesCounter;
        
        // before updating the position, we first claim all the pending rewards for both tokens
        collect(_token0, _token1, _fee, 0, 0, true);
        
        // decrease 100% of the liquidity. 'false' to indicate that liquidity sates have not been updated yet 
        (uint _amount0, uint _amount1) = decreaseLiquidity(_token0, _token1, _fee, 100, true);
        
        // reset the nft id for the pool to be able to store the new nft id that will be minted 
        poolNftIds[_token0][_token1][_fee] = 0;

        // apply the slippage params 
        uint _amount0Min = 0 ; //newBalanceToken0 - newBalanceToken0 * slippageToken0 / quotient;
        uint _amount1Min = 0 ; //newBalanceToken1- newBalanceToken1 * slippageToken1 / quotient;

        setRates(_token0, _token1, _fee, _ticksUp, _ticksDown);
        
        (uint160 sqrtRatioX96, uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint160 sqrtPriceX96) = sqrtRatios(_token0, _token1, _fee);

        (uint _adjustedAmount0, uint _adjustedAmount1) = liquidityAmounts(_amount0, _amount1, sqrtRatioX96, sqrtPriceX96, sqrtRatioAX96, sqrtRatioBX96);

        public_amount0 = _adjustedAmount0;
        public_amount1 = _adjustedAmount1;

        if (_adjustedAmount0 < 98*_amount0/100){
            _adjustedAmount1 += swapExess(_token1, _token0, _fee, (_amount0 - _adjustedAmount0)/2);
            _adjustedAmount0 = _adjustedAmount0 + (_amount0 - _adjustedAmount0)/2;

        }else if (_adjustedAmount1 < 98*_amount1/100){
            _adjustedAmount0 += swapExess(_token1, _token0, _fee,(_amount1 - _adjustedAmount1)/2) ;
            _adjustedAmount1 = _adjustedAmount1 + (_amount1 - _adjustedAmount1)/2;
        }

        // approve the uniswap v3 position manager to spend the tokens to mint the position 
        token0.approve(address(nonfungiblePositionManager), _adjustedAmount0);
        token1.approve(address(nonfungiblePositionManager), _adjustedAmount1);
        uint _balance0 = token0.balanceOf(address(this));
        uint _balance1 = token1.balanceOf(address(this));
        public_balance0 = _balance0;
        public_balance1 = _balance1;
        public_adjustedAmount0 = _adjustedAmount0;
        public_adjustedAmount1 = _adjustedAmount1;
        uint128 _newLiquidity = mintUni3Nft(_token0, _token1, _fee, tickLower, tickUpper, _adjustedAmount0, _adjustedAmount1, _amount0Min, _amount1Min);
    }

    function updateLiquidityVariables(uint _originalNftId, 
                                      uint128 _newLiquidity, 
                                      bool _rebalance) internal {
        totalLiquidityAtStateForNft[_originalNftId][statesCounter] = _newLiquidity;
        if (_rebalance) return;
        uint _userNftId = positionsNFT.getUserNftPerPool(msg.sender, _originalNftId);
        liquidityLastDepositTime[_userNftId] = block.timestamp;
        uint128 _previousLiq = positionsNFT.getLiquidityForUserInPoolAtState(_userNftId, statesCounter - 1);

        if(_previousLiq > _newLiquidity){
            positionsNFT.updateLiquidityForUser(_userNftId, 
            _previousLiq - (_previousLiq - _newLiquidity), 
            statesCounter);
        } else {
            positionsNFT.updateLiquidityForUser(_userNftId, 
            _previousLiq + (_newLiquidity - _previousLiq), 
            statesCounter);
        }
    }

    function updateStateCounters(uint _originalNftId, uint _userNftId) internal {
        totalStatesForNft[_originalNftId]++;
        statesCounter++;
        statesIdsForNft[_originalNftId][totalStatesForNft[_originalNftId]] = statesCounter;
        liquidityLastStateUpdate[_originalNftId] = statesCounter;
        if(_userNftId == 0) return; // if rebalance no user nft to update
        uint positionNftId = positionsNFT.getUserNftPerPool(msg.sender, _originalNftId);
        positionsNFT.updateStatesIdsForPosition(positionNftId, statesCounter);
        
    }

    function updateRewardVariables(uint _originalNftId, uint _rewardAmount0, uint _rewardAmount1) internal{
        rewardAtStateForNftToken0[_originalNftId][statesCounter] = _rewardAmount0;
        rewardAtStateForNftToken1[_originalNftId][statesCounter] = _rewardAmount1;
        totalRewardForNftToken0[_originalNftId] += _rewardAmount0;
        totalRewardForNftToken1[_originalNftId] += _rewardAmount1;
    }

    function updateClaimVariables(uint _originalNftId, uint _claimAmount0, uint _claimAmount1) internal {
        totalRewardPaidForNftToken0[_originalNftId] += _claimAmount0;
        totalRewardPaidForNftToken1[_originalNftId] += _claimAmount1;
        uint _positionNftId = positionsNFT.getUserNftPerPool(msg.sender, _originalNftId);
        positionsNFT.updateLastClaimForPosition(_positionNftId, statesCounter);
        positionsNFT.updateTotalClaimForPosition(_positionNftId, _claimAmount0, _claimAmount1);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
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
        
        (uint256 tokenId, 
        uint128 _liquidity , 
        uint __amount0, 
        uint __amount1) = nonfungiblePositionManager.mint(mintParams);

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
        uint _originalNftId = originalPoolNftIds[_token0][_token1][_fee];
        (,,,,,,,uint128 oldLiquidity,,,,) = nonfungiblePositionManager.positions(tokenId);

        IncreaseLiquidityParams memory increaseLiquidityParams; 
        increaseLiquidityParams = IncreaseLiquidityParams( 
                    tokenId, 
                    _amount0, 
                    _amount1, 
                    _amount0Min, 
                    _amount1Min, 
                    block.timestamp + deadline); 
        (uint128 _addedLiquidity, uint amount0, uint amount1) = nonfungiblePositionManager.increaseLiquidity(increaseLiquidityParams);
        uint128 _newLiquidity = oldLiquidity + _addedLiquidity;
        uint userPositionNft = positionsNFT.getUserNftPerPool(msg.sender, _originalNftId);

        if(userPositionNft == 0 && msg.sender != owner){
            positionsNFT.safeMint(_originalNftId, msg.sender, _addedLiquidity, statesCounter + 1);
            userPositionNft = positionsNFT.getUserNftPerPool(msg.sender, _originalNftId);
        }

        if (msg.sender == owner){ // means rebalance
            updateStateCounters(_originalNftId, 0);
            updateLiquidityVariables(_originalNftId, _newLiquidity, true);
        } else{
            updateStateCounters(_originalNftId, userPositionNft);
            updateLiquidityVariables(_originalNftId, _newLiquidity, false);
        }
    
        return _newLiquidity;
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
    uint _amount1,
    int24 _ticksUp,
    int24 _ticksDown
    ) public {
        ERC20 token0 = ERC20(_token0);
        ERC20 token1 = ERC20(_token1); 
        
        uint oldBalanceToken0 = token0.balanceOf(address(this));
        uint oldBalanceToken1 = token1.balanceOf(address(this));
        
        setRates(_token0, _token1, _fee, _ticksUp, _ticksDown);

        (uint160 sqrtRatioX96, uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint160 sqrtPriceX96) = sqrtRatios(_token0, _token1, _fee);

        (_amount0, _amount1) = liquidityAmounts(_amount0, _amount1, sqrtRatioX96, sqrtPriceX96, sqrtRatioAX96, sqrtRatioBX96);

        token0.transferFrom(msg.sender, address(this), _amount0);
        token1.transferFrom(msg.sender, address(this), _amount1);
        token0.approve(address(nonfungiblePositionManager), _amount0);
        token1.approve(address(nonfungiblePositionManager), _amount1);
        
        ISwapRouter.ExactInputSingleParams memory _exactInputSingleParams;
        uint _amount0Min = 0;
        uint _amount1Min = 0;
        uint128 _newLiquidity;

        if(poolNftIds[_token0][_token1][_fee] == 0 && poolNftIds[_token1][_token0][_fee] == 0)
        {
            _newLiquidity = mintUni3Nft(_token0, _token1, _fee, tickLower, tickUpper, _amount0, _amount1, _amount0Min, _amount1Min);
            uint _originalNftId = originalPoolNftIds[_token0][_token1][_fee];
            uint _userNftId = positionsNFT.getUserNftPerPool(msg.sender, _originalNftId);

            updateStateCounters(_originalNftId, _userNftId);
            updateLiquidityVariables(_originalNftId, _newLiquidity, false);
        }else{
            uint _originalNftId = originalPoolNftIds[_token0][_token1][_fee];
            uint _userNftId = positionsNFT.getUserNftPerPool(msg.sender, _originalNftId);

            updateStateCounters(_originalNftId, _userNftId); // not correct, what if no nft id so far ? 
            
            collect(_token0, _token1, _fee, 0, 0, false);
            _newLiquidity = increaseUni3Nft(_token0, _token1, _fee, _amount0, _amount1, _amount0Min, _amount1Min);
        }  
    }

    function swapExess(address _token0, address _token1, uint24 _fee, uint half) internal returns (uint){
        ERC20 token0 = ERC20(_token0);
        ERC20 token1 = ERC20(_token1); 
        ISwapRouter.ExactInputSingleParams memory _exactInputSingleParams;
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
        return amountOut; 
    }

    /// @notice Allow user to withdraw liquidity from a given position, 
    /// It will burn the liquidity and send the tokens to the depositer
    /// @dev Public function
    /// @param _token0 The first token of the liquidity pool pair
    /// @param _token1 The second token of the liquidity pool pair
    /// @param _fee The desired fee for the pool  
    /// @param _purcentage desired % of the users liquidity to be removed
    /// @param _rebalance always set to true for external calls, it is set to false only internally
    function decreaseLiquidity(address _token0, address _token1, uint24 _fee, uint128 _purcentage, bool _rebalance) public returns (uint, uint) { 
        uint _poolNftId = poolNftIds[_token0][_token1][_fee];
        uint _originalNftId = originalPoolNftIds[_token0][_token1][_fee];
        
        uint _userNftId = positionsNFT.getUserNftPerPool(msg.sender, _originalNftId);
        require(liquidityLastDepositTime[_userNftId] < block.timestamp + liquidityLockTime, "liquidity locked !");
        
        uint lastLiquidityUpdateStateForPosition = positionsNFT.totalStatesForPosition(_userNftId);
        uint userPositionLastUpdateState = positionsNFT.getStatesIdsForPosition(_userNftId, lastLiquidityUpdateStateForPosition);
        uint128 _userLiquidity = positionsNFT.getLiquidityForUserInPoolAtState(_userNftId, userPositionLastUpdateState);

        uint128 _liquidityToRemove = _userLiquidity * _purcentage / 100;

        uint _amount0Min = 0; uint _amount1Min = 0;

        DecreaseLiquidityParams memory decreaseLiquidityParams;
        decreaseLiquidityParams = DecreaseLiquidityParams(
                    _poolNftId, 
                    _liquidityToRemove, 
                    _amount0Min, 
                    _amount1Min, 
                    block.timestamp + deadline); 
        (,,,,,,,uint128 _liquidity,,,uint128 _totalPendingRewards0, uint128 _totalPendingRewards1) = nonfungiblePositionManager.positions(_poolNftId);

        // returns the liquidity amounts
        (uint _amount0, uint _amount1) = nonfungiblePositionManager.decreaseLiquidity(decreaseLiquidityParams);
        _liquidity = _liquidity - _liquidityToRemove;

        // collects only the rewards, so needs the the liquidity tokens amounts 
        collect(_token0, _token1, _fee, _totalPendingRewards0, _totalPendingRewards1, _rebalance);

        updateStateCounters(_originalNftId, _userNftId);
        updateLiquidityVariables(_originalNftId, _liquidity, _rebalance);
        return (_amount0, _amount1);
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

        uint totalStatesForPosition = positionsNFT.totalStatesForPosition(_userPositionNft);

        uint corresponginPositionNftState = positionsNFT.getStatesIdsForPosition(_userPositionNft, totalStatesForPosition);

        uint128 liquidityAtLastStateForPosition = positionsNFT.getLiquidityForUserInPoolAtState(_userPositionNft, corresponginPositionNftState);
        uint _lastClaimState = positionsNFT.lastClaimForPosition(_userPositionNft);

        uint _rewardToken0;
        uint _rewardToken1;
        
        uint _maxStateForNft = totalStatesForNft[_originalNftId];
        _maxStateForNft = _maxStateForNft > 0 ? _maxStateForNft : 1;
        uint _maxStateIdForNft = statesIdsForNft[_originalNftId][_maxStateForNft - 1]; // ? -1 because statesCounter starts at 1, and statesIdsForNft starts at 0
     
        for(uint _state = _lastClaimState; _state <= _maxStateIdForNft ; _state++){
            // Not enough ! what about rewards collected outside of position traced states ?
            uint _correspondingNftState = statesIdsForNft[_originalNftId][_state];
            uint128 poolLiquidityAtState = totalLiquidityAtStateForNft[_originalNftId][_correspondingNftState];
            if(poolLiquidityAtState > 0){
                _rewardToken0 += uint256(liquidityAtLastStateForPosition) * 
                uint256(rewardAtStateForNftToken0[_originalNftId][_correspondingNftState])/uint256(poolLiquidityAtState);               
                _rewardToken1 += liquidityAtLastStateForPosition * 
                rewardAtStateForNftToken1[_originalNftId][_correspondingNftState] / poolLiquidityAtState;
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
    /// @param _totalPendingRewards0 external caller should enter 0, a positive value is used in case of decreaseliquidity internal call
    /// @param _totalPendingRewards1 external caller should enter 0, a positive value is used in case of decreaseliquidity internal call
    /// @param _rebalance if rebalance is to true, means keep rewards and tokens in the smart contract, if false send to the caller
    function collect(address _token0, 
    address _token1, 
    uint _fee, 
    uint128 _totalPendingRewards0, 
    uint128 _totalPendingRewards1, 
    bool _rebalance) public {
        ERC20 token0 = ERC20(_token0);
        ERC20 token1 = ERC20(_token1);
        uint _originalNftId = originalPoolNftIds[_token0][_token1][_fee]; // get first pool nft id 
        uint _poolNftId = poolNftIds [_token0][_token1][_fee]; // get first pool nft id 
        uint _userPositionNft = positionsNFT.getUserNftPerPool(msg.sender, _originalNftId);

        CollectParams memory collectParams;

        collectParams = CollectParams(
                    _poolNftId, 
                    address(this), 
                    max_collect, 
                    max_collect); 
        (uint _totalCollected0, uint _totalCollected1) = nonfungiblePositionManager.collect(collectParams);

        updateRewardVariables(_originalNftId, _totalPendingRewards0, _totalPendingRewards1);

        (uint _positionRewardToken0, uint _positionRewardToken1) = getPendingrewardForPosition(_token0, _token1, _fee);

        if (_rebalance){
            return ;
        }
        if (_totalCollected0 + _positionRewardToken0 > _totalPendingRewards0){
            // (_totalCollected0 - _totalReward0) corresponds to removed liquidity of token 0, idem fotr token 1 
            token0.transfer(msg.sender, _totalCollected0 + _positionRewardToken0 - _totalPendingRewards0); 
        }
        if ( _totalCollected1 + _positionRewardToken1 > _totalPendingRewards1){
            token0.transfer(msg.sender, _totalCollected1 + _positionRewardToken1 - _totalPendingRewards1);
        }
        updateClaimVariables(_originalNftId, _positionRewardToken0, _positionRewardToken1);
    }

    /// @dev Rounds tick down towards negative infinity so that it's a multiple
    /// of `tickSpacing`.
    function _floor(int24 tick, int24 tickSpacing) internal view returns (int24) {
        int24 compressed = tick / tickSpacing;
        if (tick < 0 && tick % tickSpacing != 0) compressed--;
        return compressed * tickSpacing;
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Gets the amount0 delta between two prices
    /// @dev Calculates liquidity / sqrt(lower) - liquidity / sqrt(upper),
    /// i.e. liquidity * (sqrt(upper) - sqrt(lower)) / (sqrt(upper) * sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up or down
    /// @return amount0 Amount of token0 required to cover a position of size liquidity between the two passed prices
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) public pure returns (uint256 amount0) {
        unchecked {
            if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

            uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;
            uint256 numerator2 = sqrtRatioBX96 - sqrtRatioAX96;

            require(sqrtRatioAX96 > 0);

            return
                roundUp
                    ? UnsafeMath.divRoundingUp(
                        FullMath.mulDivRoundingUp(numerator1, numerator2, sqrtRatioBX96),
                        sqrtRatioAX96
                    )
                    : FullMath.mulDiv(numerator1, numerator2, sqrtRatioBX96) / sqrtRatioAX96;
        }
    }

    /// @notice Gets the amount1 delta between two prices
    /// @dev Calculates liquidity * (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up, or down
    /// @return amount1 Amount of token1 required to cover a position of size liquidity between the two passed prices
    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) public pure returns (uint256 amount1) {
        unchecked {
            if (    sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

            return
                roundUp
                    ? FullMath.mulDivRoundingUp(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96)
                    : FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
        }
    }
}