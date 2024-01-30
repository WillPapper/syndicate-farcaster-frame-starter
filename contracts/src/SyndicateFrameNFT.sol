// SPDX-License-Identifier: MIT
// By Will Papper

pragma solidity ^0.8.20;

import {ERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721//ERC721.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract SyndicateFrameNFT is ERC721, Ownable {
    uint256 public currentTokenId = 0;
    // Change this to your own defaultURI
    string public defaultURI = "ipfs://QmcH4hTJQKo5PELUoEVbNJtzuVt9AHsLTDURj3r5K32X6t";

    mapping(address authorizedMinter => bool authorized) public authorizedMinters;
    mapping(uint256 tokenId => string tokenURI) public tokenURIs;
    mapping(uint256 tokenId => bool locked) public lockedTokenURIs;

    event DefaultTokenURISet(string tokenURI);
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
        emit AuthorizedMinterSet(msg.sender, true);

        // Authorize Syndicate's API-based wallet pool as a minter on Base
        // Mainnet
        authorizeBaseMainnetSyndicateAPI();
    }

    // This function is currently the only supported function in the
    // frame.syndicate.io API
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

    // This function is not yet supported in the frame.syndicate.io API
    // We will update this example repository when it is supported!
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

    // Set the token URI for all tokens that don't have a custom tokenURI set.
    // Must be called by the owner given its global impact on the collection
    function setDefaultTokenURI(string memory _tokenURI) public onlyOwner {
        defaultURI = _tokenURI;
        emit DefaultTokenURISet(_tokenURI);
    }

    // If you'd like to use an ID-based tokenURI (e.g. /1, /2, etc), you can
    // override this function The majority of Frames use cases are relying on
    // dynamically generated data, so our assumption is that a separate URI for
    // each token + a default URI for unset tokens is the most useful
    // If you'd prefer an ID-based structure, you can override this function to
    // enable that instead
    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        if (bytes(tokenURIs[tokenId]).length > 0) {
            return tokenURIs[tokenId];
        } else {
            return defaultURI;
        }
    }

    // Only the owner can set authorized minters. True = authorized, false =
    // unauthorized
    function setAuthorizedMinter(address minter, bool authorized) public onlyOwner {
        authorizedMinters[minter] = authorized;

        emit AuthorizedMinterSet(minter, authorized);
    }

    // These addresses are for Base Mainnet only. Contact @will on Farcaster
    // or @WillPapper on Telegram if you need other networks
    // If you've set up your own Syndicate account, you can change this function
    // to your own wallet addresses
    function authorizeBaseMainnetSyndicateAPI() internal {
        authorizedMinters[0x3D0263e0101DE2E9070737Df30236867485A5208] = true;
        authorizedMinters[0x98407Cb54D8dc219d8BF04C9018B512dDbB96caB] = true;
        authorizedMinters[0xF43A72c1a41b7361728C83699f69b5280161F0A5] = true;
        authorizedMinters[0x94702712BA81C0D065665B8b0312D87B190EbA37] = true;
        authorizedMinters[0x10FD71C6a3eF8F75d65ab9F3d77c364C321Faeb5] = true;

        emit AuthorizedMinterSet(0x3D0263e0101DE2E9070737Df30236867485A5208, true);
        emit AuthorizedMinterSet(0x98407Cb54D8dc219d8BF04C9018B512dDbB96caB, true);
        emit AuthorizedMinterSet(0xF43A72c1a41b7361728C83699f69b5280161F0A5, true);
        emit AuthorizedMinterSet(0x94702712BA81C0D065665B8b0312D87B190EbA37, true);
        emit AuthorizedMinterSet(0x10FD71C6a3eF8F75d65ab9F3d77c364C321Faeb5, true);
    }

    fallback() external payable {
        revert("FrameNFTs: Does not accept ETH");
    }
}
