// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
 
import "forge-std/Test.sol";
import "../src/CarMaintenanceBook.sol";
 
contract CarMaintenanceBookTest is Test {
    string _name = "AutoChain Ledger";
    string _symbol = "ACL";
    address _owner = makeAddr("User0");
    address _user1 = makeAddr("User1");
    string _tokenId = "VIN124858TEST";
    
 
    CarMaintenanceBook _carMaintenanceBook;
 
    function setUp() public {
        vm.prank(_owner);
        _carMaintenanceBook = new CarMaintenanceBook();
    }
 
    function test_name() public view {
        string memory name = _carMaintenanceBook.name();
        assertEq(name, _name);
    }
 
    function test_symbol() public view {
        string memory symbol = _carMaintenanceBook.symbol();
        assertEq(symbol, _symbol);
    }

    function test_owner() public view {
        assertEq(_carMaintenanceBook.owner(), _owner);
    }

    event TokenClaimed(address indexed user, uint256 idToken);

    function test_safeMint() public {
        vm.startPrank(_owner);

        uint256 id = _carMaintenanceBook.generateTokenId(_tokenId);
        string memory stringId = vm.toString(id);
        string memory uri = string(abi.encodePacked("ipfs://QmHash123/", stringId, ".json"));

        vm.expectEmit(address(_carMaintenanceBook));
        
        emit CarMaintenanceBook.TokenClaimed(address(_user1), id);

        _carMaintenanceBook.safeMint(_user1, id, uri);

        vm.stopPrank();

        string memory tokenURI = _carMaintenanceBook.tokenURI(id);
        address tokenExists = _carMaintenanceBook.ownerOf(id);
        bool lockedStatus =_carMaintenanceBook.locked(id);
        assertEq(lockedStatus, true);
        assertEq(tokenExists, _user1);
        assertEq(tokenURI, uri);
    }
}