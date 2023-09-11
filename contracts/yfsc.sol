//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract PositionsNFT is ERC721, Pausable, AccessControl, ERC721Burnable {
    using Counters for Counters.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Yf Sc Positions NFT", "YSP_NFT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function safeMint(address to) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
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

    PositionsNFT positionsNFT;


    /**
     * Contract initialization.
     */

    /// @notice Deploys the smart 
    /// @dev Assigns `msg.sender` to the owner state variable
    constructor(PositionsNFT _positionsNFT) {
        positionsNFT = _positionsNFT;
        owner = msg.sender;
    }

    /// @notice Allow user to deposit liquidity and mint corresponding NFT
    /// @dev Public function
    /// @param _token0 The first token of the liquidity pool pair
    /// @param _token1 The second token of the liquidity pool pair
    /// @param _fee The desired fee for the pool  
    /// @param _tokenToDeposit 0 for _token0, 1 for _token1
    /// @param _amount The amount of tokens `account` will receive
    function mintNFT(address _token0, address _token1, uint _fee, uint _tokenToDeposit, uint _amount) public {
        // check if pair/fee exists otherwise revert
        // transfer _tokenToDeposit from user's walet to YfSc
        // and provide liqudity (suppose uniswap handles the swap 
        // of half tokens to the second pool token)
        // Store/Update UNIV3 NFT
        // Mint/update user NFT
        // positionsNFT.safeMint(msg.sender, );
    }

    /// @notice Provide liquidity to a pair pool for a specified fee
    /// @dev Internal function, called by mintNFT function
    /// @param _token0 The first token of the liquidity pool pair
    /// @param _token1 The second token of the liquidity pool pair
    /// @param _fee The desired fee for the pool  
    /// @param _amount The amount of tokens `account` will receive
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