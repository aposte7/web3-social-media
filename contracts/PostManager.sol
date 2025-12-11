// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ProfileManager} from "./ProfileManager.sol";

contract PostManager {

    uint private postIdCount;

    ProfileManager profileManager;

    constructor(address _profileManagerAddress) {
        profileManager = ProfileManager(_profileManagerAddress);
    }

    struct Like {
        uint userId;
        uint createdAt;
    }

    struct Comment {
        uint commentId;
        uint postId;
        uint userId;
        string comment;
        uint createdAt;
    }

    struct Post { 
        uint ownerId;
        uint postId;
        string description;
        Like[] likes;
        Comment[] comments;
        uint createdAt;
    }

    mapping(uint => Post) public posts;

    event PostCreated(uint postId, uint ownerId, string description, uint createdAt);

    function createPost(string calldata _description) external {
        postIdCount++;
        uint newPostId = postIdCount;

        uint ownerId = profileManager.getProfileId(msg.sender);

        Post storage newPost = posts[newPostId];
        
        newPost.ownerId = ownerId;
        newPost.postId = newPostId;
        newPost.description = _description;
        newPost.createdAt = block.timestamp;

        emit PostCreated(newPostId, ownerId, _description, block.timestamp);
    }
}
