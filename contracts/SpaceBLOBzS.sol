// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SpaceBLOBzS is ERC721A, Ownable {

    // config
    constructor(address initialOwner)
        ERC721A("Space BLOBz S", "SPACEBLOBZS")
        Ownable(initialOwner) {
    }
    uint256 public MAX_SUPPLY = 48_440;
    uint256 public MAX_MINT_PER_WALLET = 48_440;
    uint256 public START_ID = 1;

    bool public mintEnabled = true;
    string public baseURI = "https://bored-town.github.io/cdn/assets/space-blobz-s.gif";
    IERC20 public token;
    uint256 public mintPrice = 10_000_000_000 * 10**18; // 10B token

    // start token id
    function _startTokenId() internal view virtual override returns (uint256) {
        return START_ID;
    }

    // metadata
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory jsonPreImage = string.concat(
            string.concat(
                string.concat('{"name": "Space BLOBz S #', Strings.toString(tokenId)),
                '","description":"This NFT will then grant you access to claim $BLZ on the Base chain on September 22, 2024","image":"'
            ),
            baseURI
        );
        string memory jsonPostImage = '"}';
        return
            string.concat(
                "data:application/json;utf8,",
                string.concat(jsonPreImage, jsonPostImage)
            );
    }

    // token
    function setToken(address newToken) external onlyOwner {
        token = IERC20(newToken);
    }
    function setMintPrice(uint256 _newMintPrice) external onlyOwner {
        mintPrice = _newMintPrice;
    }
    function withdraw(uint256 amount) external onlyOwner {
        require(token.transfer(msg.sender, amount), "Transfer token failed");
    }

    // toggle sale
    function toggleSale() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    // mint
    function mint(uint quantity, bytes32[] calldata _merkleProof) external {
        require(mintEnabled, "Sale is not enabled");
        require(_numberMinted(msg.sender) + quantity <= MAX_MINT_PER_WALLET, "Over wallet limit");

        uint256 totalPrice = mintPrice * quantity;
        require(token.balanceOf(msg.sender) >= totalPrice, "Insufficient funds");
        require(token.transferFrom(msg.sender, address(this), totalPrice), "Payment failed");
        
        _checkSupplyAndMint(msg.sender, quantity);
    }
    function adminMint(uint quantity) external onlyOwner {
        _checkSupplyAndMint(msg.sender, quantity);
    }
    function _checkSupplyAndMint(address to, uint256 quantity) private {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Over supply");

        _mint(to, quantity);
    }

    // aliases
    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }
    function remainingSupply() external view returns (uint256) {
        return MAX_SUPPLY - _totalMinted();
    }

}
