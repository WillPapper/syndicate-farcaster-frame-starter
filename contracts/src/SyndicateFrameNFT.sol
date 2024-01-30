// SPDX-License-Identifier: MIT
// By Will Papper

pragma solidity ^0.8.20;

import {ERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721//ERC721.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract SyndicateFrameNFT is ERC721, Ownable {
    uint256 public currentTokenId = 0;
    address internal constant INITIAL_MINTER = 0x3D0263e0101DE2E9070737Df30236867485A5208;
    // Change this to your own baseURI
    string public baseURI = "ipfs://";

    mapping(address authorizedMinter => bool authorized) public authorizedMinters;
    mapping(uint256 tokenId => string tokenURI) public tokenURIs;
    mapping(uint256 tokenId => bool locked) public lockedTokenURIs;

    event TokenURISet(uint256 indexed tokenId, string tokenURI);
    event TokenURILocked(uint256 indexed tokenId);
    event AuthorizedMinterSet(address indexed minter, bool authorized);

    modifier onlyAuthorizedMinter() {
        require(authorizedMinters[msg.sender], "FrameNFTs: Mint must be triggered by API");
        _;
    }

    modifier onlyUnlockedTokenURI(uint256 tokenId) {
        require(!lockedTokenURIs[tokenId], "FrameNFTs: Token URI is locked");
        _;
    }

    // The deployer is set as the initial owner by default. Make sure to
    // transfer this to a Safe or other multisig for long-term use!
    // You can call `transferOwnership` to do this.
    constructor() ERC721("SyndicateFrameNFT", "SYNFRAME") Ownable(msg.sender) {
        // The deployer is set as an authorized minter, allowing them to set up
        // owner mints manually via the contract as needed
        authorizedMinters[msg.sender] = true;

        // Authorize Syndicate's API as a minter
        authorizedMinters[INITIAL_MINTER] = true;

        emit AuthorizedMinterSet(msg.sender, true);
        emit AuthorizedMinterSet(INITIAL_MINTER, true);
    }

    // This function is currently the only supported function in the frame.syndicate.io API
    function mint(address to) public onlyAuthorizedMinter {
        ++currentTokenId;
        _mint(to, currentTokenId);
    }

    // This function is not yet supported in the frame.syndicate.io API
    // We will update this example repository when it is supported!
    function mint(address to, string memory _tokenURI) public onlyAuthorizedMinter {
        ++currentTokenId;
        tokenURIs[currentTokenId] = _tokenURI;
        _mint(to, currentTokenId);

        emit TokenURISet(currentTokenId, _tokenURI);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI)
        public
        onlyAuthorizedMinter
        onlyUnlockedTokenURI(tokenId)
    {
        tokenURIs[tokenId] = _tokenURI;

        emit TokenURISet(tokenId, _tokenURI);
    }

    // Since this action is irreversible, we require the owner to call it
    function lockTokenURI(uint256 tokenId) public onlyOwner {
        lockedTokenURIs[tokenId] = true;

        emit TokenURILocked(tokenId);
    }

    function setDefaultTokenURI(string memory _tokenURI) public onlyOwner {
        baseURI = _tokenURI;
    }

    function _baseURI() internal view virtual override(ERC721) returns (string memory) {
        return baseURI;
    }

    function setAuthorizedMinter(address minter, bool authorized) public onlyOwner {
        authorizedMinters[minter] = authorized;

        emit AuthorizedMinterSet(minter, authorized);
    }

    fallback() external payable {
        revert("FrameNFTs: Does not accept ETH");
    }
}
