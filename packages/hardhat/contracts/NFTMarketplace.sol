// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTMarketplace is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemSales;

    address private _tokenAddress;

    mapping(uint256 => uint256) private _itemPrices;
    mapping(uint256 => address) private _itemSellers;
    mapping(uint256 => bool) private _itemSold;

    event ItemListed(uint256 indexed itemId, uint256 price, address seller);
    event ItemSold(uint256 indexed itemId, uint256 price, address seller, address buyer);
    event TokenBurnt(uint256 indexed itemId);

    constructor(address tokenAddress) {
        _tokenAddress = tokenAddress;
    }

    function listNewItem(uint256 price) external {
        require(price > 0, "Price cannot be zero");
        
        _itemIds.increment();
        uint256 itemId = _itemIds.current();
        _itemPrices[itemId] = price;
        _itemSellers[itemId] = msg.sender;
        _itemSold[itemId] = false;
        
        emit ItemListed(itemId, price, msg.sender);
    }

    function buyItem(uint256 itemId) external payable {
        require(_itemIds.current() >= itemId, "Item does not exist");
        require(!_itemSold[itemId], "Item is already sold");
        require(msg.value >= _itemPrices[itemId], "Insufficient payment");

        address seller = _itemSellers[itemId];
        payable(seller).transfer(msg.value);

        _itemSales.increment();
        _itemSold[itemId] = true;

        emit ItemSold(itemId, _itemPrices[itemId], seller, msg.sender);
    }

    function burnToken(uint256 itemId) external {
        require(_itemIds.current() >= itemId, "Item does not exist");
        require(_itemSold[itemId], "Token must be sold before burning");

        _burn(itemId);

        emit TokenBurnt(itemId);
    }

    function getItemPrice(uint256 itemId) external view returns (uint256) {
        return _itemPrices[itemId];
    }

    function isItemSold(uint256 itemId) external view returns (bool) {
        return _itemSold[itemId];
    }

    function _burn(uint256 itemId) private {
        ERC721(_tokenAddress).safeTransferFrom(_itemSellers[itemId], address(0), itemId);
        delete _itemPrices[itemId];
        delete _itemSellers[itemId];
        _itemSold[itemId] = false;
    }
}