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

    function updateLiquidityForUser(uint positionNftId, uint128 _liquidity,uint _state)public onlyRole(MINTER_ROLE) {
        liquidityForUserInPoolAtState[positionNftId][_state] = _liquidity;
        totalStatesForPosition[positionNftId]++;
        statesIdsForPosition[positionNftId][totalStatesForPosition[positionNftId]] = _state;
    }

    function updateLastClaimForPosition(uint _positionNftId, uint _state)public onlyRole(MINTER_ROLE) {
        lastClaimForPosition[_positionNftId] = _state;
    }

    function updateTotalClaimForPosition(uint _positionNftId, uint _totalClaim)public onlyRole(MINTER_ROLE) {
        totalClaimedforPosition[_positionNftId] = _totalClaim;
    }

    function getLiquidityForUserInPoolAtState(uint _userPositionNft, uint _state) public returns(uint128 liquidity){
        liquidity = liquidityForUserInPoolAtState[_userPositionNft][_state];
        return liquidity;
    }

    function getStatesIdsForPosition(uint _userPositionNft, uint _stateId) public returns(uint id){
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
    uint public statesCounter = 1; 

    mapping(uint=>uint) public liquidityLastStateUpdate; // nft --> last State Update for liquidity for Uni3 NFT

    mapping(uint => mapping(uint => uint128)) public totalLiquidityAtStateForNft; 

    mapping(uint => mapping(uint => uint)) public rewardAtStateForNftToken0; 
    mapping(uint => mapping(uint => uint)) public rewardAtStateForNftToken1; 

    mapping(uint => uint) public totalRewardForNftToken0; 
    mapping(uint => uint) public totalRewardForNftToken1; 

    mapping(uint => uint) public totalRewardPaidForNftToken0; 
    mapping(uint => uint) public totalRewardPaidForNftToken1; 

    mapping(uint => mapping(uint => uint)) public statesIdsForNft; 

    mapping(uint => uint) public totalStatesForNft; 

    uint public liquidityUpdateRatioDenominator = 1000; // used to track users shares when liquidity 
                                       //position is updated and drives a change in liquidity amount 
                                       
    mapping(uint => uint) public liquidityUpdateRatio; // if == 1000, means liquidity amount didn t change, 
                                                       // if < 1000, means liquidity amount is lower than before update 
                                                       // if > 1000, means liquidity amount is higher than before update 
                                                       // LUR = { 1003, 980, 970, 850, 1050, 1090, 1100, 1200 }    

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

    uint public public_poolNftId;
  
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

    }

    function setSilppageToken0(uint _slippageToken0, uint _slippageToken1) public onlyOwner{

    }

    function setLockTime(uint _liquidityLockTime) public onlyOwner{
        
    }

    // you will need to update the ticks first before calling this methods
    function updatePosition(address _token0, address _token1, uint24 _fee) external onlyOwner {

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
    uint _amount0,
    uint _amount1
    ) public {

    }

    function decreaseLiquidity(address _token0, address _token1, uint24 _fee, uint128 _purcentage, bool _notYetpdated) public {

    }

    function sweepToken(address _token, uint amount, address receiver) public {

    }

    function collect(address _token0, address _token1, uint _fee,  uint128 _tokensOwed0, uint128 _tokensOwed1) public {

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
        return amount1;
    }

    function getPendingrewardForPosition(address _token0, address _token1, uint _fee) view public returns (uint reward0, uint reward1){
    }

    // add the fees 
    // in rebalance you take just the nft id 
    // user will select the pair he wants 

}