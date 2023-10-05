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

    uint public public_nft_id;
    uint public public_liquidityToRemove;
    uint public public_amount0Min;
    uint public public_amount1Min;
    uint public public_deadline; 

    uint public public_balance0Before;
    uint public public_balance1Before;

    uint public public_balance0After;
    uint public public_balance1After;

    uint public public_update_position_balance0;
    uint public public_update_position_balance1;

    uint128 public liquidity_before;
    uint128 public liquidity_after;

    uint128 public tokensOwed0_before;
    uint128 public tokensOwed1_before;

    uint128 public tokensOwed0_after;
    uint128 public tokensOwed1_after;


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

        tickLower = -300000;
        tickUpper = 300000;

        ERC20 token0 = ERC20(_token0);
        ERC20 token1 = ERC20(_token1);

        uint oldBalanceToken0 = token0.balanceOf(address(this));
        uint oldBalanceToken1 = token1.balanceOf(address(this));

        decreaseLiquidity(_token0, _token1, _fee, 100);

        uint newBalanceToken0 = token0.balanceOf(address(this));
        uint newBalanceToken1 = token1.balanceOf(address(this));

        uint balance0 = newBalanceToken0 - oldBalanceToken0;
        uint balance1 = newBalanceToken1 - oldBalanceToken1;

        public_update_position_balance0 = balance0;
        public_update_position_balance1 = balance1;

        poolNftIds[_token0][_token1][_fee] = 0;

        // mintNFT(
        //     _token0, 
        //     _token1, 
        //     _fee, 
        //     balance0, 
        //     balance1
        // );
        mintNFT(
            _token0, 
            _token1, 
            _fee, 
            newBalanceToken0, 
            newBalanceToken1
        );

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
        // IncreaseLiquidityParams memory increaseLiquidityParams;

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
        uint _userNftId = positionsNFT.getUserNftPerPool(msg.sender, updatedlNftId[_poolNftId]);
        require(positionsNFT.liquidityLastDepositTime(_userNftId) < block.timestamp + liquidityLockTime, "liquidity locked !");
        uint userNft = positionsNFT.getUserNftPerPool(msg.sender, updatedlNftId[_poolNftId]);
        uint128 _userLiquidity = positionsNFT.liquidityForUserInPool(userNft);

        uint128 _liquidityToRemove = _userLiquidity * _purcentage / 100;

        uint _amount0Min = 0; // maybe integrate slippage later
        uint _amount1Min = 0; // maybe integrate slippage later 

        (,,,,,,,liquidity_before,,,
            tokensOwed0_before,
            tokensOwed1_before
        ) = nonfungiblePositionManager.positions(updatedlNftId[_poolNftId]);

        DecreaseLiquidityParams memory decreaseLiquidityParams;
        decreaseLiquidityParams = DecreaseLiquidityParams(
                    updatedlNftId[_poolNftId], 
                    _liquidityToRemove, 
                    _amount0Min, 
                    _amount1Min, 
                    block.timestamp + deadline); 

        public_nft_id = userNft;
        public_liquidityToRemove = _liquidityToRemove;
        public_amount0Min = _amount0Min;
        public_amount1Min = _amount1Min;
        public_deadline = block.timestamp + deadline; 

        ERC20 token0 = ERC20(_token0);
        ERC20 token1 = ERC20(_token1);

        public_balance0Before = token0.balanceOf(address(this));
        public_balance1Before = token1.balanceOf(address(this));

        nonfungiblePositionManager.decreaseLiquidity(decreaseLiquidityParams);
        (,,,,,,,liquidity_after,,,
            tokensOwed0_after,
            tokensOwed1_after
        ) = nonfungiblePositionManager.positions(updatedlNftId[_poolNftId]);

        collect(_token0, _token1, _fee);
        public_balance0After = token0.balanceOf(address(this));
        public_balance1After = token1.balanceOf(address(this));

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