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
        bool isDeleted;
    }

    struct Post { 
        uint ownerId;
        uint postId;
        string content;
        uint createdAt;
        bool isDeleted;
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

    event PostCreated( uint indexed postId, uint indexed ownerId, address indexed ownerAddress, string content, uint createdAt);
    event PostEdited( uint indexed postId, string newContent, uint editedAt);
    event PostDeleted( uint indexed postId, uint deletedAt);
    event PostLiked( uint indexed postId, uint indexed userId, address indexed userAddress, uint createdAt);
    event PostUnliked( uint indexed postId, uint indexed userId, address indexed userAddress, uint removedAt);
    event CommentCreated( uint indexed commentId, uint indexed postId, uint indexed authorId, address authorAddress, string content, uint createdAt);
    event CommentEdited( uint indexed commentId, string newContent, uint editedAt);
    event CommentDeleted( uint indexed commentId, uint deletedAt);



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

        emit PostCreated(newPostId, ownerId, msg.sender, _content,  newPost.createdAt);
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
        if(postIndex[postId].ownerId != 0 && !_isPostDeleted(postId)) return true;
        else return false;
    }

    function getTotalPostCount() external view returns (uint256) {
        return allPosts.length;
    }

    function deletePost(uint _postId) external {
        uint userId = profileManager.getProfileId(msg.sender);
        require(_postExists(_postId), "Post does not exist");

        PostLocation memory loc = postIndex[_postId];
        require(loc.ownerId == userId, "Not post owner");

        Post storage post = allPosts[loc.index];
        require(!post.isDeleted, "Already deleted");
        post.isDeleted = true;
        emit PostDeleted(_postId, block.timestamp);

    }

    function _isPostDeleted(uint256 _postId) internal view returns(bool){
        PostLocation memory loc = postIndex[_postId];
        return allPosts[loc.index].isDeleted;
    }

    function editPost(uint _postId, string calldata newContent) external {
        uint userId = profileManager.getProfileId(msg.sender);
        require(_postExists(_postId), "Post doesn't exist");
        PostLocation memory loc = postIndex[_postId];
        require(loc.ownerId == userId, "you don't have this post");
        require(bytes(newContent).length >  3, "content should be atleast letter 3");
        allPosts[loc.index].content = newContent;

        emit PostEdited(_postId, newContent, block.timestamp);
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
            createdAt: block.timestamp,
            isDeleted: false
        });

        postComments[_postId].push(newCommentId);
        emit CommentCreated(newCommentId, _postId, authorId, msg.sender, _content, comments[newCommentId].createdAt);
    }

    function editComment(uint256 _commentId, string calldata newContent) external {
        uint256 userId = profileManager.getProfileId(msg.sender);
        uint256 authorId = comments[_commentId].authorId;
        require(userId == authorId, "You don't own this comment");
        Comment storage comment =   comments[_commentId];
        require(!comment.isDeleted, "Comment does not exsist");

        comment.content = newContent;

        emit CommentEdited(_commentId, newContent, block.timestamp);
    }

    function deleteComment(uint256 _commentId) external {
        uint256 userId = profileManager.getProfileId(msg.sender);
        uint256 authorId = comments[_commentId].authorId;
        require(userId == authorId, "You don't own this comment");
        Comment storage comment =   comments[_commentId];
        require(!comment.isDeleted, "Comment does not exsist");

        comment.isDeleted = true;      
        emit CommentDeleted(_commentId, block.timestamp);   
    }

    function getCommentsByPost(uint256 _postId, uint256 _offset, uint256 _limit) external view returns (Comment[] memory) {
        require(_postExists(_postId), "Post does not exist");

        uint256 totalComments = postComments[_postId].length;

        if (_offset >= totalComments) {
            return new Comment[](0);
        }

        uint256 end = _offset + _limit;
        if (end > totalComments) {
            end = totalComments;
        }

        uint256 resultSize = end - _offset;
        Comment[] memory paginatedComments = new Comment[](resultSize);

        uint256 index = 0;
        for (uint256 i = _offset; i < end; i++) {
            uint256 commentId = postComments[_postId][i];
            paginatedComments[index] = comments[commentId];
            index++;
        }

        return paginatedComments;
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
            emit PostUnliked(_postId, userId, msg.sender , block.timestamp);
        } else {
            postLikes[_postId][userId] = true;
            postLikeCount[_postId]++;
             emit PostLiked(_postId, userId, msg.sender , block.timestamp);
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
