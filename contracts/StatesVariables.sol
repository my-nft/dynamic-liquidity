pragma solidity ^0.8.9;

import './positionNFT.sol';

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
}
contract StatesVariables {

    uint public deadline = 600; 

    address public yf;
    mapping(uint => mapping(uint => uint128)) public totalLiquidityAtStateForNft; 
    
    mapping(uint => mapping(uint => uint128)) public rewardAtStateForNftToken0; 
    // for a given uniswap nft, and a given state, returns the claimed reward for token 1
    mapping(uint => mapping(uint => uint128)) public rewardAtStateForNftToken1; 

    mapping(address => mapping(address => mapping(uint => int24))) public ticksUp; // 
    mapping(address => mapping(address => mapping(uint => int24))) public ticksDown; // 

    mapping(uint => mapping(uint => uint)) public statesIdsForNft; 

    mapping(uint => uint) public totalStatesForNft; 

    mapping(uint => mapping(uint => uint)) public liquidityChangeCoef;

    mapping(uint => mapping(uint => uint)) public poolUpdateStateId;

    uint public statesCounter; 

    mapping(uint => uint) public liquidityLastDepositTime; // position nft => timestamp 

    int24 public tickLower; 
    int24 public tickUpper;

    ISwapRouter private iSwapRouter;

    NonfungiblePositionManager private nonfungiblePositionManager; 

    address public owner;

    Positions private positionsNFT; 
    
    constructor(Positions _positionsNFT,
    NonfungiblePositionManager _nonfungiblePositionManager,
    address _yf, 
    ISwapRouter _iSwapRouter){
        owner = msg.sender;
        yf = _yf;
        iSwapRouter = _iSwapRouter;
        nonfungiblePositionManager = _nonfungiblePositionManager;
        positionsNFT = _positionsNFT;
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

    function getLiquidityLastDepositTime(uint _nft) public view returns (uint) {
        return liquidityLastDepositTime[_nft];
    }

    function setLiquidityLastDepositTime(uint _nft, uint _time) public {
        liquidityLastDepositTime[_nft] = _time;
    }

    function setInitialTicksForPool(address _token0, address _token1, uint24 _fee, int24 _ticksUp, int24 _ticksDown) external  {
        setTicksUp(_token0, _token1, _fee, _ticksUp);
        setTicksDown(_token0, _token1, _fee, _ticksDown);
        setTicksUp(_token1, _token0, _fee, _ticksUp);
        setTicksDown(_token1, _token0, _fee, _ticksDown);
    }

    function _floor(int24 tick, int24 tickSpacing) public view returns (int24) {
        int24 compressed = tick / tickSpacing;
        if (tick < 0 && tick % tickSpacing != 0) compressed--;
        return compressed * tickSpacing;
    }

    function setRates(address _token0, address _token1, uint24 _fee, 
    int24 _ticksUp, int24 _ticksDown) public  {
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

    function sqrtRatios(address _token0, address _token1, uint24 _fee) 
    public returns (uint160 sqrtRatioX96, uint160 sqrtRatioAX96, 
    uint160 sqrtRatioBX96, uint160 sqrtPriceX96){
        address _factoryAddress = nonfungiblePositionManager.factory();
        Factory _factory = Factory(_factoryAddress);
        address _poolAddress = _factory.getPool(_token0, _token1, _fee);
        Pool pool = Pool(_poolAddress);
        int24 tick;
        (sqrtPriceX96, tick, , , , , ) = pool.slot0();
        sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);
        setRates( _token0,  _token1,  _fee, 
        getTicksUp(_token0, _token1, _fee), 
        getTicksDown(_token0, _token1, _fee));

        sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);
        return (sqrtRatioX96, sqrtRatioAX96, sqrtRatioBX96, sqrtPriceX96);
    }

    function setTicks(int24 _tickLower, int24 _tickUpper) public {
        tickLower = _tickLower;
        tickUpper = _tickUpper;
    }

    function getStatesCounter() public view returns (uint) {
        return statesCounter;
    }

    function setStatesCounter(uint _count) public returns(uint){
        statesCounter = _count;
    }

    function getTickLower() public view returns (int24) {
        return tickLower;
    }

    function setTickLower(int24 _tick) public returns(uint){
        tickLower = _tick;
    }

    function getTickUpper() public view returns (int24) {
        return tickUpper;
    }

    function setTickUpper(int24 _tick) public returns(uint){
        tickUpper = _tick;
    }

    function getPoolUpdateStateId(uint _nft, uint _state) public view returns (uint) {
        return poolUpdateStateId[_nft][_state];
    }

    function setPoolUpdateStateId(uint _nft, uint _state, uint _glogalState) public returns(uint){
        poolUpdateStateId[_nft][_state] = _glogalState;
    }

    function getLiquidityChangeCoef(uint _nft, uint _state) public view returns (uint) {
        return liquidityChangeCoef[_nft][_state];
    }

    function setLiquidityChangeCoef(uint _nft, uint _state, uint _coef) public returns(uint){
        liquidityChangeCoef[_nft][_state] = _coef;
    }
    ///

    function getTotalStatesForNft(uint _nft) public view returns (uint) {
        return totalStatesForNft[_nft];
    }

    function setTotalStatesForNft(uint _nft, uint _totalStates) public returns(uint){
        totalStatesForNft[_nft] = _totalStates;
    }

    function getStatesIdsForNft(uint _nft, uint _stateId) public view returns (uint){
        return statesIdsForNft[_nft][_stateId];
    }

    function setStatesIdsForNft(uint _nft, uint _stateId, uint _state) public {
        statesIdsForNft[_nft][_stateId] = _state;
    }

    function setTotalLiquidityAtStateForNft(uint _nft, uint _state, uint128 _liquidity) public {
        // require(msg.sender == yf, "not allowed");
        totalLiquidityAtStateForNft[_nft][_state] = _liquidity;
    }
    function getTotalLiquidityAtStateForNft(uint _nft, uint _state) public view returns(uint128){
        return totalLiquidityAtStateForNft[_nft][_state];
    }

    function setRewardAtStateForNftToken0(uint _nft, uint _state,uint128 _reward) internal {
        // require(msg.sender == yf, "not allowed");
        rewardAtStateForNftToken0[_nft][_state] = _reward;
    }
    function getRewardAtStateForNftToken0(uint _nft, uint _state) public view returns(uint){
        return rewardAtStateForNftToken0[_nft][_state];
    }

    function setRewardAtStateForNftToken1(uint _nft, uint _state,uint128 _reward) internal {
        // require(msg.sender == yf, "not allowed");
        rewardAtStateForNftToken1[_nft][_state] = _reward;
    }
    function getRewardAtStateForNftToken1(uint _nft, uint _state) public view returns(uint){
        return rewardAtStateForNftToken1[_nft][_state];
    }

    function setTicksUp(address _token0, address _token1, uint24 _fee, int24 _ticksUp) public {
        // require(msg.sender == yf, "not allowed");
        ticksUp[_token0][_token1][_fee] == _ticksUp;
    }
    function getTicksUp(address _token0, address _token1, uint24 _fee) public view returns(int24){
        return ticksUp[_token0][_token1][_fee];
    }

    function setTicksDown(address _token0, address _token1, uint24 _fee, int24 _ticksUp) public {
        // require(msg.sender == yf, "not allowed");
        ticksDown[_token0][_token1][_fee] == _ticksUp;
    }
    function getTicksDown(address _token0, address _token1, uint24 _fee) public view returns(int24){
        return ticksDown[_token0][_token1][_fee];
    }

    function updateRewardVariables(uint _originalNftId, uint _rewardAmount0, 
    uint _rewardAmount1, uint _counter) external {
        setRewardAtStateForNftToken0(_originalNftId, _counter, (uint128)(_rewardAmount0));
        setRewardAtStateForNftToken1(_originalNftId, _counter, (uint128)(_rewardAmount1));
    }

    function swapExess(address _token0, address _token1, 
    uint24 _fee, uint half) external returns (uint){
        ERC20 token0 = ERC20(_token0);
        ERC20 token1 = ERC20(_token1);
        ISwapRouter.ExactInputSingleParams memory _exactInputSingleParams;
        _exactInputSingleParams = ISwapRouter.ExactInputSingleParams(
            _token0, 
            _token1, 
            _fee, 
            address(this), 
            // block.timestamp + deadline,
            half,
            0,
            0
        );
        token0.transferFrom(address(yf), address(this), half);
        token0.approve(address(iSwapRouter), half);
        // return 0;
        uint256 amountOut = iSwapRouter.exactInputSingle(_exactInputSingleParams);
        
        token1.transfer(address(yf), amountOut);
        return amountOut; 
    }

    function getTotalLiquidityAtStateForPosition(uint _position, uint _state) 
    public view returns(uint128){
        uint _totalStateIdsForNft = totalStatesForNft[_position];
        // if(_state >= statesIdsForNft[_position][_totalStateIdsForNft]) {
        if(_state >= getStatesIdsForNft(_position,_totalStateIdsForNft)) {
            uint stateId = getStatesIdsForNft(_position,_totalStateIdsForNft);
            return getTotalLiquidityAtStateForNft(_position, stateId);
        }else{
            for(uint i = _totalStateIdsForNft ; i > 0; i--){
                if (getStatesIdsForNft(_position,i) <= _state){
                    return getTotalLiquidityAtStateForNft(_position, getStatesIdsForNft(_position,i));
                }
            }
        }
        return 0;
    }


    function updateLiquidityVariables(address _user, uint _originalNftId, 
                                      uint128 _newLiquidity, 
                                      bool _rebalance) public {
        setTotalLiquidityAtStateForNft(_originalNftId, getStatesCounter(), _newLiquidity) ;                               
        uint _totalStates;
        uint _stateId;
        uint128 oldLiquidityChangeCoef;

        _totalStates = getTotalStatesForNft(_originalNftId) - 1;
        _stateId = getStatesIdsForNft(_originalNftId,_totalStates);

        oldLiquidityChangeCoef = (uint128)(getLiquidityChangeCoef(_originalNftId,_stateId));
        if (_rebalance) {
            uint128 _liquidityBefore = getTotalLiquidityAtStateForPosition(_originalNftId, getStatesCounter() - 1);
            
            uint128 changeCoef;
            changeCoef = (oldLiquidityChangeCoef * _newLiquidity) / _liquidityBefore;

            setLiquidityChangeCoef(_originalNftId,getStatesCounter(), changeCoef);
            setPoolUpdateStateId(_originalNftId,getTotalStatesForNft(_originalNftId),getStatesCounter());

            return;
        }
        
        uint _userNftId = positionsNFT.getUserNftPerPool(_user, _originalNftId);

        if(oldLiquidityChangeCoef == 0) oldLiquidityChangeCoef = 1000000;

        setLiquidityChangeCoef(_originalNftId,getStatesCounter(), oldLiquidityChangeCoef);

        // liquidityLastDepositTime[_userNftId] = block.timestamp;
        setLiquidityLastDepositTime(_userNftId, block.timestamp);
        uint128 _previousLiq = getTotalLiquidityAtStateForPosition(_originalNftId, getStatesCounter() - 1);
        
        uint128 _changeCoefForLastLiquidity = getChangeCoefSinceLastUserUpdate(_originalNftId, _userNftId, 1);
        
        uint128 _previousLiqCorrected = _previousLiq;
        
        uint lastLiquidityUpdateStateForPosition = positionsNFT.totalStatesForPosition(_userNftId);
        
        uint userPositionLastUpdateState = 
        positionsNFT.getStatesIdsForPosition(_userNftId, lastLiquidityUpdateStateForPosition-1);
        
        uint128 _userLiq = positionsNFT.getLiquidityForUserInPoolAtState(_userNftId, userPositionLastUpdateState);
        uint128 _userLiqCorrected = (_userLiq * _changeCoefForLastLiquidity) / 1000000;
        
        if(_previousLiqCorrected > _newLiquidity){
            positionsNFT.updateLiquidityForUser(_userNftId, 
            _userLiqCorrected - (_previousLiqCorrected - _newLiquidity), 
            getStatesCounter());
        } else {
            positionsNFT.updateLiquidityForUser(_userNftId, 
            _userLiqCorrected + (_newLiquidity - _previousLiqCorrected), 
            getStatesCounter());
            
            setLiquidityLastDepositTime(_userNftId, block.timestamp);
        }
    }

    function getChangeCoefSinceLastUserUpdate(uint _originalNftId, uint _userNftId, uint correction) 
    public view returns(uint128){
        
        uint _totalPoolUpdates = getTotalStatesForNft(_originalNftId) ;
        if (_totalPoolUpdates < 1){
                return 1000000 ;
        }
        
        uint128 lastTicksUpdate = (uint128)(getPoolUpdateStateId(_originalNftId,_totalPoolUpdates));
        
        uint llustfp = positionsNFT.totalStatesForPosition(_userNftId);
        
        uint userPositionLastUpdateState = positionsNFT.getStatesIdsForPosition(_userNftId, llustfp - correction);
        
        if (userPositionLastUpdateState < 1){
                return 1000000 ;    
        }
        
        if(getLiquidityChangeCoef(_originalNftId,userPositionLastUpdateState) == 0) return 1000000;
        if(getLiquidityChangeCoef(_originalNftId,lastTicksUpdate) == 0) return 1000000;

        
        return (uint128)(1000000*
        (uint128)(getLiquidityChangeCoef(_originalNftId,lastTicksUpdate)))/
        (uint128)(getLiquidityChangeCoef(_originalNftId,userPositionLastUpdateState));
    }

    function updateStateCounters(uint _originalNftId, uint _userNftId, address sender) public {
        setTotalStatesForNft(_originalNftId, getTotalStatesForNft(_originalNftId) +1);
        setStatesCounter(getStatesCounter() + 1);
        setStatesIdsForNft(_originalNftId, getTotalStatesForNft(_originalNftId), getStatesCounter());

        if(_userNftId == 0) return; 
        uint positionNftId = positionsNFT.getUserNftPerPool(sender, _originalNftId);
        positionsNFT.updateStatesIdsForPosition(positionNftId, getStatesCounter());  

        uint _totalStates = getTotalStatesForNft(_originalNftId) - 1;
        uint _stateId = getStatesIdsForNft(_originalNftId,_totalStates);
        uint oldLiquidityChangeCoef = getLiquidityChangeCoef(_originalNftId,_stateId);
        setPoolUpdateStateId(_originalNftId, getTotalStatesForNft(_originalNftId), getStatesCounter());
        // return;
    }
}