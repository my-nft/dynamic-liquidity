//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.

pragma solidity ^0.8.9;

import './positionNFT.sol';

interface StatesVariables {
    function getTotalLiquidityAtStateForNft(uint _nft, uint _state) external view returns(uint128);
    function setTotalLiquidityAtStateForNft(uint _nft, uint _state,uint128 _liquidity) external;
    function setRewardAtStateForNftToken0(uint _nft, uint _state,uint128 _reward) external ;
    function getRewardAtStateForNftToken0(uint _nft, uint _state) external view returns(uint128);
    function setRewardAtStateForNftToken1(uint _nft, uint _state,uint128 _reward) external ;
    function getRewardAtStateForNftToken1(uint _nft, uint _state) external view returns(uint128);
    function setTicksUp(address _token0, address _token1, uint24 _fee, int24 _ticksUp) external;
    function getTicksUp(address _token0, address _token1, uint24 _fee) external view returns(int24);
    function setTicksDown(address _token0, address _token1, uint24 _fee, int24 _ticksUp) external ;
    function getTicksDown(address _token0, address _token1, uint24 _fee) external view returns(int24);
    function updateRewardVariables(uint _originalNftId, uint _rewardAmount0, uint _rewardAmount1, uint _counter) external;
    function swapExess(address _token0, address _token1, uint24 _fee, uint half) external returns (uint);
    function getStatesIdsForNft(uint _nft, uint _stateId) external view returns (uint);
    function setStatesIdsForNft(uint _nft, uint _stateId, uint _state) external;
    function getTotalLiquidityAtStateForPosition(uint _position, uint _state) external view returns(uint128);
    function getTotalStatesForNft(uint _nft) external view  returns (uint);
    function setTotalStatesForNft(uint _nft, uint _totalStates) external returns(uint);
    function getLiquidityChangeCoef(uint _nft, uint _state) external  view  returns (uint) ;
    function setLiquidityChangeCoef(uint _nft, uint _state, uint _coef) external returns(uint);
    function getPoolUpdateStateId(uint _nft, uint _state) external view returns (uint) ;
    function setPoolUpdateStateId(uint _nft, uint _state, uint _glogalState) external returns(uint);

    function getTickLower() external view returns (int24) ;
    function setTickLower(uint _tick) external returns(uint);
    function getTickUpper() external view returns (int24) ;
    function setTickUpper(uint _tick) external returns(uint);

    function setTicks(int24 _tickLower, int24 _tickUpper) external ;
    function setRates(address _token0, address _token1, uint24 _fee, 
    int24 _ticksUp, int24 _ticksDown) external;
    function sqrtRatios(address _token0, address _token1, uint24 _fee) 
    external returns (uint160 sqrtRatioX96, uint160 sqrtRatioAX96, 
    uint160 sqrtRatioBX96, uint160 sqrtPriceX96);

    function getStatesCounter() external view returns (uint);
    function setStatesCounter(uint _count) external returns(uint);

    function getLiquidityLastDepositTime(uint _nft) external view returns (uint) ;
    function setLiquidityLastDepositTime(uint _nft, uint _time) external ;

    function getChangeCoefSinceLastUserUpdate(uint _originalNftId, uint _userNftId, uint correction) 
    external view returns(uint128);

    function updateLiquidityVariables(address, uint _originalNftId, 
                                      uint128 _newLiquidity, 
                                      bool _rebalance) external;

    function updateStateCounters(uint _originalNftId, uint _userNftId, address) external;

}

interface Positions{
    function totalStatesForPosition(uint _userPositionNft) external view returns(uint id);
    function safeMint(uint _uniswapNftId, address _receiver, uint128 _liquidity, uint _state) external ;
    function getUserNftPerPool(address receiver, uint uniswapNftId) view external returns (uint);
    function updateLiquidityForUser(uint positionNftId, uint128 _liquidity, uint _state) external ;
    function updateStatesIdsForPosition(uint positionNftId, uint _state) external ;
    function updateLastClaimForPosition(uint _positionNftId, uint _state) external ;
    function updateTotalClaimForPosition(uint _positionNftId, uint _newClaim0, uint _newClaim1) external ;
    function getLiquidityForUserInPoolAtState(uint _userPositionNft, uint _state) external view returns(uint128 liquidity);
    function getUserShareInPoolAtState(uint _userPositionNft, uint _state) external view returns(uint128 liquidity);
    function getStatesIdsForPosition(uint _userPositionNft, uint _stateId) external view returns(uint id);
    function updateClaimVariables(uint _originalNftId, uint _claimAmount0, uint _claimAmount1, uint statesCounter) external;
    function lastClaimForPosition(uint) external view returns (uint);
    function statesIdsForPosition(uint, uint) external view returns (uint);
}

