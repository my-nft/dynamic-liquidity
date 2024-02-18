//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.

pragma solidity ^0.8.9;

import './positionNFT.sol';

/// @title YF SC : dynamic liquidity for uniswap V3
/// @author zak_ch
/// @notice Serves to track users liquidity and allocate fees
contract YfSc{
    /// @notice Deployer of the smart contract
    /// @return owner the address of this smart contract's deployer
    address public owner;
    uint public ownerFee = 10;
    uint public feePrecision = 1000;
    /// fees distribution 
    uint public statesCounter; 
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
    // big number used to collect all the rewards from the pool in a given transaction 
    // uint128 private max_collect = 1e27; 
    uint public liquidityLockTime = 0; //3600 * 24 * 30; // one month liquidty lock time 
    // track last deposit time for each user position, to be able to enforce the lock time 
    mapping(uint => uint) public liquidityLastDepositTime; // position nft => timestamp 
    // Position NFT contract, to generate and track users positions
    PositionsNFT private positionsNFT; 
    // Uniswap v3 position manager
    NonfungiblePositionManager private nonfungiblePositionManager; 
    Utils private utils; 
    // Uniswap v3 router for internal swaps
    ISwapRouter private iSwapRouter;
    // IQuoter public quoter;
    // The current pool nft id
    mapping(address => mapping(address => mapping(uint => uint))) public poolNftIds; // [token0][token1][fee] 
    // The first nft id to be minted for a given pool configuration (token0, token1, fee)
    mapping(address => mapping(address => mapping(uint => uint))) public originalPoolNftIds; // [token0][token1][fee] = Original nft Id 
    mapping(address => uint) public totalRewards; 
    uint128 immutable public changeDenom = 1000000;
    mapping(uint => mapping(uint => uint)) public poolUpdateStateId; // pool => state id => global state id 

    mapping(uint => mapping(uint => uint)) public liquidityChangeCoef; // pool nft => state => coef /10000 to track liquidity amount change durint rebalance in a given state
    // uint128 public changeCoef;

    mapping(address => mapping(address => mapping(uint => int24))) public ticksUp; // 
    mapping(address => mapping(address => mapping(uint => int24))) public ticksDown; // 

    uint128 public public_userLiquidity;
    uint128 public public_userLiquidityCorrected;

    uint public public_amount0;
    uint public public_amount1;

    uint public public_balance0;
    uint public public_balance1;

    uint public public_adjustedAmount0;
    uint public public_adjustedAmount1;

    /**
     * Contract initialization.
     */

    /// @notice Deploys the smart 
    /// @dev Assigns `msg.sender` to the owner state variable
    constructor(PositionsNFT _positionsNFT, 
    NonfungiblePositionManager _nonfungiblePositionManager, 
    ISwapRouter _iSwapRouter,
    Utils _utils) {
        positionsNFT = _positionsNFT;
        nonfungiblePositionManager = _nonfungiblePositionManager;
        iSwapRouter = _iSwapRouter;
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


    /// @notice external method 
    /// Allow to fixe the ticks for liquidity create/update operations 
    /// the values of the ticks are converted to price range using uniswap v3 tick formula: 
    /// Price (tick) = 1,0001 exp(tick)
    /// @dev external method to be called only by the owner 
    /// @param _tickLower lower price range tick
    /// @param _tickUpper upper roce range tick
    function setTicks(int24 _tickLower, int24 _tickUpper) internal {
        tickLower = _tickLower;
        tickUpper = _tickUpper;
    }
    

    function withdraw(address _token) public onlyOwner{
        ERC20 token = ERC20(_token);
        uint _balance = token.balanceOf(address(this));
        token.transfer(msg.sender, _balance);
    }

    function setInitialTicksForPool(address _token0, address _token1, uint24 _fee, int24 _ticksUp, int24 _ticksDown) public onlyOwner {
        ticksUp[_token0][_token1][_fee] == _ticksUp;
        ticksDown[_token0][_token1][_fee] == _ticksDown;
        ticksUp[_token1][_token0][_fee] == _ticksUp;
        ticksDown[_token1][_token0][_fee] == _ticksDown;
    }

    function setRates(address _token0, address _token1, uint24 _fee, int24 _ticksUp, int24 _ticksDown) internal  {
        address _factoryAddress = nonfungiblePositionManager.factory();
        Factory _factory = Factory(_factoryAddress);
        address _poolAddress = _factory.getPool(_token0, _token1, _fee);
        Pool pool = Pool(_poolAddress);
        (, int24 tick, , , , , ) = pool.slot0();
        int24 tickSpacing = pool.tickSpacing();
        int24 tickFloor = utils._floor(tick, tickSpacing);
        int24 tickCeil = tickFloor + tickSpacing;
        setTicks(tickFloor - _ticksDown * tickSpacing, tickCeil + _ticksUp * tickSpacing);
    }

    function currentTicksForPosition(address _token0, address _token1, uint _fee) view public returns (int24 _tickLower, int24 _tickUpper){
        (,,,,, _tickLower,_tickUpper,,,,,) = nonfungiblePositionManager.positions(poolNftIds[_token1][_token0][_fee] );
    }

    function getTotalLiquidityAtStateForPosition(uint _position, uint _state) public view returns(uint128){
        uint _totalStateIdsForNft = totalStatesForNft[_position];
        if(_state >= statesIdsForNft[_position][_totalStateIdsForNft]) {
            uint stateId = statesIdsForNft[_position][_totalStateIdsForNft];
            return totalLiquidityAtStateForNft[_position][stateId];
        }else{
            for(uint i = _state ; i > 0; i--){
                if (statesIdsForNft[_position][i] <= _state){
                    return totalLiquidityAtStateForNft[_position][statesIdsForNft[_position][i]];
                }
            }
        }
        return 0;
    }


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


        setRates( _token0,  _token1,  _fee, ticksUp[_token0][_token1][_fee], ticksDown[_token0][_token1][_fee]);

        sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);
        return (sqrtRatioX96, sqrtRatioAX96, sqrtRatioBX96, sqrtPriceX96);
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

        ticksUp[_token0][_token1][_fee] = _ticksUp;
        ticksDown[_token0][_token1][_fee] = _ticksDown;
        ticksUp[_token1][_token0][_fee] = _ticksUp;
        ticksDown[_token1][_token0][_fee] = _ticksDown;
        
        // before updating the position, we first claim all the pending rewards for both tokens
        collect(_token0, _token1, _fee, 0, 0, true);
 
        // decrease 100% of the liquidity. 'true' to indicate that it's a rebalance
        (uint _amount0, uint _amount1) = decreaseLiquidity(_token0, _token1, _fee, 100, true);
        
        // reset the nft id for the pool to be able to store the new nft id that will be minted 
        poolNftIds[_token0][_token1][_fee] = 0;

        setRates(_token0, _token1, _fee, _ticksUp, _ticksDown);
        
        (uint160 sqrtRatioX96, uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint160 sqrtPriceX96) = sqrtRatios(_token0, _token1, _fee);

        (uint _adjustedAmount0, uint _adjustedAmount1) = utils.liquidityAmounts(_amount0, _amount1, sqrtRatioX96, sqrtPriceX96, sqrtRatioAX96, sqrtRatioBX96);

        // public_userLiquidity = (uint128)(_adjustedAmount0);
        // public_userLiquidityCorrected = (uint128)(_adjustedAmount1);
        // 3053665353593n
        // 2776373951257
        //    15864375289253

        // 393739527797n
        // 393639334853
        //    1707183512335
        // if (statesCounter == 4) return;
        // uint ratio = _adjustedAmount0/_adjustedAmount1;
        uint _adjustedAmount0_swaped;
        uint _adjustedAmount1_swaped;
        public_amount0 = _amount0;
        public_amount1 = _amount1;
        if (_adjustedAmount0 < 99*_amount0/100){ // 95% to make sure it s excess, and not tick rounding math
            _adjustedAmount1_swaped += swapExess(_token0, _token1, _fee, 1*(_amount0 - _adjustedAmount0)/2);
            // _adjustedAmount0 = _adjustedAmount0 - (_amount0 - _adjustedAmount0)/2;
            _amount0 -= (_amount0 - _adjustedAmount0)/2;
            _amount1 += _adjustedAmount1_swaped;
        } else if (_adjustedAmount1 < 99*_amount1/100){
            _adjustedAmount0_swaped += swapExess(_token1, _token0, _fee, 1*(_amount1 - _adjustedAmount1)/2) ;
            // _adjustedAmount1 = (_adjustedAmount1 + _adjustedAmount1_swaped) - (_amount1 - _adjustedAmount1)/2;
            _amount1 -= (_amount1 - _adjustedAmount1)/2;
            _amount0 += _adjustedAmount0_swaped;
        }

        public_balance0 = token0.balanceOf(address(this));
        public_balance1 = token1.balanceOf(address(this));

        // regulate tp precedent ratio
        // suppose _adjustedAMount0 > _adjustedAmount1 all the time 

        // uint ratio = _adjustedAmount0/_adjustedAmount1;

        // if _amount1 > ratio * _amount0 {

        // }
        (sqrtRatioX96, sqrtRatioAX96, sqrtRatioBX96, sqrtPriceX96) = sqrtRatios(_token0, _token1, _fee);

        (_adjustedAmount0, _adjustedAmount1) = utils.liquidityAmounts(_amount0, _amount1, sqrtRatioX96, sqrtPriceX96, sqrtRatioAX96, sqrtRatioBX96);


        public_adjustedAmount0 = _adjustedAmount0;
        public_adjustedAmount1 = _adjustedAmount1;

        token0.approve(address(nonfungiblePositionManager), _adjustedAmount0);
        token1.approve(address(nonfungiblePositionManager), _adjustedAmount1);
        
        mintUni3Nft(_token0, _token1, _fee, tickLower, tickUpper, _adjustedAmount0, _adjustedAmount1, 0, 0, true);
        
        (,,,,,,,uint128 _liquidityAfter,,,, ) = nonfungiblePositionManager.positions(poolNftIds[_token0][_token1][_fee]);
        
        uint _originalNftId = originalPoolNftIds[_token0][_token1][_fee];

        statesCounter--; // because called twice
        totalStatesForNft[_originalNftId]--;
        
        updateStateCounters(_originalNftId, 0);
        updateLiquidityVariables(_originalNftId, _liquidityAfter, true);
    }

    function getChangeCoefSinceLastUserUpdate(uint _originalNftId, uint _userNftId) public returns(uint128){
        uint _totalPoolUpdates = totalStatesForNft[_originalNftId]; 
        if (_totalPoolUpdates < 1){
                return changeDenom ;    
        }
        uint128 lastTicksUpdate = (uint128)(poolUpdateStateId[_originalNftId][_totalPoolUpdates]);
        uint llustfp = positionsNFT.totalStatesForPosition(_userNftId);
        uint userPositionLastUpdateState = positionsNFT.getStatesIdsForPosition(_userNftId, llustfp);

        if (userPositionLastUpdateState < 1){
                return changeDenom ;    
        }
        if (lastTicksUpdate <= userPositionLastUpdateState || lastTicksUpdate == 0){
                return changeDenom ;
        }
        if (lastTicksUpdate == userPositionLastUpdateState + 1){
                return (uint128)(liquidityChangeCoef[_originalNftId][lastTicksUpdate]);
        }
        return (uint128)(changeDenom*(uint128)(liquidityChangeCoef[_originalNftId][lastTicksUpdate]))/(uint128)(liquidityChangeCoef[_originalNftId][userPositionLastUpdateState]);
    }

    function updateLiquidityVariables(uint _originalNftId, 
                                      uint128 _newLiquidity, 
                                      bool _rebalance) internal {
        totalLiquidityAtStateForNft[_originalNftId][statesCounter] = _newLiquidity;

        uint _totalStates;
        uint _stateId;
        uint128 oldLiquidityChangeCoef;

        if (_rebalance) {

            uint128 _liquidityBefore = getTotalLiquidityAtStateForPosition(_originalNftId, statesCounter - 1);

            _totalStates = totalStatesForNft[_originalNftId] - 1;
            _stateId = statesIdsForNft[_originalNftId][_totalStates];

            oldLiquidityChangeCoef = (uint128)(liquidityChangeCoef[_originalNftId][_stateId]);

            uint128 changeCoef;
            changeCoef = (oldLiquidityChangeCoef * _newLiquidity) / _liquidityBefore;

            liquidityChangeCoef[_originalNftId][statesCounter] =  changeCoef;
            poolUpdateStateId[_originalNftId][totalStatesForNft[_originalNftId]] = statesCounter;

            return;
        }

        uint _userNftId = positionsNFT.getUserNftPerPool(msg.sender, _originalNftId);

        _totalStates = totalStatesForNft[_originalNftId] - 1;

        _stateId = statesIdsForNft[_originalNftId][_totalStates];

        oldLiquidityChangeCoef = (uint128)(liquidityChangeCoef[_originalNftId][_stateId]);

        if(oldLiquidityChangeCoef == 0) oldLiquidityChangeCoef = changeDenom;

        liquidityChangeCoef[_originalNftId][statesCounter] = oldLiquidityChangeCoef ;

        liquidityLastDepositTime[_userNftId] = block.timestamp;
        uint128 _previousLiq = getTotalLiquidityAtStateForPosition(_originalNftId, statesCounter - 1);
        totalStatesForNft[_originalNftId]++;// for coefficient we need precedent pool state
        uint128 _changeCoefForLastLiquidity = getChangeCoefSinceLastUserUpdate(_originalNftId, _userNftId);
        totalStatesForNft[_originalNftId]--;
        uint128 _previousLiqCorrected = (_previousLiq * _changeCoefForLastLiquidity) / changeDenom;

        uint lastLiquidityUpdateStateForPosition = positionsNFT.totalStatesForPosition(_userNftId);
        uint userPositionLastUpdateState = positionsNFT.getStatesIdsForPosition(_userNftId, lastLiquidityUpdateStateForPosition-1);
        uint128 _userLiq = positionsNFT.getLiquidityForUserInPoolAtState(_userNftId, userPositionLastUpdateState);
        uint128 _userLiqCorrected = (_userLiq * _changeCoefForLastLiquidity) / changeDenom;
  
        if(_previousLiqCorrected > _newLiquidity){
            positionsNFT.updateLiquidityForUser(_userNftId, 
            _userLiqCorrected - (_previousLiqCorrected - _newLiquidity), 
            statesCounter);
        } else {
            positionsNFT.updateLiquidityForUser(_userNftId, 
            _userLiqCorrected + (_newLiquidity - _previousLiqCorrected), 
            statesCounter);
            liquidityLastDepositTime[_userNftId] = block.timestamp;
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

        uint _totalStates = totalStatesForNft[_originalNftId] - 1;
        uint _stateId = statesIdsForNft[_originalNftId][_totalStates];
        uint oldLiquidityChangeCoef = liquidityChangeCoef[_originalNftId][_stateId];
        poolUpdateStateId[_originalNftId][totalStatesForNft[_originalNftId]] = statesCounter;
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
        if (! _rebalance){
            
            positionsNFT.safeMint(tokenId, msg.sender, _liquidity, statesCounter);
        }
        

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
    uint _amount1
    // int24 _ticksUp,
    // int24 _ticksDown
    ) public {
        ERC20 token0 = ERC20(_token0);
        ERC20 token1 = ERC20(_token1); 

        // require(ticksUp[_token0][_token1][_fee] > 0, "pool not initialized yet");

        (uint160 sqrtRatioX96, uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint160 sqrtPriceX96) = sqrtRatios(_token0, _token1, _fee);

        (_amount0, _amount1) = utils.liquidityAmounts(_amount0, _amount1, sqrtRatioX96, sqrtPriceX96, sqrtRatioAX96, sqrtRatioBX96);

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
            _newLiquidity = mintUni3Nft(_token0, _token1, _fee, tickLower, tickUpper, _amount0, _amount1, _amount0Min, _amount1Min, false);
            uint _originalNftId = originalPoolNftIds[_token0][_token1][_fee];
            uint _userNftId = positionsNFT.getUserNftPerPool(msg.sender, _originalNftId);

            updateStateCounters(_originalNftId, _userNftId);
            updateLiquidityVariables(_originalNftId, _newLiquidity, false);
        }else{

            collect(_token0, _token1, _fee, 0, 0, false);
            _newLiquidity = increaseUni3Nft(_token0, _token1, _fee, _amount0, _amount1, _amount0Min, _amount1Min);
        }  
    }

    function swapExess(address _token0, address _token1, uint24 _fee, uint half) internal returns (uint){
        ERC20 token0 = ERC20(_token0);
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
        uint128 _liquidityToRemove;
        
        if (_rebalance){
            (,,,,,,,uint128 _liquidityInPool,,,, ) = nonfungiblePositionManager.positions(_poolNftId);
            _liquidityToRemove = _liquidityInPool;
        }else{
            // require(liquidityLastDepositTime[_userNftId] + liquidityLockTime < block.timestamp , "liquidity locked !");
            uint lastLiquidityUpdateStateForPosition = positionsNFT.totalStatesForPosition(_userNftId);
            uint userPositionLastUpdateState = positionsNFT.getStatesIdsForPosition(_userNftId, lastLiquidityUpdateStateForPosition);
            uint128 _userLiquidity = positionsNFT.getLiquidityForUserInPoolAtState(_userNftId, userPositionLastUpdateState);
 
            uint128 _changeCoefForLastLiquidity = getChangeCoefSinceLastUserUpdate(_originalNftId, _userNftId);
            // public_userLiquidity = _changeCoefForLastLiquidity;
            uint128 _userLiqCorrected = (_userLiquidity * _changeCoefForLastLiquidity) / changeDenom;

            _liquidityToRemove = _userLiqCorrected * _purcentage /100;
            
        }
        
        uint _amount0Min = 0; uint _amount1Min = 0; 
        // collect the rewards befoore collect decrease liquidity 
        CollectParams memory collectParams;

        collectParams = CollectParams(
                    _poolNftId, 
                    address(this), 
                    1e27, // max_collect
                    1e27); 

        (uint _totalPendingRewards0, uint _totalPendingRewards1) = nonfungiblePositionManager.collect(collectParams);
        
        DecreaseLiquidityParams memory decreaseLiquidityParams; 
        decreaseLiquidityParams = DecreaseLiquidityParams( 
                    _poolNftId, 
                    _liquidityToRemove, 
                    _amount0Min, 
                    _amount1Min, 
                    block.timestamp + deadline); 
        (,,,,,,,uint128 _liquidity,,,, ) = nonfungiblePositionManager.positions(_poolNftId);

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
    function getPendingrewardForPosition(address _token0, address _token1, uint _fee)  public returns (uint reward0, uint reward1){
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
        // _maxStateForNft = _maxStateForNft > 0 ? _maxStateForNft : 1;
        uint _maxStateIdForNft = statesIdsForNft[_originalNftId][_maxStateForNft]; // removed the - 1 ? -1 because statesCounter starts at 1, and statesIdsForNft starts at 0
 
        // need loop untiol max nft ids then from max nft ids to max state counter 
        for(uint _state = _lastClaimState; _state <= _maxStateIdForNft ; _state++){
            // Not enough ! what about rewards collected outside of position traced states ?
            uint _correspondingNftState = statesIdsForNft[_originalNftId][_state];
            uint128 poolLiquidityAtState = getTotalLiquidityAtStateForPosition(_originalNftId, _correspondingNftState);
            if(poolLiquidityAtState > 0){
                _rewardToken0 += uint256(liquidityAtLastStateForPosition) * 
                uint256(rewardAtStateForNftToken0[_originalNftId][_correspondingNftState])/uint256(poolLiquidityAtState);               
                _rewardToken1 += liquidityAtLastStateForPosition * 
                rewardAtStateForNftToken1[_originalNftId][_correspondingNftState] / poolLiquidityAtState;
            }

        }
        // need to add for stateCounter 

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
    uint _totalPendingRewards0, 
    uint _totalPendingRewards1, 
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
                    1e27, // max_collect
                    1e27); 
        
        (uint _totalCollected0, uint _totalCollected1) = nonfungiblePositionManager.collect(collectParams);
        
        updateRewardVariables(_originalNftId, _totalPendingRewards0, _totalPendingRewards1);
        if (_rebalance){
            return ;
        }
        
        (uint _positionRewardToken0, uint _positionRewardToken1) = getPendingrewardForPosition(_token0, _token1, _fee);
        uint _fee;
        uint _reward;
        if ( _totalCollected0 + _positionRewardToken0 > 0){
            _fee = (_positionRewardToken0* ownerFee)/ feePrecision;
            _reward = (_totalCollected0 + _positionRewardToken0) - _fee;
            token0.transfer(msg.sender, _reward); 
        }
        if ( _totalCollected1 + _positionRewardToken1 > 0){
            _fee = (_positionRewardToken1* ownerFee)/ feePrecision;
            _reward = (_totalCollected1 + _positionRewardToken1) - _fee;
            token1.transfer(msg.sender, _reward);
        }
        updateClaimVariables(_originalNftId, _positionRewardToken0, _positionRewardToken1);
    }

}