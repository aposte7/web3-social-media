// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ProfileManager} from "./ProfileManager.sol";

contract PostManager {

    uint private postIdCount;
    uint private commentIdCounter;

    ProfileManager profileManager;

    constructor(address _profileManagerAddress) {
        profileManager = ProfileManager(_profileManagerAddress);
    }


    struct Comment {
        uint commentId;
        uint postId;
        uint authorId;
        string content;
        uint createdAt;
    }

    struct Post { 
        uint ownerId;
        uint postId;
        string content;
        uint createdAt;
    }

    struct PostLocation {
        uint ownerId;     
        uint index;        
    }


    mapping(uint256 userId => uint256[] userPostsIndex) private userPosts; 
    mapping(uint256 postId => PostLocation PostLocationStruct) private postIndex;
    mapping(uint256 postId => mapping(uint256 userId => bool)) private postLikes;
    mapping(uint256 postId => uint) private postLikeCount;
    mapping(uint256 commentId => Comment) private comments; 
    mapping(uint256 postId => uint256[] commentId) private postComments; 

    Post[] private allPosts;
    event PostCreated(uint postId, uint ownerId, string content, uint createdAt);

    function createPost(string calldata _content) external {

        require(bytes(_content).length >  3, "content should be atleast letter 3");

        uint ownerId = profileManager.getProfileId(msg.sender);

        postIdCount++;
        uint newPostId = postIdCount;

        allPosts.push();
        uint index = allPosts.length - 1;
        Post storage newPost = allPosts[index];

        newPost.ownerId = ownerId;
        newPost.postId = newPostId;
        newPost.content = _content;
        newPost.createdAt = block.timestamp;

        userPosts[ownerId].push(index);

        postIndex[newPostId] = PostLocation(ownerId, index);

        emit PostCreated(newPostId, ownerId, _content, block.timestamp);
    }


    // Reminder forself the should impelment pagination and be external function
    function getAllPosts() internal view returns (Post[] memory) {
        return allPosts;
    }

    function getPostById(uint _postId) external view returns(Post memory){
        require(_postExists(_postId), "Post doesn't exist");
        PostLocation memory loc = postIndex[_postId];
        return allPosts[loc.index];
    }

    function getPostsByUser(uint userId) external view returns (Post[] memory) {

        uint[] memory userPostIndices = userPosts[userId];
        Post[] memory tempUserPosts = new Post[](userPostIndices.length);

        for (uint i = 0; i < userPostIndices.length; i++) {
            tempUserPosts[i] = allPosts[userPostIndices[i]];
        }

        return tempUserPosts;
    }

    function _postExists(uint postId) internal view returns (bool){
        if(postIndex[postId].ownerId != 0 ) return true;
        else return false;
    }

    function deletePost(uint _postId) external {
        uint userId = profileManager.getProfileId(msg.sender);

        require(_postExists(_postId), "Post does not exist");

        PostLocation memory loc = postIndex[_postId];
        require(loc.ownerId == userId, "You do not own this post");

        uint postArrayIndex = loc.index;
        uint lastPostIndex = allPosts.length - 1;

        if (postArrayIndex != lastPostIndex) {
            Post storage lastPost = allPosts[lastPostIndex];

            allPosts[postArrayIndex] = lastPost;

            postIndex[lastPost.postId].index = postArrayIndex;

            uint[] storage ownerPosts = userPosts[lastPost.ownerId];
            for (uint i = 0; i < ownerPosts.length; i++) {
                if (ownerPosts[i] == lastPostIndex) {
                    ownerPosts[i] = postArrayIndex;
                    break;
                }
            }
        }

        allPosts.pop();

        uint[] storage postsOfUser = userPosts[userId];
        for (uint i = 0; i < postsOfUser.length; i++) {
            if (postsOfUser[i] == postArrayIndex) {
                postsOfUser[i] = postsOfUser[postsOfUser.length - 1];
                postsOfUser.pop();
                break;
            }
        }

        delete postIndex[_postId];
    }


    function editPost(uint _postId, string calldata _content) external {
        uint userId = profileManager.getProfileId(msg.sender);
        require(_postExists(_postId), "Post doesn't exist");
        PostLocation memory loc = postIndex[_postId];
        require(loc.ownerId == userId, "you don't have this post");
        require(bytes(_content).length >  3, "content should be atleast letter 3");


        allPosts[loc.index].content = _content;
    }
    

    // -- COMMENT Functionalites //
    function commentOnPost(uint256 _postId, string calldata _content) external {
        uint256 authorId = profileManager.getProfileId(msg.sender);
        require(_postExists(_postId), "Post does not exist");
        require(bytes(_content).length > 0, "Empty comment");

        commentIdCounter++;
        uint256 newCommentId = commentIdCounter;

        comments[newCommentId] = Comment({
            commentId: newCommentId,
            postId: _postId,
            authorId: authorId,
            content: _content,
            createdAt: block.timestamp
        });

        postComments[_postId].push(newCommentId);
    }

    function getPostCommentCount(uint256 _postId) external view returns (uint256) {
        require(_postExists(_postId), "Post does not exist");
        return postComments[_postId].length;
    }

    //--  LIKE Functionalities --//

    function togglePostLike(uint _postId) external {
        uint userId = profileManager.getProfileId(msg.sender);
        require(_postExists(_postId), "Post doesn't exist");

        if (postLikes[_postId][userId]) {
            postLikes[_postId][userId] = false;
            postLikeCount[_postId]--;
        } else {
            postLikes[_postId][userId] = true;
            postLikeCount[_postId]++;
        }
    }


    function getPostLikeCount(uint _postId) external view returns (uint) {
        require(_postExists(_postId), "Post doesn't exist");
        return postLikeCount[_postId];
    }

    function hasUserLikedPost(uint _postId, uint _userId) external view returns (bool) {
        require(_postExists(_postId), "Post doesn't exist");
        return postLikes[_postId][_userId];
    }


}
