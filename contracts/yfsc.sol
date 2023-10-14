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

    mapping(uint=>mapping(uint=>uint128)) public liquidityForUserInPoolAtState; // nft --> state --> liquidity 

    mapping(uint => mapping(uint => uint)) public statesIdsForPosition;

    mapping(uint => uint) public totalStatesForPosition;
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

    function updateLiquidityForUser(uint positionNftId, uint128 _liquidity,uint _state)public onlyRole(MINTER_ROLE) {
        liquidityForUserInPoolAtState[positionNftId][_state] = _liquidity;
        totalStatesForPosition[positionNftId]++;
        statesIdsForPosition[positionNftId][totalStatesForPosition[positionNftId]] = _state;
    }

    function getLiquidityForUserInPoolAtState(uint _userPositionNft, uint _state) public returns(uint128 liquidity){
        liquidity = liquidityForUserInPoolAtState[_userPositionNft][_state];
        return liquidity;
    }

    function getStatesIdsForPosition(uint _userPositionNft, uint _stateId) public returns(uint id){
        id = liquidityForUserInPoolAtState[_userPositionNft][_stateId];
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

    /// fees distribution 
    uint public statesCounter; 

    mapping(uint=>uint) public liquidityLastStateUpdate; // nft --> last State Update for liquidity for Uni3 NFT

    mapping(uint => mapping(uint=>uint)) public liquidityStatesPerNft; // nft --> state --> amount 

    /// Original uniswapNFT => total reward at statesCounter (for token0 and token1) 
    mapping(uint => mapping(uint => uint)) public totalRewardReceivedAtStateForToken0; 
    mapping(uint => mapping(uint => uint)) public totalRewardReceivedAtStateForToken1; 
  
    mapping(uint => mapping(uint => uint128)) public totalLiquidityAtStateForNft; 

    int24 public tickLower = -27060; // -21960
    int24 public tickUpper = -25680; // -20820
    uint public deadline = 600;

    uint public slippageToken0 = 500; // => 5 %
    uint public slippageToken1 = 500; // => 5 %

    uint public quotient = 10000; 

    uint128 public max_collect = 1e27;

    uint public positionsCounter;

    uint public liquidityLockTime = 3600 * 24 * 30; // one month liquidty lock time 

    mapping(uint => uint) public liquidityLastDepositTime; // position nft => timestamp

    PositionsNFT public positionsNFT;
    NonfungiblePositionManager public nonfungiblePositionManager;

    mapping(address => mapping(address => mapping(uint => uint))) public poolNftIds; // [token0][token1][fee]
    mapping(address => mapping(address => mapping(uint => uint))) public originalPoolNftIds; // [token0][token1][fee] = Original nft Id

    mapping(address => uint) public totalRewards;

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
        ERC20 token0 = ERC20(_token0);
        ERC20 token1 = ERC20(_token1);
        uint oldStateCounter = statesCounter;

        collect(_token0, _token1, _fee);

        decreaseLiquidity(_token0, _token1, _fee, 100);

        uint newBalanceToken0 = token0.balanceOf(address(this));
        uint newBalanceToken1 = token1.balanceOf(address(this));

        uint _nftId = poolNftIds[_token0][_token1][_fee];

        poolNftIds[_token0][_token1][_fee] = 0;

        uint _amount0Min = newBalanceToken0 - newBalanceToken0 * slippageToken0 / quotient;
        uint _amount1Min = newBalanceToken1- newBalanceToken1 * slippageToken1 / quotient;

        uint _amount0 = newBalanceToken0;
        uint _amount1 = getAmount1ForAmount0(tickLower, tickUpper, _amount0);
 
        token0.approve(address(nonfungiblePositionManager), _amount0);
        token1.approve(address(nonfungiblePositionManager), _amount1);
        
        _amount0Min = 0 ; //_amount0 - _amount0 * slippageToken0 / quotient; 
        _amount1Min = 0 ; // _amount1 - _amount1 * slippageToken1 / quotient; 
        mintUni3Nft(_token0, _token1, _fee, tickLower, tickUpper, _amount0, _amount1, _amount0Min, _amount1Min);

        uint _originalPositionNft = originalPoolNftIds[_token0][_token1][_fee];

        (,,,,,,,uint128 _liquidity,,,,) = nonfungiblePositionManager.positions(_nftId);

        totalLiquidityAtStateForNft[_nftId][oldStateCounter] = _liquidity; 
        
        // handle the risidual tokens not added to liquidity because of ratio difference 
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
            
            (uint256 tokenId, uint128 _liquidity , , ) = nonfungiblePositionManager.mint(mintParams);
            originalPoolNftIds[_token0][_token1][_fee] = tokenId;
            poolNftIds[_token0][_token1][_fee] = tokenId;

            poolNftIds[_token1][_token0][_fee] = tokenId;

            positionsNFT.safeMint(tokenId, msg.sender, _liquidity, statesCounter);
    
            liquidity = _liquidity;
            return liquidity;
    }

    function increaseUni3Nft(
                                address _token0, 
                                address _token1, 
                                uint _fee, 
                                uint _amount0, 
                                uint _amount1, 
                                uint _amount0Min, 
                                uint _amount1Min) 
                            internal returns(uint128 liquidity){
        
        uint tokenId = poolNftIds[_token0][_token1][_fee] > 0 ? poolNftIds[_token0][_token1][_fee] : poolNftIds[_token1][_token0][_fee];
        uint _nftId = originalPoolNftIds[_token0][_token1][_fee];
        (,,,,,,,uint128 oldLiquidity,,,,) = nonfungiblePositionManager.positions(tokenId);
 
        ////////////////// handle rewards distribution //////////////////////
        ERC20 token0 = ERC20(_token0);
        ERC20 token1 = ERC20(_token1);
        uint balanceToken0BeforeCollection = token0.balanceOf(address(this));
        uint balanceToken1BeforeCollection = token1.balanceOf(address(this));

        collect(_token0, _token1, _fee);

        uint balanceToken0AfterCollection = token0.balanceOf(address(this));
        uint balanceToken1AfterCollection = token1.balanceOf(address(this));
        ////////////////////////////////////////////////////////////////////
        IncreaseLiquidityParams memory increaseLiquidityParams; 
        increaseLiquidityParams = IncreaseLiquidityParams( 
                    tokenId, 
                    _amount0, 
                    _amount1, 
                    _amount0Min, 
                    _amount1Min, 
                    block.timestamp + deadline); 
        (liquidity,,) = nonfungiblePositionManager.increaseLiquidity(increaseLiquidityParams);
        ///////////////// BEGIN: UPDATE LIQUIDITY MAPPINGS ////////////////////////
        totalLiquidityAtStateForNft[tokenId][statesCounter] = liquidity; 
        uint userPositionNft = positionsNFT.getUserNftPerPool(msg.sender, _nftId);
        uint128 userAddedLiquidty = liquidity - oldLiquidity;
        uint lastLiquidityUpdateStateForPosition = positionsNFT.totalStatesForPosition(userPositionNft);
        uint userPositionLastUpdateState = positionsNFT.getStatesIdsForPosition(userPositionNft, lastLiquidityUpdateStateForPosition);
        
        uint128 userOldLiquidityInPool = positionsNFT.getLiquidityForUserInPoolAtState(userPositionNft, userPositionLastUpdateState);
    
        if(positionsNFT.getUserNftPerPool(msg.sender, _nftId) == 0){
            positionsNFT.safeMint(_nftId, msg.sender, userAddedLiquidty, statesCounter);
        }else{
            positionsNFT.updateLiquidityForUser(userPositionNft, userAddedLiquidty + userOldLiquidityInPool, statesCounter);
        }
        
        ///////////////// END: UPDATE LIQUIDITY MAPPINGS ////////////////////////
        return liquidity;
    }

    /// @notice Allow user to deposit liquidity and mint corresponding NFT
    /// @dev Public function
    /// @param _token0 The first token of the liquidity pool pair
    /// @param _token1 The second token of the liquidity pool pair
    /// @param _fee The desired fee for the pool  
    /// @param _amount0 0 for _token0, 1 for _token1
    // To avoid being stuck with random erc20, bettre put weth address as _token1
    function mintNFT(
    address _token0, 
    address _token1, 
    uint24 _fee, 
    uint _amount0 
    ) public {
        ERC20 token0 = ERC20(_token0);
        ERC20 token1 = ERC20(_token1);
        uint _amount1 = getAmount1ForAmount0(tickLower, tickUpper, _amount0);
        
        token0.transferFrom(msg.sender, address(this), _amount0);
        token1.transferFrom(msg.sender, address(this), _amount1);
        token0.approve(address(nonfungiblePositionManager), _amount0);
        token1.approve(address(nonfungiblePositionManager), _amount1);
        
        uint _amount0Min = 0; // _amount0 - _amount0 * slippageToken0 / quotient;
        uint _amount1Min = 0; // _amount1- _amount1 * slippageToken1 / quotient;

        uint128 _liquidityAdded;

        if(poolNftIds[_token0][_token1][_fee] == 0 && poolNftIds[_token1][_token0][_fee] == 0)
        {
            _liquidityAdded = mintUni3Nft(_token0, _token1, _fee, tickLower, tickUpper, _amount0, _amount1, _amount0Min, _amount1Min);
        }else{
            _liquidityAdded = increaseUni3Nft(_token0, _token1, _fee, _amount0, _amount1, _amount0Min, _amount1Min);
        }    

        ///////////////// BEGIN: UPDATE LIQUIDITY MAPPINGS ////////////////////////
        uint _nftId = originalPoolNftIds[_token0][_token1][_fee];
        totalLiquidityAtStateForNft[_nftId][statesCounter] = _liquidityAdded; 
        liquidityLastStateUpdate[_nftId] = statesCounter;

        uint userNft = positionsNFT.getUserNftPerPool(msg.sender, _nftId);
        positionsNFT.updateLiquidityForUser(userNft, _liquidityAdded, statesCounter);

        statesCounter++ ;
        liquidityLastDepositTime[userNft] = block.timestamp;
        ////////////////// END: UPDATE LIQUIDITY MAPPINGS ////////////////////////
    }

    function decreaseLiquidity(address _token0, address _token1, uint24 _fee, uint128 _purcentage) public {
        uint _poolNftId = poolNftIds[_token0][_token1][_fee];
        uint _poolOriginalNftId = originalPoolNftIds[_token0][_token1][_fee];
        uint _userNftId = positionsNFT.getUserNftPerPool(msg.sender, _poolOriginalNftId);
        require(liquidityLastDepositTime[_userNftId] < block.timestamp + liquidityLockTime, "liquidity locked !");
        
        uint lastLiquidityUpdateStateForPosition = positionsNFT.totalStatesForPosition(_userNftId);
        uint userPositionLastUpdateState = positionsNFT.getStatesIdsForPosition(_userNftId, lastLiquidityUpdateStateForPosition);
        uint128 _userLiquidity = positionsNFT.getLiquidityForUserInPoolAtState(_userNftId, userPositionLastUpdateState);
     
        uint128 _liquidityToRemove = _userLiquidity * _purcentage / 100;

        uint _amount0Min = 0; // maybe integrate slippage later
        uint _amount1Min = 0; // maybe integrate slippage later 

        DecreaseLiquidityParams memory decreaseLiquidityParams;
        decreaseLiquidityParams = DecreaseLiquidityParams(
                    _poolNftId, 
                    _liquidityToRemove, 
                    _amount0Min, 
                    _amount1Min, 
                    block.timestamp + deadline); 

        ERC20 token0 = ERC20(_token0);
        ERC20 token1 = ERC20(_token1);

        nonfungiblePositionManager.decreaseLiquidity(decreaseLiquidityParams);

        (,,,,,,,uint128 _liquidity,,,,) = nonfungiblePositionManager.positions(_poolNftId);
        uint _nftId = originalPoolNftIds[_token0][_token1][_fee];

        ///////////////// BEGIN: UPDATE LIQUIDITY MAPPINGS ////////////////////////
        totalLiquidityAtStateForNft[_nftId][statesCounter] = _liquidity; 
        liquidityLastStateUpdate[_nftId] = statesCounter;

        positionsNFT.updateLiquidityForUser(_nftId, _userLiquidity - _liquidityToRemove, statesCounter);

        statesCounter++ ;

        ////////////////// END: UPDATE LIQUIDITY MAPPINGS ////////////////////////
   
        collect(_token0, _token1, _fee);
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
                    _poolNftId, 
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

    // add the fees 
    // in rebalance you take just the nft id 
    // user will select the pair he wants 

}