// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@fhevm/solidity/lib/FHE.sol";
import {SepoliaConfig} from "./fhevm-config/ZamaConfig.sol";

contract RealEstateNFT is ERC721, ERC721URIStorage, SepoliaConfig {
    uint256 private _tokenIdCounter;
    address private _admin;

    struct Property {
        string propertyAddress;
        euint32 area;
        string propertyType;
        euint32 value;
        bool isActive;
    }

    mapping(uint256 => Property) public properties;

    event PropertyMinted(uint256 indexed tokenId, address owner, string propertyAddress, string propertyType);
    event PropertyUpdated(uint256 indexed tokenId, string propertyAddress, string propertyType);
    event PropertyDeactivated(uint256 indexed tokenId);

    constructor() ERC721("RealEstateNFT", "RENFT") {
        _tokenIdCounter = 0;
        _admin = msg.sender;
    }

    function mintProperty(
        address recipient,
        string memory propertyAddress,
        externalEuint32 areaHandle,
        bytes calldata areaHandleProof,
        string memory propertyType,
        externalEuint32 valueHandle,
        bytes calldata valueHandleProof,
        string memory _tokenURI // 👈 renamed to avoid conflict with function
    ) public returns (uint256) {
        require(bytes(propertyAddress).length > 0, "Property address proof cannot be empty");
        require(bytes(propertyType).length > 0, "Property type cannot be empty");
        require(areaHandleProof.length > 0, "Area handle proof cannot be empty");
        require(valueHandleProof.length > 0, "Value handle proof cannot be empty");

        euint32 area = FHE.fromExternal(areaHandle, areaHandleProof);
        euint32 value = FHE.fromExternal(valueHandle, valueHandleProof);

        _tokenIdCounter = _tokenIdCounter + 1;
        uint256 newTokenId = _tokenIdCounter;

        _mint(recipient, newTokenId);
        _setTokenURI(newTokenId, _tokenURI);

        properties[newTokenId] = Property({
            propertyAddress: propertyAddress,
            area: area,
            propertyType: propertyType,
            value: value,
            isActive: true
        });

        FHE.allowThis(properties[newTokenId].area);
        FHE.allowThis(properties[newTokenId].value);
        FHE.allow(properties[newTokenId].area, msg.sender);
        FHE.allow(properties[newTokenId].value, msg.sender);

        emit PropertyMinted(newTokenId, recipient, propertyAddress, propertyType);
        return newTokenId;
    }

    function updateProperty(
        uint256 tokenId,
        string memory propertyAddress,
        externalEuint32 areaHandle,
        bytes calldata areaHandleProof,
        string memory propertyType,
        externalEuint32 valueHandle,
        bytes calldata valueHandleProof
    ) public {
        require(_exists(tokenId), "Token does not exist");
        require(properties[tokenId].isActive, "Property is not active");
        require(bytes(propertyAddress).length > 0, "Property address cannot be empty");
        require(bytes(propertyType).length > 0, "Property type cannot be empty");

        euint32 area = FHE.fromExternal(areaHandle, areaHandleProof);
        euint32 value = FHE.fromExternal(valueHandle, valueHandleProof);

        properties[tokenId].propertyAddress = propertyAddress;
        properties[tokenId].area = area;
        properties[tokenId].propertyType = propertyType;
        properties[tokenId].value = value;

        FHE.allowThis(properties[tokenId].area);
        FHE.allowThis(properties[tokenId].value);
        FHE.allow(properties[tokenId].area, msg.sender);
        FHE.allow(properties[tokenId].value, msg.sender);

        emit PropertyUpdated(tokenId, propertyAddress, propertyType);
    }

    function deactivateProperty(uint256 tokenId) public {
        require(_exists(tokenId), "Token does not exist");
        require(properties[tokenId].isActive, "Property is already deactivated");

        properties[tokenId].isActive = false;
        emit PropertyDeactivated(tokenId);
    }

    function getPropertyDetails(
        uint256 tokenId
    ) public view returns (string memory propertyAddress, string memory propertyType, bool isActive) {
        require(_exists(tokenId), "Token does not exist");
        Property memory prop = properties[tokenId];
        return (prop.propertyAddress, prop.propertyType, prop.isActive);
    }

    function burn(uint256 tokenId) public {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not the token owner");
        _burn(tokenId);
        delete properties[tokenId];
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        try this.ownerOf(tokenId) returns (address) {
            return true;
        } catch {
            return false;
        }
    }

    function getAdmin() public view returns (address) {
        return _admin;
    }
}
