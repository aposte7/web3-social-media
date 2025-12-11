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

  
    function createProfile(
        string calldata username,
        string calldata bio,
        string calldata avatarURI
    ) external returns (Profile memory) {

        require(profiles[msg.sender].id == 0, "Profile already exists");
        require(bytes(username).length >= 3, "Username too short");
        require(usernameTaken[username] == false, "Username already taken");

        _profileCounter++;


        Profile memory newProfile = Profile({
            id: _profileCounter,
            username: username,
            bio: bio,
            avatarURI: avatarURI,
            owner: msg.sender,
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });

        profiles[msg.sender] = newProfile;

        profileList.push(newProfile);
        
        usernameTaken[username] = true;

        emit ProfileCreated(_profileCounter, msg.sender, username, block.timestamp);

        return newProfile;
    }


    function updateProfile(
        string calldata newUsername,
        string calldata newBio,
        string calldata newAvatarURI
    ) external onlyProfileOwner returns (Profile memory) {

        Profile storage user = profiles[msg.sender];

        if (keccak256(bytes(newUsername)) != keccak256(bytes(user.username))) {
            require(bytes(newUsername).length >= 3, "Username too short");
            require(usernameTaken[newUsername] == false, "Username already taken");

            usernameTaken[user.username] = false;
            usernameTaken[newUsername] = true;

            user.username = newUsername;
        }

        user.bio = newBio;
        user.avatarURI = newAvatarURI;
        user.updatedAt = block.timestamp;

        emit ProfileUpdated(user.id, msg.sender, block.timestamp);

        return user;
    }


    function getProfileId(address _address) public view returns(uint){
        require(profiles[_address].id !=0, "Profile not found" );

        return profiles[_address].id;
    }


    function getProfile(address userAddress) external view returns (Profile memory) {
        require(profiles[userAddress].id != 0, "Profile not found");
        return profiles[userAddress];
    }

    function getMyProfile() external view returns (Profile memory) {
        require(profiles[msg.sender].id != 0, "Profile not found");
        return profiles[msg.sender];
    }

    function getAllProfiles() external view returns (Profile[] memory) {
        return profileList;
    }

    function totalProfiles() external view returns (uint256) {
        return _profileCounter;
    }
}
