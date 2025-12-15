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
    }

    mapping(address userAddress => uint userIndex) private profileIndexPlusOne;
    mapping(string => bool) private usernameTaken;

    Profile[] private profileList;


    event ProfileCreated( uint256 indexed profileId, address indexed owner, string username,  string bio, string avatarURI, uint256 createdAt);
    event ProfileUpdated( uint256 indexed profileId, uint256 updatedAt);



    modifier onlyProfileOwner() {
        require(profileList[profileIndexPlusOne[msg.sender]].id != 0, "Profile does not exist");
        _;
    }
   

  
    function createProfile(string calldata username,string calldata bio,string calldata avatarURI) external returns (Profile memory) {
        require(profileList[profileIndexPlusOne[msg.sender]].id == 0, "Profile already exists");
        require(bytes(username).length >= 3, "Username too short");
        require(usernameTaken[username] == false, "Username already taken");

        _profileCounter++;


        Profile memory newProfile = Profile({
            id: _profileCounter,
            username: username,
            bio: bio,
            avatarURI: avatarURI,
            owner: msg.sender,
            createdAt: block.timestamp
        });


        profileList.push(newProfile);
        profileIndexPlusOne[msg.sender] = profileList.length;
        usernameTaken[username] = true;

        emit ProfileCreated(_profileCounter, msg.sender, username, bio, avatarURI, block.timestamp);

        return newProfile;
    }


    function updateProfile(string calldata newUsername,string calldata newBio,string calldata newAvatarURI) external onlyProfileOwner returns (Profile memory) {

        Profile storage user = profileList[profileIndexPlusOne[msg.sender] - 1];

        if (keccak256(bytes(newUsername)) != keccak256(bytes(user.username))) {
            require(bytes(newUsername).length >= 3, "Username too short");
            require(usernameTaken[newUsername] == false, "Username already taken");

            usernameTaken[user.username] = false;
            usernameTaken[newUsername] = true;
            user.username = newUsername;
        }

        user.bio = newBio;
        user.avatarURI = newAvatarURI;

        emit ProfileUpdated(user.id, block.timestamp);

        return user;
    }


    function getProfileId(address _address) public view returns(uint){
        require(profileList[profileIndexPlusOne[_address]].id !=0, "Profile not found" );

        return profileList[profileIndexPlusOne[_address] - 1].id;
    }


    function getProfile(address userAddress) external view returns (Profile memory) {
        require(profileList[profileIndexPlusOne[userAddress]].id != 0, "Profile not found");
        
        return profileList[profileIndexPlusOne[userAddress]];
    }

    function getMyProfile() external view returns (Profile memory) {
        require(profileList[profileIndexPlusOne[msg.sender]].id != 0, "Profile not found");
        return profileList[profileIndexPlusOne[msg.sender]];
    }

    function getAllProfiles() external view returns (Profile[] memory) {
        return profileList;
    }

    function totalProfiles() external view returns (uint256) {
        return _profileCounter;
    }
}
