// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ProfileManager {

    uint256 private _profileCounter;

    struct Profile {
        uint256 id;
        string username;
        string bio;
        string avatarURI;      
        address owner;
        uint256 createdAt;
        uint256 updatedAt;
    }

    mapping(address => Profile) private profiles;

    mapping(string => bool) private usernameTaken;

    Profile[] private profileList;



    event ProfileCreated(
        uint256 indexed id,
        address indexed owner,
        string username,
        uint256 timestamp
    );

    event ProfileUpdated(
        uint256 indexed id,
        address indexed owner,
        uint256 timestamp
    );



    modifier onlyProfileOwner() {
        require(profiles[msg.sender].id != 0, "Profile does not exist");
        _;
    }


}