interface IUtils {
    function toUint128(uint256 x) external view returns (uint128 y) ;
    function liquidityAmounts(
    uint _amount0, uint _amount1, 
    uint160 _sqrtRatioX96, uint160 _sqrtPriceX96, 
    uint160 _sqrtRatioAX96, uint160 _sqrtRatioBX96) 
    external 
    returns (uint _adjustedAmount0, uint _adjustedAmount1);
    function _floor(int24 tick, int24 tickSpacing) external view returns (int24) ;
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) external view returns (uint128 liquidity);
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) external view returns (uint128 liquidity);
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) external view returns (uint128 liquidity) ;
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) external view returns (uint256 amount0);
    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) external view returns (uint256 amount1);
}

/// @title YF SC : dynamic liquidity for uniswap V3
/// @author zak_ch
/// @notice Serves to track users liquidity and allocate fees
contract YfSc{
    /// @notice Deployer of the smart contract
    /// @return owner the address of this smart contract's deployer
    address public owner;
    uint public ownerFee = 10;
    uint public feePrecision = 1000;

    // uint public statesCounter; 

    uint public liquidityLockTime = 0; 
    // mapping(uint => uint) public liquidityLastDepositTime; // position nft => timestamp 
 
    Positions private positionsNFT; 
  
    NonfungiblePositionManager private npm; 
    IUtils private utils; 

    StatesVariables private sv;

    mapping(address => mapping(address => mapping(uint => uint))) public poolNftIds; // [token0][token1][fee] 
    // The first nft id to be minted for a given pool configuration (token0, token1, fee)
    mapping(address => mapping(address => mapping(uint => uint))) public originalPoolNftIds; // [token0][token1][fee] = Original nft Id 
    
    uint public public_reward_0;
    uint public public_reward_1;
    /**
     * Contract initialization.
     */

    /// @notice Deploys the smart 
    /// @dev Assigns `msg.sender` to the owner state variable
    constructor(Positions _positionsNFT, 
    NonfungiblePositionManager _npm, 
    IUtils _utils) {
        positionsNFT = _positionsNFT;
        npm = _npm;
        owner = msg.sender;
        utils = _utils;
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

    function setStatesVariables(StatesVariables _sv) external onlyOwner {
        sv =  _sv;
    }

    // function withdraw(address _token) public onlyOwner{
    //     ERC20 token = ERC20(_token);
    //     uint _balance = token.balanceOf(address(this));
    //     token.transfer(msg.sender, _balance);
    // }


    // function setLockTime(uint _liquidityLockTime) external onlyOwner{
    //     liquidityLockTime = _liquidityLockTime;
    // }

    function updatePosition(address _token0, address _token1, uint24 _fee, 
    int24 _ticksUp, int24 _ticksDown) external onlyOwner {
       
        ERC20 token0 = ERC20(_token0);
        ERC20 token1 = ERC20(_token1);

        sv.setTicksUp(_token0, _token1, _fee, _ticksUp);
        sv.setTicksDown(_token0, _token1, _fee, _ticksDown);
        sv.setTicksUp(_token1, _token0, _fee, _ticksUp);
        sv.setTicksDown(_token1, _token0, _fee, _ticksDown);
        
        // collect(_token0, _token1, _fee, 0, 0, true, false);
        (uint _amount0, uint _amount1) = decreaseLiquidity(_token0, _token1, _fee, 100, true);
        
        poolNftIds[_token0][_token1][_fee] = 0;
        poolNftIds[_token1][_token0][_fee] = 0;

        sv.setRates(_token0, _token1, _fee, _ticksUp, _ticksDown);
        
        (uint160 sqrtRatioX96, uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint160 sqrtPriceX96) = 
        sv.sqrtRatios(_token0, _token1, _fee);

        (uint _adjustedAmount0, uint _adjustedAmount1) = 
        utils.liquidityAmounts(_amount0, _amount1, sqrtRatioX96, sqrtPriceX96, sqrtRatioAX96, sqrtRatioBX96);

        uint _adjustedAmount0_swaped;
        uint _adjustedAmount1_swaped;
        
        if (_adjustedAmount0 < 99*_amount0/100){ 
            token0.approve(address(sv), (_amount0 - _adjustedAmount0)/2);
            
            _adjustedAmount1_swaped += sv.swapExess(_token0, _token1, _fee, (_amount0 - _adjustedAmount0)/2);
            _amount0 -= (_amount0 - _adjustedAmount0)/2;
            _amount1 += _adjustedAmount1_swaped;
        } else if (_adjustedAmount1 < 99*_amount1/100){
            token1.approve(address(sv), (_amount1 - _adjustedAmount1)/2);
            _adjustedAmount0_swaped += sv.swapExess(_token1, _token0, _fee, (_amount1 - _adjustedAmount1)/2) ;
            _amount1 -= (_amount1 - _adjustedAmount1)/2;
            _amount0 += _adjustedAmount0_swaped;
        }
        
        (sqrtRatioX96, sqrtRatioAX96, sqrtRatioBX96, sqrtPriceX96) = sv.sqrtRatios(_token0, _token1, _fee);

        (_adjustedAmount0, _adjustedAmount1) = utils.liquidityAmounts(99*_amount0/100, 99*_amount1/100, sqrtRatioX96, sqrtPriceX96, sqrtRatioAX96, sqrtRatioBX96);

        token0.approve(address(npm), _adjustedAmount0);
        token1.approve(address(npm), _adjustedAmount1);
        
        mintUni3Nft(_token0, _token1, _fee, sv.getTickLower(), sv.getTickUpper(), _adjustedAmount0, _adjustedAmount1, 0, 0, true);
        
        (,,,,,,,uint128 _liquidityAfter,,,, ) = npm.positions(poolNftIds[_token0][_token1][_fee]);
        
        uint _originalNftId = originalPoolNftIds[_token0][_token1][_fee];

        sv.setStatesCounter(sv.getStatesCounter() - 1);
        sv.setTotalStatesForNft(_originalNftId, sv.getTotalStatesForNft(_originalNftId) - 1);
        
        sv.updateStateCounters(_originalNftId, 0, msg.sender);
        sv.updateLiquidityVariables(msg.sender, _originalNftId, _liquidityAfter, true);
    }

    // function updateStateCounters(uint _originalNftId, uint _userNftId) internal {
    //     sv.setTotalStatesForNft(_originalNftId, sv.getTotalStatesForNft(_originalNftId) +1);
    //     sv.setStatesCounter(sv.getStatesCounter() + 1);
    //     sv.setStatesIdsForNft(_originalNftId, sv.getTotalStatesForNft(_originalNftId), sv.getStatesCounter());

    //     if(_userNftId == 0) return; 
    //     uint positionNftId = positionsNFT.getUserNftPerPool(msg.sender, _originalNftId);
    //     positionsNFT.updateStatesIdsForPosition(positionNftId, sv.getStatesCounter());  

    //     uint _totalStates = sv.getTotalStatesForNft(_originalNftId) - 1;
    //     uint _stateId = sv.getStatesIdsForNft(_originalNftId,_totalStates);
    //     uint oldLiquidityChangeCoef = sv.getLiquidityChangeCoef(_originalNftId,_stateId);
    //     sv.setPoolUpdateStateId(_originalNftId,sv.getTotalStatesForNft(_originalNftId),sv.getStatesCounter());
    // }

    function mintUni3Nft(
                            address _token0, 
                            address _token1, 
                            uint24 _fee, 
                            int24 _tickLower, 
                            int24 _tickUpper, 
                            uint _amount0, 
                            uint _amount1, 
                            uint _amount0Min, 
                            uint _amount1Min,
                            bool _rebalance
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
                    block.timestamp + 600 
                    );
        uint128 oldLiquidity;
        if (originalPoolNftIds[_token0][_token1][_fee] != 0 ){
            (,,,,,,,oldLiquidity,,,,) = npm.positions(originalPoolNftIds[_token0][_token1][_fee]);
        }

        (uint256 tokenId, 
        uint128 _liquidity , 
        uint __amount0, 
        uint __amount1) = npm.mint(mintParams);

        if (originalPoolNftIds[_token0][_token1][_fee] == 0){
            originalPoolNftIds[_token1][_token0][_fee] = tokenId;
            originalPoolNftIds[_token0][_token1][_fee] = tokenId;
        }

        poolNftIds[_token0][_token1][_fee] = tokenId;
        poolNftIds[_token1][_token0][_fee] = tokenId;
        if (! _rebalance){
            positionsNFT.safeMint(tokenId, msg.sender, _liquidity - oldLiquidity, sv.getStatesCounter());
        }

        return _liquidity;
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

        uint tokenId = poolNftIds[_token0][_token1][_fee] ;
        uint _originalNftId = originalPoolNftIds[_token0][_token1][_fee];
        (,,,,,,,uint128 oldLiquidity,,,,) = npm.positions(tokenId);

        IncreaseLiquidityParams memory increaseLiquidityParams; 
        increaseLiquidityParams = IncreaseLiquidityParams( 
                    tokenId, 
                    _amount0, 
                    _amount1, 
                    _amount0Min, 
                    _amount1Min, 
                    block.timestamp + 600); 
        (uint128 _addedLiquidity, uint amount0, uint amount1) = npm.increaseLiquidity(increaseLiquidityParams);
        uint128 _newLiquidity = oldLiquidity + _addedLiquidity;
        uint userPositionNft = positionsNFT.getUserNftPerPool(msg.sender, _originalNftId);

        if(userPositionNft == 0 && msg.sender != owner){
            positionsNFT.safeMint(_originalNftId, msg.sender, _addedLiquidity, sv.getStatesCounter() + 1);
            userPositionNft = positionsNFT.getUserNftPerPool(msg.sender, _originalNftId);
        }

        if (msg.sender == owner){ // means rebalance
            sv.updateStateCounters(_originalNftId, 0, msg.sender);
            sv.updateLiquidityVariables(msg.sender, _originalNftId, _newLiquidity, true);
        } else{
            sv.updateStateCounters(_originalNftId, userPositionNft, msg.sender);
            sv.updateLiquidityVariables(msg.sender, _originalNftId, _newLiquidity, false);
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
    uint _amount1
    ) public {
        
        ERC20 token0 = ERC20(_token0);
        ERC20 token1 = ERC20(_token1); 
        
        // require(sv.getTicksUp(_token0, _token1, _fee) > 0, "pool not initialized yet");
        
        (uint160 sqrtRatioX96, uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint160 sqrtPriceX96) = sv.sqrtRatios(_token0, _token1, _fee);
        // return;
        (_amount0, _amount1) = utils.liquidityAmounts(_amount0, _amount1, sqrtRatioX96, sqrtPriceX96, sqrtRatioAX96, sqrtRatioBX96);
        
        token0.transferFrom(msg.sender, address(this), _amount0);
        token1.transferFrom(msg.sender, address(this), _amount1);
        
        token0.approve(address(npm), _amount0);
        token1.approve(address(npm), _amount1);
        
        ISwapRouter.ExactInputSingleParams memory _exactInputSingleParams;

        uint128 _newLiquidity;

        
        
        if(poolNftIds[_token0][_token1][_fee] == 0)
        {
            _newLiquidity = mintUni3Nft(_token0, _token1, _fee, sv.getTickLower(), sv.getTickUpper(), _amount0, _amount1, 0, 0, false);
            
            sv.updateStateCounters(originalPoolNftIds[_token0][_token1][_fee], 
            positionsNFT.getUserNftPerPool(msg.sender, originalPoolNftIds[_token0][_token1][_fee]), msg.sender);
            
            sv.updateLiquidityVariables(msg.sender, originalPoolNftIds[_token0][_token1][_fee], _newLiquidity, false);
            
        }else{
            
            collect(_token0, _token1, _fee, 0, 0, false, false);
            _newLiquidity = increaseUni3Nft(_token0, _token1, _fee, _amount0, _amount1, 0, 0);
        }  
        
    }

    /// @notice Allow user to withdraw liquidity from a given position, 
    /// It will burn the liquidity and send the tokens to the depositer
    /// @dev Public function
    /// @param _token0 The first token of the liquidity pool pair
    /// @param _token1 The second token of the liquidity pool pair
    /// @param _fee The desired fee for the pool  
    /// @param _purcentage desired % of the users liquidity to be removed
    /// @param _rebalance always set to true for external calls, it is set to false only internally
    function decreaseLiquidity(address _token0, address _token1, uint24 _fee, 
    uint128 _purcentage, bool _rebalance) public returns (uint, uint) { 
        
        uint _poolNftId = poolNftIds[_token0][_token1][_fee];
        uint _originalNftId = originalPoolNftIds[_token0][_token1][_fee];  
        
        uint _userNftId = positionsNFT.getUserNftPerPool(msg.sender, _originalNftId);
        uint128 _liquidityToRemove;
        
        if (_rebalance){
            (,,,,,,,uint128 _liquidityInPool,,,, ) = npm.positions(_poolNftId);
            _liquidityToRemove = _liquidityInPool;
        }else{
            require(sv.getLiquidityLastDepositTime(_userNftId) + liquidityLockTime < block.timestamp , "liquidity locked !");
            uint lastLiquidityUpdateStateForPosition = positionsNFT.totalStatesForPosition(_userNftId);
            uint userPositionLastUpdateState = positionsNFT.getStatesIdsForPosition(_userNftId, 
            lastLiquidityUpdateStateForPosition);
            uint128 _userLiquidity = positionsNFT.getLiquidityForUserInPoolAtState(_userNftId, userPositionLastUpdateState);
            uint128 _changeCoefForLastLiquidity = sv.getChangeCoefSinceLastUserUpdate(_originalNftId, _userNftId, 0);
            uint128 _userLiqCorrected = (_userLiquidity * _changeCoefForLastLiquidity) / 1000000;
            
            _liquidityToRemove = (_userLiqCorrected * _purcentage)/100;
        }
        // collect the rewards befoore collect decrease liquidity 
        CollectParams memory collectParams;
        collectParams = CollectParams(
                    _poolNftId, 
                    address(this), 
                    1e27, // max_collect
                    1e27); 

        (uint _reward0, uint _reward1) = 
        npm.collect(collectParams);

        public_reward_0 = _reward0;
        public_reward_1 = _reward1;

        // sv.updateRewardVariables(_originalNftId, _totalPendingRewards0, 
        // _totalPendingRewards1, sv.getStatesCounter());
     
        
        DecreaseLiquidityParams memory decreaseLiquidityParams; 
        decreaseLiquidityParams = DecreaseLiquidityParams( 
                    _poolNftId, 
                    _liquidityToRemove, 
                    0, 
                    0, 
                    block.timestamp + 600); 
        (,,,,,,,uint128 _liquidity,,, , ) = npm.positions(_poolNftId);

        (uint _amount0, uint _amount1) = 
        npm.decreaseLiquidity(decreaseLiquidityParams);
        
        _liquidity = _liquidity - _liquidityToRemove;
        
        collect(_token0, _token1, _fee, _reward0, 
        _reward1, _rebalance, false);
        
        sv.updateStateCounters(_originalNftId, _userNftId, msg.sender);
        
        sv.updateLiquidityVariables(msg.sender, _originalNftId, _liquidity, _rebalance);
        
        return (_amount0, _amount1);
    }

    /// @notice returns the pending rewards for a user in a given pool
    /// @dev Public function
    /// @param _token0 The first token of the liquidity pool pair
    /// @param _token1 The second token of the liquidity pool pair
    /// @param _fee The desired fee for the pool  
    function getPendingrewardForPosition(address _token0, address _token1, uint _fee) 
    public view returns (uint reward0, uint reward1){
        uint _originalNftId = originalPoolNftIds[_token0][_token1][_fee]; // get first pool nft id 
        // uint _poolNftId = poolNftIds [_token0][_token1][_fee]; // get current pool nft id 
        uint _userPositionNft = positionsNFT.getUserNftPerPool(msg.sender, _originalNftId);
        
        uint userLastClaim = positionsNFT.lastClaimForPosition(_originalNftId);
        uint userTotalStates = positionsNFT.totalStatesForPosition(_userPositionNft); 
        // uint lastStateId = positionsNFT.statesIdsForPosition(_userPositionNft, userTotalStates > 0 ? userTotalStates - 1 : 0);
        if (userTotalStates > 0){
            userTotalStates = userTotalStates - 1;
        }
        uint lastStateId = positionsNFT.statesIdsForPosition(_userPositionNft, userTotalStates);
        
        uint totalRewardToken0 = sv.getRewardAtStateForNftToken0(_originalNftId, sv.getStatesCounter());
        uint totalRewardToken1 = sv.getRewardAtStateForNftToken1(_originalNftId, sv.getStatesCounter());

        // uint totalRewardToken0 = sv.getStatesCounter();//sv.getRewardAtStateForNftToken1(_originalNftId, 2);
        // uint totalRewardToken1 = sv.getRewardAtStateForNftToken0(_originalNftId, 2);
        // return(lastStateId, sv.getStatesCounter());
        
        uint totalRewardLastStateToken0 = sv.getRewardAtStateForNftToken0(_originalNftId, lastStateId);
        uint totalRewardLastStateToken1 = sv.getRewardAtStateForNftToken1(_originalNftId, lastStateId);
        // return(0, 100);
        // return(totalRewardToken0, totalRewardToken1);
        uint totalToken0 = totalRewardToken0 - totalRewardLastStateToken0;
        uint totalToken1 = totalRewardToken1 - totalRewardLastStateToken1;
        
        uint128 _userLiquidity = positionsNFT.getLiquidityForUserInPoolAtState(_userPositionNft, lastStateId);
        
        uint128 _changeCoefForLastLiquidity = sv.getChangeCoefSinceLastUserUpdate(_originalNftId, _userPositionNft, 0);
        
        uint userLiquidityCorrected = (_userLiquidity * _changeCoefForLastLiquidity) / 1000000;
        
        uint128 poolLiquidity = sv.getTotalLiquidityAtStateForPosition(_originalNftId, sv.getStatesCounter() - 1);
        uint userShare;
        if(poolLiquidity == 0){
            userShare = 0; 
        } else{
            userShare = (1000000*userLiquidityCorrected)/poolLiquidity;
        }
        
        uint reward0 = (userShare * totalToken0)/1000000;
        uint reward1 = (userShare * totalToken1)/1000000;
        return(reward0, reward1);
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
    uint _totalPendingRewards0, 
    uint _totalPendingRewards1, 
    bool _rebalance,
    bool _external) public {
        
        ERC20 token0 = ERC20(_token0);
        ERC20 token1 = ERC20(_token1);
        uint _originalNftId = originalPoolNftIds[_token0][_token1][_fee]; // get first pool nft id 
        uint _poolNftId = poolNftIds [_token0][_token1][_fee]; // get first pool nft id 
        uint _userPositionNft = positionsNFT.getUserNftPerPool(msg.sender, _originalNftId);

        CollectParams memory collectParams;

        collectParams = CollectParams(
                    _poolNftId, 
                    address(this), 
                    1e27, // max_collect
                    1e27); 

        // (,,,,,,,uint128 _liquidity,,,uint128 _reward0 , uint128 _reward1) = npm.positions(_poolNftId);
        uint _reward0 = _totalPendingRewards0;
        uint _reward1 = _totalPendingRewards1;

        (uint _totalCollected0, uint _totalCollected1) = 
        npm.collect(collectParams);

        uint _statesIncrease;

        if (_external){
            _reward0 = _totalCollected0;
            _reward1 = _totalCollected1;

            sv.updateStateCounters(_originalNftId, _userPositionNft, msg.sender);
            (,,,,,,,uint128 _liquidityInPool,,,, ) = npm.positions(_poolNftId);
            sv.updateLiquidityVariables(msg.sender, _originalNftId, _liquidityInPool, false);  
            _statesIncrease = 1;
        }

        // uint _state = sv.getStatesCounter() > _statesIncrease ? (sv.getStatesCounter() - _statesIncrease) : 0;
        
        sv.updateRewardVariables(_originalNftId, 
        sv.getRewardAtStateForNftToken0(_originalNftId, sv.getStatesCounter() - _statesIncrease) + _reward0, 
        sv.getRewardAtStateForNftToken1(_originalNftId, sv.getStatesCounter() - _statesIncrease) + _reward1, 
        sv.getStatesCounter() - _statesIncrease + 1);
        // sv.getStatesCounter());

        // sv.updateRewardVariables(_originalNftId, 
        // 1000000, 
        // 20000, 
        // sv.getStatesCounter());

        if (_rebalance){
            return ;
        }

        (uint _positionRewardToken0, uint _positionRewardToken1) = 
        getPendingrewardForPosition(_token0, _token1, _fee);
        uint _fee;
        uint _reward;

        // token1.transfer(msg.sender, 100);

        // return;
        if ( _positionRewardToken0 > 0){
            // token0.transfer(msg.sender, _positionRewardToken0); 
            uint _total0 = (_totalCollected0 + _positionRewardToken0)  ;
            _fee = (_positionRewardToken0 * ownerFee)/ feePrecision;
            _reward = (_total0) - _fee;
            token0.transfer(msg.sender, _reward); 
        }
        if (_positionRewardToken1 > 0){
            // token1.transfer(msg.sender, _positionRewardToken1);
            uint _total1 = (_totalCollected1 + _positionRewardToken1);
            _fee = (_positionRewardToken1* ownerFee)/ feePrecision;
            _reward = (_positionRewardToken1) - _fee;
            token1.transfer(msg.sender, _reward);
        }
        positionsNFT.updateClaimVariables(_originalNftId, _positionRewardToken0, 
        _positionRewardToken1, sv.getStatesCounter());
    }

}