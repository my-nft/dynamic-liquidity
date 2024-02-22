
import './utils.sol';

contract PositionsNFT is ERC721, AccessControl {
    using Counters for Counters.Counter;

    // bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;

    mapping(address => mapping(uint=>uint)) public userNftPerPool;

    mapping(uint=>mapping(uint=>uint128)) public liquidityForUserInPoolAtState; // nft --> state --> liquidity 
    mapping(uint=>mapping(uint=>uint128)) public userShareInPoolAtState; // nft --> state --> liquidity 
    
    mapping(uint => mapping(uint => uint)) public statesIdsForPosition;

    mapping(uint => uint) public totalStatesForPosition;

    mapping(uint => uint) public lastClaimForPosition;

    mapping(uint => uint) public totalClaimedforPositionToken0;
    mapping(uint => uint) public totalClaimedforPositionToken1;

    constructor() ERC721("Yf Sc Positions NFT", "YSP_NFT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _tokenIdCounter.increment(); // to start from 1
    }


    function safeMint(uint _uniswapNftId, address _receiver, uint128 _liquidity, uint _state) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_receiver, tokenId);
        userNftPerPool[_receiver][_uniswapNftId] = tokenId;   
    }

    function getUserNftPerPool(address receiver, uint uniswapNftId) view public returns (uint) {
        return userNftPerPool[receiver][uniswapNftId];
    }

    function updateLiquidityForUser(uint positionNftId, uint128 _liquidity, uint _state)public onlyRole(MINTER_ROLE) {
        liquidityForUserInPoolAtState[positionNftId][_state] = _liquidity;

        statesIdsForPosition[positionNftId][totalStatesForPosition[positionNftId]] = _state;   
    }

    function updateStatesIdsForPosition(uint positionNftId, uint _state)public onlyRole(MINTER_ROLE) {
        totalStatesForPosition[positionNftId]++;
        statesIdsForPosition[positionNftId][totalStatesForPosition[positionNftId]] = _state;
    }

    function updateLastClaimForPosition(uint _positionNftId, uint _state)public onlyRole(MINTER_ROLE) {
        lastClaimForPosition[_positionNftId] = _state;
    }

    function updateTotalClaimForPosition(uint _positionNftId, uint _newClaim0, uint _newClaim1)public onlyRole(MINTER_ROLE) {
        totalClaimedforPositionToken0[_positionNftId] += _newClaim0;
        totalClaimedforPositionToken1[_positionNftId] += _newClaim1;
    }

    function getLiquidityForUserInPoolAtState(uint _userPositionNft, uint _state) public view returns(uint128 liquidity){
        // we need to handle the case update liquidity
        uint _totalStateIdsForPosition = totalStatesForPosition[_userPositionNft];
        if(_state >= statesIdsForPosition[_userPositionNft][_totalStateIdsForPosition]) {
            uint stateId = statesIdsForPosition[_userPositionNft][_totalStateIdsForPosition];
            return liquidityForUserInPoolAtState[_userPositionNft][stateId];
        }else{
            for(uint i = _totalStateIdsForPosition ; i > 0; i--){
                // if (statesIdsForPosition[_userPositionNft][i] <= _state){
                if (statesIdsForPosition[_userPositionNft][i] <= _state){
                    return liquidityForUserInPoolAtState[_userPositionNft][statesIdsForPosition[_userPositionNft][i]];
                }
            }
        }
        return 0;
    }

    function getUserShareInPoolAtState(uint _userPositionNft, uint _state) public view returns(uint128 liquidity){
        // we need to handle the case update liquidity
        uint _totalStateIdsForPosition = totalStatesForPosition[_userPositionNft];
        if(_state >= statesIdsForPosition[_userPositionNft][_totalStateIdsForPosition]) {
            uint stateId = statesIdsForPosition[_userPositionNft][_totalStateIdsForPosition];
            return userShareInPoolAtState[_userPositionNft][stateId];
        }else{
            for(uint i = _state ; i > 0; i--){
                if (statesIdsForPosition[_userPositionNft][i] <= _state){
                    return userShareInPoolAtState[_userPositionNft][statesIdsForPosition[_userPositionNft][i]];
                }
            }
        }
        return 0;
    }

    function getStatesIdsForPosition(uint _userPositionNft, uint _stateId) public view returns(uint id){
        return statesIdsForPosition[_userPositionNft][_stateId];
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
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