# dynamic-liquidity providing 

I. Smart contracts description

To handle the shared liquidity managment accross a uniswap v3 position we use two smart contracts: 
 PositionNFT contract: 
 Inherits from ERC721 standard and allow to track users positions 
 Each NFT from this contract is a fraction of the Uniswap V3 position NFT

 YfSc contract: 
 Manages the following functions: 
 1. Interractions with uniswap v3 
 2. Mint and hold univ3 positions NFT
 3. Mint positions fractins NFT from PositionNFT contract 
 4. Allow users to invest/withdraw in uni v3 liquidity pools 
 5. handle yield distributions among investers 

 II. investments tracking and yield distribution

 To track investments, liquidity and rewards, we use an internal state counter. 

 If we use a global variable like block numner or block timestamp, we can have an issue in calculation in case if multi state changes in the same block. 

 Given the fact that the reward amounts is not regular overtime, we need to identify all the liquidity states in the smart contract, that's why we use the variable statesCounters. 

 We increment the states counter every time one of the following actions takes place: 

 1. User deposits/removes liquidity,
 2. User mints/burn/updates Uniswap v3 NFT,
 3. User claims reward.

 We avoid using lists to track the states changes to avoid reaching the smart contract limit. We only use the following mappings: 

 1. mapping(uint=>mapping(uint=>uint128)) public liquidityForUserInPoolAtState
 Allows to retrieve the total liquidity held by the user in a given pool in a given state 
 The first variable is the user poisiotn NFT id and the second is the state id the snapshot was taken in

 2. mapping(uint => uint) public totalStatesForPosition:
 We need to track the numbers of states the position liquidity has changed. That way we have to loop only through that position states changes to calculate the corresponding reward 

 3. mapping(uint => uint) public totalStatesForPosition:
 For each position, we will store the number of states changes to be able to loop from the last reward distribution state to the current state

 4. mapping(uint=>uint) public liquidityLastStateUpdate: 
 For a given Uniswap v3 position NFT, we store the last state, this position was updated. This is usefull because the smart contract is designed to handle multi uniswap v3 positions 

 5. mapping(uint => mapping(uint => uint128)) public totalLiquidityAtStateForNft:
 This allows to storethe liquidity amount deposited for a given uniswap v3 position at a given state 

6. mapping(uint => mapping(uint => uint)) public statesIdsForNft: idem PositionNFT

7. mapping(uint => uint) public totalStatesForNft:  idem PositinNFT