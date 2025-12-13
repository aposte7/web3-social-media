// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ProfileManager} from "./ProfileManager.sol";

contract PostManager {

    uint private postIdCount;
    uint private commentIdIdCount;

    ProfileManager profileManager;

    constructor(address _profileManagerAddress) {
        profileManager = ProfileManager(_profileManagerAddress);
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
        uint like;
        string description;
        Comment[] comments;
        uint createdAt;
    }

    struct PostLocation {
        uint ownerId;     
        uint index;        
    }

    mapping(uint userId => uint postId ) likes;

    mapping(uint userId => uint[] userPostsIndex) public userPosts; 
   
    Post[] public allPosts;

    mapping(uint postId => PostLocation PostLocationStruct) public postIndex;

    event PostCreated(uint postId, uint ownerId, string description, uint createdAt);


    function createPost(string calldata _description) external {
        uint ownerId = profileManager.getProfileId(msg.sender);

        postIdCount++;
        uint newPostId = postIdCount;

        allPosts.push();
        uint index = allPosts.length - 1;
        Post storage newPost = allPosts[index];

        newPost.ownerId = ownerId;
        newPost.postId = newPostId;
        newPost.description = _description;
        newPost.createdAt = block.timestamp;

        userPosts[ownerId].push(index);

        postIndex[newPostId] = PostLocation(ownerId, index);

        emit PostCreated(newPostId, ownerId, _description, block.timestamp);
    }


    function getAllPosts() external view returns (Post[] memory) {
        return allPosts;
    }

    function getPostById(uint _postId) external view returns(Post memory){
        require(_postExists(_postId), "Post doesn't exist");
        PostLocation memory loc = postIndex[_postId];
        return allPosts[loc.index];
    }

    function getPostsByUser(uint userId) external view returns (Post[] memory){
        require(userPosts[userId][0]!= 0, "user doesn't own any post");
        Post[] memory tempUserPosts;

        for(uint index; index < userPosts[userId].length; index++){
                    tempUserPosts[index] = allPosts[userPosts[userId][index]];
        }

        return tempUserPosts;
    }

    function _postExists(uint postId) internal view returns (bool){
        if(postIndex[postId].ownerId != 0 ) return true;
        else return false;
    }

    function deletePost(uint _postId) external{
        // check if the post exist and the user ownes it.
        uint userId = profileManager.getProfileId(msg.sender);

        PostLocation memory loc = postIndex[_postId];

        require(loc.ownerId == userId, "you don't have this post");
        require(_postExists(_postId), "Post doesn't exist");

        delete allPosts[loc.index];
        delete postIndex[_postId];

        userPosts[loc.ownerId][_postId] = userPosts[loc.ownerId][userPosts[loc.ownerId].length - 1];
        userPosts[loc.ownerId].pop();
    }

    function editPost(uint _postId, string calldata _description) external {
        uint userId = profileManager.getProfileId(msg.sender);

        PostLocation memory loc = postIndex[_postId];

        require(loc.ownerId == userId, "you don't have this post");
        require(_postExists(_postId), "Post doesn't exist");

        allPosts[loc.index].description = _description;
    }

    // -- COMMENT Functionalites //

    function commentOnPost(string calldata _comment, uint _postId) external {
        uint commenterId = profileManager.getProfileId(msg.sender);

        require(_postExists(_postId), "Post does not exist");

        PostLocation memory loc = postIndex[_postId];

        uint index = loc.index;

        Comment memory newComment = Comment({
            commentId: ++commentIdIdCount,
            postId: _postId,
            userId: commenterId,
            comment: _comment,
            createdAt: block.timestamp
        });

        allPosts[index].comments.push(newComment);
    }


    //--  LIKE Functionalities --//

    function togglePostLike(uint _postId) external {
        uint userId = profileManager.getProfileId(msg.sender);

        require(_postExists(_postId), "Post doesn't exist");
        PostLocation memory loc = postIndex[_postId];

        if(likes[userId] == 1){
            likes[userId] = 0;
            --allPosts[loc.index].like;
        }

        else {
            likes[userId] = 1;
            ++allPosts[loc.index].like;
        }

    }

    function getPostLikeCount(uint _postId) external view returns (uint){
        require(_postExists(_postId), "Post doesn't exist");  
        PostLocation memory loc = postIndex[_postId];
        
       return allPosts[loc.index].like;
    }
}
