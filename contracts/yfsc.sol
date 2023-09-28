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
    }

    function getUserNftPerPool(address receiver, uint uniswapNftId) view public returns (uint) {
        return userNftPerPool[receiver][uniswapNftId];
    }


    function updateLiquidityForUser(uint positionNftId, uint128 liquidity)public onlyRole(MINTER_ROLE) {
       
        liquidityForUserInPool[positionNftId] = liquidityForUserInPool[positionNftId] + liquidity;
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

    uint public positionsCounter;

    PositionsNFT public positionsNFT;
    NonfungiblePositionManager public nonfungiblePositionManager;

    mapping(uint => uint) public totalLiquidity;

    mapping(address => mapping(address => mapping(uint => uint))) public poolNftIds;// [token0][token1][fee] = nftId

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

    function setTickLower(int24 _tickLower) public onlyOwner{
        tickLower = _tickLower;
    }

    function setTickUpper(int24 _tickUpper) public onlyOwner{
        tickUpper = _tickUpper;
    }

    function setSilppageToken0(uint _slippageToken0) public onlyOwner{
        slippageToken0 = _slippageToken0;
    }

    function setSilppageToken1(uint _slippageToken1) public onlyOwner{
        slippageToken1 = _slippageToken1;
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
            positionsNFT.safeMint(tokenId, msg.sender, liquidity);
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
        // IncreaseLiquidityParams memory increaseLiquidityParams;

        uint tokenId = poolNftIds[_token0][_token1][_fee] > 0 ? poolNftIds[_token0][_token1][_fee] : poolNftIds[_token1][_token0][_fee];
        
        IncreaseLiquidityParams memory increaseLiquidityParams;
        increaseLiquidityParams = IncreaseLiquidityParams(
                    tokenId, 
                    _amount0, 
                    _amount1, 
                    _amount0Min, 
                    _amount1Min, 
                    block.timestamp + deadline ); 
        (uint128 liquidity,,) = nonfungiblePositionManager.increaseLiquidity(increaseLiquidityParams); 

        if(positionsNFT.getUserNftPerPool(msg.sender, tokenId) == 0){
            positionsNFT.safeMint(tokenId, msg.sender, liquidity);
        }else{
            positionsNFT.updateLiquidityForUser(positionsNFT.getUserNftPerPool(msg.sender, tokenId), liquidity);
        }
    }

    /// @notice Allow user to deposit liquidity and mint corresponding NFT
    /// @dev Public function
    /// @param _token0 The first token of the liquidity pool pair
    /// @param _token1 The second token of the liquidity pool pair
    /// @param _fee The desired fee for the pool  
    /// @param _amount0 0 for _token0, 1 for _token1
    /// @param _amount1 0 for _token0, 1 for _token1
    function mintNFT(
    address _token0, 
    address _token1, 
    uint24 _fee, 
    uint _amount0, 
    uint _amount1
    ) public {
        ERC20 token0 = ERC20(_token0);
        ERC20 token1 = ERC20(_token1);
        token0.transferFrom(msg.sender, address(this), _amount0);
        token1.transferFrom(msg.sender, address(this), _amount1);
        token0.approve(address(nonfungiblePositionManager), _amount0);
        token1.approve(address(nonfungiblePositionManager), _amount1);
        
        uint _amount0Min = _amount0 - _amount0 * slippageToken0 / quotient;
        uint _amount1Min = _amount1- _amount1 * slippageToken1 / quotient;
        console.log("before testing");
        if(poolNftIds[_token0][_token1][_fee] == 0 && poolNftIds[_token1][_token0][_fee] == 0)
        {
            mintUni3Nft(_token0, _token1, _fee, tickLower, tickUpper, _amount0, _amount1, _amount0Min, _amount1Min);
        }else{
            // console.log("increasing", _token0, _token1, _fee, _amount0, _amount1, _amount0Min, _amount1Min);
            console.log("increasing");

            increaseUni3Nft(_token0, _token1, _fee, _amount0, _amount1, _amount0Min, _amount1Min);
        }        
    }

    function decreaseLiquidity(address _token0, address _token1, uint24 _fee, uint128 _purcentage) public {
        uint _poolNftId = poolNftIds[_token0][_token1][_fee];
        uint _userNftId = positionsNFT.getUserNftPerPool(msg.sender, _poolNftId);

        uint128 _userLiquidity = positionsNFT.liquidityForUserInPool(_userNftId);

        uint128 _liquidityToRemove = _userLiquidity * _purcentage / 100;

        uint _amount0Min = 0;
        uint _amount1Min = 0;
 
        DecreaseLiquidityParams memory decreaseLiquidityParams;
        decreaseLiquidityParams = DecreaseLiquidityParams(
                    _poolNftId, 
                    _liquidityToRemove, 
                    _amount0Min, 
                    _amount1Min, 
                    block.timestamp + deadline ); 
        nonfungiblePositionManager.decreaseLiquidity(decreaseLiquidityParams);
    }

    // rebalance --> burn nft and create new one for new position 

    /// @notice Provide liquidity to a pair pool for a specified fee
    /// @dev Internal function, called by mintNFT function
    /// @param _token0 The first token of the liquidity pool pair
    /// @param _token1 The second token of the liquidity pool pair
    /// @param _fee The desired fee for the pool  
    /// @param _amount The amount of tokens `account` will receive
    /// @param _tokenToDeposit The amount of tokens `account` will receive
    function provideLiquidityToUniswap(address _token0, address _token1, uint _fee, uint _tokenToDeposit, uint _amount) internal {
        
    }
    // add the fees 
    // in rebalance you take just the nft id 
    // user will select the pair he wants 

    /// @notice Lock liquidity for a user
    /// @dev Function can only be called by the contract's deployer
    /// @param _user the liquidity provider to lock
    /// @param _token0 The first token of the liquidity pool pair
    /// @param _token1 The second token of the liquidity pool pair
    /// @param _fee The desired fee for the pool  
    function lockLiquidity(address _user, address _token0, address _token1, uint _fee) public {
        
    }

    /// @notice Withdraw liquidity by user
    /// @dev Function can be called by every liquidity provider
    /// @param _user The address of the account that will receive the newly created tokens
    /// @param _token0 The first token of the liquidity pool pair
    /// @param _token1 The second token of the liquidity pool pair
    /// @param _fee The desired fee for the pool  
    /// @param _amount The amount of tokens `account` will receive
    function withdrawLiquidity(address _user, address _token0, address _token1, uint _fee, uint _amount) public {   
        
    }

    /// @notice Collect all fees for a user
    /// @dev Function can be called by every liquidity provider
    function collectFees() public {
    }
}