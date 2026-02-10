// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IStitchedPunksShop {
    function updateOrderRedeemNFT(uint16 punkIndex) external;
}

contract StitchedPunksNFT is Ownable, ERC721 {
    using Strings for uint256;

    address public stitchedPunksShopAddress;
    string private _currentBaseURI;

    // В OpenZeppelin v5 конструктор Ownable требует аргумент.
    // Мы передаем msg.sender, чтобы тот, кто деплоит, стал владельцем.
    constructor() ERC721("StitchedPunksToken", "SPT") Ownable(msg.sender) {
        _currentBaseURI = "https://stitchedpunks.com/metadata/";
        stitchedPunksShopAddress = 0x9f4263370872b44EF46477DC9Bc67ca938e129c6;
    }

    function setStitchedPunksShopAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Invalid address");
        stitchedPunksShopAddress = newAddress;
    }

    function setMetadataBaseUri(string memory newUri) external onlyOwner {
        _currentBaseURI = newUri;
    }

    // Переопределяем внутреннюю функцию для возврата Base URI
    function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        // ИСПРАВЛЕНИЕ: В v5 вместо _exists используем _requireOwned
        _requireOwned(tokenId); 
        
        string memory base = _baseURI();
        return bytes(base).length > 0 
            ? string(abi.encodePacked(base, tokenId.toString(), ".json")) 
            : "";
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), "StitchedPunksNFT.json"));
    }

    function mintToken(uint16 punkIndex, address receiverAddress) external onlyOwner {
        require(receiverAddress != address(0), "Invalid receiver");
        _safeMint(receiverAddress, punkIndex);
        IStitchedPunksShop(stitchedPunksShopAddress).updateOrderRedeemNFT(punkIndex);
    }
}