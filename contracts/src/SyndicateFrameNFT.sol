// SPDX-License-Identifier: MIT
// By David Murray
// check_sometingNFT contract 

pragma solidity ^0.8.20;

import {ERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721//ERC721.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {Base64} from "../lib/openzeppelin/contracts/utils/Base64.sol";

contract check_somethingNFT is ERC721, Ownable {
    uint256 public currentTokenId = 0;
    string public defaultURI;

    mapping(address authorizedMinter => bool authorized) public authorizedMinters;
    mapping(uint256 tokenId => string tokenURI) public tokenURIs;
    mapping(uint256 tokenId => bool locked) public lockedTokenURIs;

    // Keep track of mint limits
    uint256 public maxMintPerAddress;
    mapping(address minted => uint256 count) public mintCount;

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

    modifier onlyBelowMaxMint(address to) {
        require(mintCount[to] < maxMintPerAddress, "FrameNFTs: Max mint reached");
        _;
    }

    // The deployer is set as the initial owner by default. Make sure to
    // transfer this to a Safe or other multisig for long-term use!
    // You can call `transferOwnership` to do this.
    constructor() ERC721("SyndicateFrameNFT", "SYNFRAME") Ownable(msg.sender) {
        // Update this with your own NFT collection's metadata
        defaultURI = "ipfs://QmSFqezaUhBKr32Z2vgFrbDPGYdbcj8zQcQvsDqbU6b6UH";
        maxMintPerAddress = 1;

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
    function mint(address to) public onlyAuthorizedMinter onlyBelowMaxMint(to) {
        ++currentTokenId;
        ++mintCount[to];
        _mint(to, currentTokenId);
    }
    // Add your new SVG generation function here
    function generateSVG(uint256 tokenId) internal view returns (string memory) {
        // Use blockhash as seed for pseudo-randomness
        uint256 seed = uint256(blockhash(block.number - 1)) + tokenId;
        bytes memory svgBytes = abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" width="120" height="120">');
        for (uint i = 0; i < 12; i++) {
            for (uint j = 0; j < 12; j++) {
                // Generate color for each pixel
                string memory color = pseudoRandomColor(seed, i, j);
                svgBytes = abi.encodePacked(
                    svgBytes,
                    '<rect x="', uint2str(i * 10), '" y="', uint2str(j * 10), '" width="10" height="10" fill="', color, '" />'
                );
            }
        }
        svgBytes = abi.encodePacked(svgBytes, '</svg>');
        return string(svgBytes);
    }

    function pseudoRandomColor(uint256 seed, uint i, uint j) private pure returns (string memory) {
        uint rand = uint(keccak256(abi.encodePacked(seed, i, j))) % 100;
        if (rand < 70) {
            return '#000000'; // Black 70% probability
        } else if (rand < 80) {
            return '#FF0000'; // Red 10% probability
        } else if (rand < 90) {
            return '#0000FF'; // Blue 10% probability
        } else {
            return '#00FF00'; // Green 10% probability
        }
        // Add more colors as needed
    }

    // This function is not yet supported in the frame.syndicate.io API
    // We will update this example repository when it is supported!
    function mint(address to, string memory _tokenURI) public onlyAuthorizedMinter onlyBelowMaxMint(to) {
        ++currentTokenId;
        ++mintCount[to];
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
    // Override the existing tokenURI function to include the SVG logic
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (bytes(_tokenURIs[tokenId]).length > 0) {
            return _tokenURIs[tokenId];
        } else {
            // Generate the SVG and encode it as a data URI
            string memory svg = generateSVG(tokenId);
            string memory svgBase64Encoded = Base64.encode(bytes(svg));
            return string(abi.encodePacked("data:image/svg+xml;base64,", svgBase64Encoded));
        }
    }

    // Only the owner can set the max mint per address
    function setMaxMintPerAddress(uint256 _maxMintPerAddress) public onlyOwner {
        maxMintPerAddress = _maxMintPerAddress;
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

    // This function ensures that ETH sent directly to the contract by mistake
    // is rejected
    fallback() external payable {
        revert("FrameNFTs: Does not accept ETH");
    }
    // Helper function to convert uint to string
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
}
