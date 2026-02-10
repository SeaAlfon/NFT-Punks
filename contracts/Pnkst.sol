// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Интерфейс для взаимодействия с магазином
interface IStitchedPunksShop {
    function updateOrderRedeemNFT(uint16 punkIndex) external;
}

contract StitchedPunksNFT is Ownable, ERC721 {
    using Strings for uint256;

    // Адрес контракта магазина
    address public stitchedPunksShopAddress;

    // Базовый URI для метаданных
    string private _currentBaseURI;

    /**
     * @dev Конструктор требует initialOwner для Ownable (в OpenZeppelin v5.0+)
     */
    constructor(address initialOwner) 
        ERC721("StitchedPunksToken", "SPT") 
        Ownable(initialOwner) 
    {
        _currentBaseURI = "https://stitchedpunks.com/metadata/";
        
        // Рекомендуется задавать адрес внешнего контракта здесь, а не хардкодить
        stitchedPunksShopAddress = 0x9f4263370872b44EF46477DC9Bc67ca938e129c6;
    }

    // --- Управление настройками ---

    function setStitchedPunksShopAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Invalid address");
        stitchedPunksShopAddress = newAddress;
    }

    function setMetadataBaseUri(string memory newUri) external onlyOwner {
        _currentBaseURI = newUri;
    }

    // --- Переопределения ERC721 ---

    /**
     * @dev Внутренняя функция, используемая ERC721 для получения базового пути.
     * Мы переопределяем её вместо использования удаленного метода _setBaseURI.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseURI;
    }

    /**
     * @dev Возвращает URI токена с добавлением ".json"
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId); // Проверка существования токена (OZ v5)
        
        string memory base = _baseURI();
        return bytes(base).length > 0 
            ? string(abi.encodePacked(base, tokenId.toString(), ".json")) 
            : "";
    }

    /**
     * @dev Метаданные уровня контракта (для OpenSea)
     */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), "StitchedPunksNFT.json"));
    }

    // --- Минтинг ---

    function mintToken(uint16 punkIndex, address receiverAddress) external onlyOwner {
        // Проверка адреса перед минтом
        require(receiverAddress != address(0), "Invalid receiver");

        // Минтим токен
        _safeMint(receiverAddress, punkIndex);

        // Обновляем статус заказа во внешнем контракте
        // ВАЖНО: Если вызов updateOrderRedeemNFT упадет (revert), то и минт откатится.
        IStitchedPunksShop(stitchedPunksShopAddress).updateOrderRedeemNFT(punkIndex);
    }
}