// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC5192.sol";

/// @title CarMaintenanceBook - A contract for a vehicle maintenance NFT and record-keeping
/// @author MaxVast
/// @dev Implementation Openzeppelin's Ownable, ERC721 and Interface IERC5192
contract CarMaintenanceBook is ERC721, Ownable, IERC5192 {
    /// @notice Struct to store information about each NFT.
    /// @dev The TokenData structure includes the URI associated with the NFT and a flag indicating whether the NFT is locked.
    struct TokenData {
        string uri; // The URI associated with the NFT.
        bool locked; // A flag indicating whether the NFT is locked (i.e., cannot be transferred).
    }

    /// @notice Struct to store information about each maintenance event.
    /// @dev The Maintenance structure includes details about the maintenance performed, such as the type of maintenance and the date it occurred.
    struct Maintenance {
        string maintenance; // Details about the maintenance performed.
        string description; // Description about the maintenance performed.
        uint256 mileage; // Mileage about the vehicle.
        uint256 dateMaintenance; // The timestamp indicating when the maintenance occurred.
    }

    /// @notice Mapping from Token ID to a list of maintenance events.
    /// @dev The Maintenances mapping stores an array of Maintenance structures for each Token ID,
    /// providing a history of maintenance events associated with each NFT.
    mapping(uint256 => Maintenance[]) Maintenances;

    /// @notice Mapping from Token ID to TokenData.
    /// @dev The tokenData mapping associates each Token ID with its corresponding TokenData structure,
    /// storing information such as the URI and the lock status of the NFT.
    mapping(uint256 => TokenData) private tokenData;

    /// @notice Mapping from Token ID to claim status.
    /// @dev The claimedTokens mapping tracks whether a specific Token ID has been claimed or not.
    mapping(uint256 => bool) claimedTokens;

    /// @notice Mapping from Token ID to the owner's address.
    /// @dev The balance mapping associates each Token ID with the address of its owner,
    /// indicating the current owner of each NFT.
    mapping(uint256 => address) public balance;

    /// @notice Emitted when the token is claimed.
    /// @dev If a token is claimed, this event should be emitted.
    /// @param user The address of the user claiming the token.
    /// @param idToken The identifier for a token.
    event TokenClaimed(address indexed user, uint256 idToken);

    /// @notice Modifier to ensure that a token can be transferred only if it is not locked.
    modifier IsTransferAllowed(uint256 _tokenId) {
        require(!tokenData[_tokenId].locked, "Token is locked");
        _;
    }

    /// @notice Modifier to ensure that a token with the specified ID exists.
    modifier tokenIsExists(uint256 _idToken) {
        require(claimedTokens[_idToken], "Token not exists");
        _;
    }

    /// @dev Constructor to initialize the ERC721 token with a name and symbol.
    constructor() ERC721("AutoChain Ledger", "ACL") Ownable(msg.sender) { }

    /// @notice Claims an NFT and sends it to the specified address.
    /// @dev Only distributors can mint tokens, and each token is associated with a URI.
    /// @param _to The address to which the NFT will be sent.
    /// @param _idToken The identifier for the token.
    /// @param _uri The URI associated with the token.
    function safeMint(address _to, uint256 _idToken, string calldata _uri) external onlyOwner {
        require(!claimedTokens[_idToken], "Token already claimed");
        tokenData[_idToken].uri = _uri;
        tokenData[_idToken].locked = true;
        _safeMint(_to, _idToken);
        claimedTokens[_idToken] = true;
        
        emit TokenClaimed(_to, _idToken);
    }

    /// @notice Returns the locking status of an NFT.
    /// @dev NFTs assigned to the zero address are considered invalid, and queries
    /// about them do throw.
    /// @param _idToken The identifier for an NFT.
    function locked(uint256 _idToken) external view tokenIsExists(_idToken) returns (bool)  {
        return tokenData[_idToken].locked;
    }

    /// @notice Unlocks an NFT, allowing it to be transferred.
    /// @dev Only distributors can unlock tokens.
    /// @param _idToken The identifier for an NFT.
    function unlockToken(uint256 _idToken) external onlyOwner tokenIsExists(_idToken) {
        tokenData[_idToken].locked = false;
        emit Unlocked(_idToken);
    }

    /// @notice Reclaims an NFT from a specified address.
    /// @dev Only distributors can reclaim tokens.
    /// @param _from The address from which the NFT will be reclaimed.
    /// @param _idToken The identifier for an NFT.
    function reclaimToken(address _from, uint256 _idToken) external onlyOwner tokenIsExists(_idToken) {
        require(ownerOf(_idToken) == _from, "Token does not belong to the specified address");
        _transfer(_from, msg.sender, _idToken);
        tokenData[_idToken].locked = false;
    }

    /// @notice Transfers an NFT from one address to another.
    /// @dev Only distributors can transfer tokens.
    /// Mint tokens to the cagnotte at user from.
    /// @param _from The address from which the NFT will be transferred.
    /// @param _to The address to which the NFT will be transferred.
    /// @param _idToken The identifier for an NFT.
    function transferTokenNew(address _from, address _to, uint256 _idToken) external onlyOwner tokenIsExists(_idToken) {
        require(ownerOf(_idToken) == _from, "Token does not belong to the specified address");
        _transfer(_from, _to, _idToken);
    }

    /// @notice Generates a unique token ID based on the provided VIN.
    /// @dev The VIN (Vehicle Identification Number) is used to generate a unique ID.
    /// @param _vin The Vehicle Identification Number.
    function generateTokenId(string calldata _vin) external pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_vin)));
    }

    /// @notice Adds maintenance information to an NFT.
    /// @dev Only distributors can add maintenance information.
    /// Credits 100 tokens to the cagnotte for each maintenance added.
    /// @param _idToken The identifier for an NFT.
    /// @param _mileage identifier for mileage.
    /// @param _maintenance The details of the maintenance.
    /// @param _description The description of the maintenance.
    function addMaintenance(uint256 _idToken, uint256 _mileage, string calldata _maintenance, string calldata _description ) external onlyOwner tokenIsExists(_idToken) {
        Maintenances[_idToken].push(Maintenance(_maintenance, _description, _mileage, block.timestamp));
    }

    /// @notice Retrieves the maintenance history for an NFT.
    /// @dev Returns an array of Maintenance structures containing details of each maintenance event.
    /// @param _idToken The identifier for an NFT.
    function getMaintenanceHistory(uint256 _idToken) external view tokenIsExists(_idToken) returns (Maintenance[] memory) {
        return Maintenances[_idToken];
    }

    /// @notice Retrieves the number of maintenance events recorded for an NFT.
    /// @dev Returns the length of the maintenance history array for an NFT.
    /// @param _idToken The identifier for an NFT.
    function getLengthMaintenanceHistory(uint256 _idToken) external view tokenIsExists(_idToken) returns (uint) {
        return Maintenances[_idToken].length;
    }

    /// @notice Retrieves a specific maintenance event by its index in the maintenance history array.
    /// @dev Returns details of a maintenance event based on its index.
    /// @param _idToken The identifier for an NFT.
    /// @param _idMaintenance The index of the maintenance event.
    function gethMaintenanceHistoryById(uint256 _idToken, uint _idMaintenance) external view tokenIsExists(_idToken) returns (Maintenance memory) {
        return Maintenances[_idToken][_idMaintenance];
    }

    //Override function ERC721

    /// @notice Retrieves the URI associated with an NFT.
    /// @dev  Overrides the ERC721 tokenURI function.
    function tokenURI(uint _idToken) public view virtual override(ERC721) tokenIsExists(_idToken) returns(string memory) {
        return string(abi.encodePacked(tokenData[_idToken].uri));
    }

    /// @dev Overrides the ERC721 transferFrom function to include the IsTransferAllowed modifier.
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721) IsTransferAllowed(tokenId) {
        super.transferFrom(from, to, tokenId);
    }

    /// @dev Overrides the ERC721 safeTransferFrom function to include the IsTransferAllowed modifier.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override(ERC721) IsTransferAllowed(tokenId) {
        super.safeTransferFrom(from, to, tokenId, _data);
    }
}