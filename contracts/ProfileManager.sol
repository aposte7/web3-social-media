// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ProfileManager {
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
    mapping(address => bool) private hasProfile;
    mapping(string => bool) private usernameTaken;
    address[] private profileOwners;
    uint256 private profileCounter;


    event ProfileCreated(uint256 indexed profileId,address indexed owner,string username,uint256 createdAt
    );

    event ProfileUpdated(uint256 indexed profileId,uint256 updatedAt
    );


    modifier onlyProfileOwner() {
        require(hasProfile[msg.sender], "Profile does not exist");
        _;
    }


    function createProfile(string calldata username,string calldata bio,string calldata avatarURI) external returns (Profile memory) {
        require(!hasProfile[msg.sender], "Profile already exists");
        require(bytes(username).length >= 3, "Username too short");
        require(!usernameTaken[username], "Username already taken");

        profileCounter++;

        Profile memory newProfile = Profile({
            id: profileCounter,
            username: username,
            bio: bio,
            avatarURI: avatarURI,
            owner: msg.sender,
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });

        profiles[msg.sender] = newProfile;
        hasProfile[msg.sender] = true;
        usernameTaken[username] = true;
        profileOwners.push(msg.sender);

        emit ProfileCreated(newProfile.id,msg.sender,username,block.timestamp
        );

        return newProfile;
    }


    function updateProfile(string calldata newUsername,string calldata newBio,string calldata newAvatarURI) external onlyProfileOwner returns (Profile memory) {

        Profile storage user = profiles[msg.sender];

        if (keccak256(bytes(newUsername)) != keccak256(bytes(user.username))) {
            require(bytes(newUsername).length >= 3, "Username too short");
            require(!usernameTaken[newUsername], "Username already taken");

            usernameTaken[user.username] = false;
            usernameTaken[newUsername] = true;
            user.username = newUsername;
        }

        user.bio = newBio;
        user.avatarURI = newAvatarURI;
        user.updatedAt = block.timestamp;

        emit ProfileUpdated(user.id, block.timestamp);

        return user;
    }


    function getProfile(address user) external view returns (Profile memory) {
        require(hasProfile[user], "Profile not found");
        return profiles[user];
    }

    function getMyProfile() external view returns (Profile memory) {
        require(hasProfile[msg.sender], "Profile not found");
        return profiles[msg.sender];
    }

    function getProfileId(address user) external view returns (uint256) {
        require(hasProfile[user], "Profile not found");
        return profiles[user].id;
    }

    function totalProfiles() external view returns (uint256) {
        return profileOwners.length;
    }

    function getAllProfiles() external view returns (Profile[] memory) {
        uint256 count = profileOwners.length;
        Profile[] memory list = new Profile[](count);

        for (uint256 i = 0; i < count; i++) {
            list[i] = profiles[profileOwners[i]];
        }

        return list;
    }

    function profileExists(address user) external view returns (bool) {
        return hasProfile[user];
    }
}
