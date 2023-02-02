// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract nftContract is ERC721, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor(string memory _name,string memory _symbol) ERC721(_name, _symbol) {}

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
}
contract ShadowNetwork {

    // * Project Terminology

    // * Platform Name: Shadow Network 
    // * Sub-Platforms: Syndicates
    // * Members: Shadows (Users)

    // * Owner of Network: Shogun
    address public owner;

    // ? ------User : Shadow
    // User Mapping
    mapping(address => User) public users;

    // User curated spaces (join syndicates)
    // Syndicate Ids user have joined
    mapping(address => uint256[]) public userSyndicates;

    // Unique wallets / users
    uint256 public userCount = 0;

    // ? ------Syndicate
    // Syndicate name Index
    uint256 public syndicateCount = 0;

    // Id to Syndicate
    mapping(uint256 => Syndicate) public syndicates;

    // ? -------Image (Posts)
    // Image index
    uint256 public imageCount = 0;

    // Id to Image
    mapping(uint256 => Image) public images;

    //* Get all Post Ids for a User
    // * userAddress => [imageIds Array]
    mapping(address => uint256[]) posts;
    // ? --------------/

    // ? ------Comments
    // create comments mapping (imageId -> comment)
    // Array of Comment(Struct) for a Post
    mapping(uint256 => Comment[]) public comments;

    // create mapping to keep inventory on number of comments per image
    // postId => No of Comments
    mapping(uint256 => uint256) public commentOnPosts;
    // ? --------------/

    // ? ------STRUCTURES
    // Syndicate Structure
    struct Syndicate {
        uint256 syndicateCount;
        address syndicateCreator;
        uint256 dateCreated;
        string syndicateName;
        string syndicateDescription;
        string _nftName;
        string _nftSymbol;
        address NftContract;
    }

    // Profile of User
    struct User {
        address addr;
        uint256 upvotesTotal;
        uint256 downvotesTotal;
        uint256 postTotal;
        // * Is User Registered on Platform
        bool isVerified;
    }

    // Image Proprerty Struct
    struct Image {
        uint256 id;
        string hash;
        string memeTitle;
        address author;
        uint256 datePosted;
        uint256 upvotes;
        uint256 downvotes;
        //convert to bool
        bool isSpoiler;
        bool isOC;
        uint256 syndicateId;
    }

    // Comment structure assoicated with image
    struct Comment {
        address addr;
        uint256 datePosted;
        uint256 imageId;
        string commentMessage;
    }

    // ? EVENTS
    event EventCreateSyndicate (
        uint256 syndicateCount,
        address syndicateCreator,
        uint256 dateCreated,
        string syndicateName,
        string syndicateDescription,
        string _nftName,
        string _nftSymbol,
        address NftContract
    );

    event EventJoinSyndicate(uint256 id, address _member);

    event ImageCreated(
        uint256 id,
        string hash,
        string memeTitle,
        address author,
        uint256 datePosted,
        uint256 upvotes,
        uint256 downvotes,
        bool isSpoiler,
        bool isOC,
        uint256 syndicateId
    );

    event ImageUpvotes(
        uint256 id,
        string hash,
        string memeTitle,
        address author,
        uint256 upvotes,
        uint256 downvotes,
        uint256 syndicateId
    );

    event ImageDownvotes(
        uint256 id,
        string hash,
        string memeTitle,
        address author,
        uint256 upvotes,
        uint256 downvotes,
        uint256 syndicateId
    );

    event CommentAdded(
        address addr,
        uint256 datePosted,
        uint256 imageId,
        string commentMessage
    );

    constructor() {
        owner = msg.sender;
    }

    // * Contract Owner Only
    modifier onlyOwner() {
        require(owner == msg.sender, "Not the Owner");
        _;
    }

    // * Check Member Function
    function checkOwnership(address _user, uint256 _syndicateId) public view returns (bool) {
        // Get the address of the NFT contract for the specified space
        address nftContractAddress = syndicates[_syndicateId].NftContract;

        // Call the balanceOf function on the NFT contract to get the number of NFTs owned by the user
        uint256 balance = nftContract(nftContractAddress).balanceOf(_user);

        // Return true if the user has at least one NFT in the NFT contract, otherwise return false
        return balance > 0;
    }

    //* Create a Syndicate in Shadow Network
    function createSyndicate(
        string memory _syndicateName,
        string memory _syndicateDescription,
        string memory _nftName,
        string memory _nftSymbol
    ) public payable {
        // Requires space name to be less than 21 words
        require(bytes(_syndicateName).length > 0 && bytes(_syndicateName).length <= 21);
        require(
            bytes(_syndicateDescription).length > 0 &&
                bytes(_syndicateDescription).length <= 100
        );

        // Add to index
        syndicateCount++;

        // Create an instance of the ERC721 contract
        nftContract _nftContract = new nftContract(_nftName, _nftSymbol);

        // Set the owner of the ERC721 contract to the function caller
        _nftContract.transferOwnership(msg.sender);

        // Add to spaces mapping
        syndicates[syndicateCount] = Syndicate(
            syndicateCount,
            msg.sender,
            block.timestamp,
            _syndicateName,
            _syndicateDescription,
            _nftName,
            _nftSymbol,
            address(_nftContract)
        );

        emit EventCreateSyndicate(
             syndicateCount,
            msg.sender,
            block.timestamp,
            _syndicateName,
            _syndicateDescription,
            _nftName,
            _nftSymbol,
            address(_nftContract)
        );
    }

    //* Join a Syndicate based on the syndicateId
    // ? You must have an NFT sent by the Founder of the Syndicate
    function joinSyndicate(uint256 _syndicateId) public {

        // Require NFT of the Syndicate
        require(checkOwnership(msg.sender, _syndicateId), "Not a Syndicate Member");

        userSyndicates[msg.sender].push(_syndicateId);
        emit EventJoinSyndicate(_syndicateId, msg.sender);
    }

    //* Get all the syndicates associated with the user
    function getJoinSyndicates(
        address _userAddress
    ) public view returns (uint256[] memory) {
        return userSyndicates[_userAddress];
    }

    //* Get the Syndicate's name by search
    function getSyndicateName(uint256 _id) public view returns (string memory) {
        return syndicates[_id].syndicateName;
    }

    //* Upload Text Content
    function uploadTextContent(
        string memory _textContent,
        string memory _memeTitle,
        bool _isSpoiler,
        bool _isOC,
        uint _syndicateId
    ) public payable {
        // Enure the text content exists
        require(
            bytes(_textContent).length > 0 && bytes(_textContent).length <= 500
        );
        // Ensure title length
        require(
            bytes(_memeTitle).length > 0 && bytes(_memeTitle).length <= 100
        );

        // Enure uploader address exists
        require(msg.sender != address(0));

        // * Check if Member of the Syndicate in which the Image is Posted
        require(checkOwnership(msg.sender, _syndicateId), "Not a Syndicate Member");


        // Increment image id
        imageCount++;

        uint256 upvoteScore = 1;
        uint256 postTotal = 1;

        // Add Image to the contract
        images[imageCount] = Image(
            imageCount,
            _textContent,
            _memeTitle,
            msg.sender,
            block.timestamp,
            upvoteScore,
            0,
            _isSpoiler,
            _isOC,
            _syndicateId
        );

        // check if user exist add to mapping if not create new from varibale
        User memory _user = users[msg.sender];

        // get variable for address if already created and update mapping record
        if (msg.sender == _user.addr) {
            // * User Already Exist
            posts[msg.sender].push(imageCount); // Update Post array (address => Image.id)
            users[msg.sender].upvotesTotal = _user.upvotesTotal + 1;
            users[msg.sender].postTotal = _user.postTotal + 1;
        } else {
            // * Create New User
            posts[msg.sender].push(imageCount); // Update Post array (address => Image.id)
            users[msg.sender] = User(msg.sender, 1, 0, postTotal, true);
            userCount++;
        }

        // Trigger an event
        emit ImageCreated(
            imageCount,
            _textContent,
            _memeTitle,
            msg.sender,
            block.timestamp,
            upvoteScore,
            0,
            _isSpoiler,
            _isOC,
            _syndicateId
        );
    }

    //* Upload image
    function uploadImage(
        string memory _imgHash,
        string memory _memeTitle,
        bool _isSpoiler,
        bool _isOC,
        uint _syndicateId
    ) public payable {
        // Enure the image title hash exists
        require(bytes(_imgHash).length > 0 && bytes(_imgHash).length <= 100);
        // Ensure image description
        require(
            bytes(_memeTitle).length > 0 && bytes(_memeTitle).length <= 100
        );

        // Enure uploader address exists
        require(msg.sender != address(0));

        // * Check if Member of the Syndicate in which the Image is Posted
        require(checkOwnership(msg.sender, _syndicateId), "Not a Syndicate Member");


        // Increment image id
        imageCount++;

        uint256 upvoteScore = 1;
        uint256 postTotal = 1;

        // Add Image to the contract
        images[imageCount] = Image(
            imageCount,
            _imgHash,
            _memeTitle,
            msg.sender,
            block.timestamp,
            upvoteScore,
            0,
            _isSpoiler,
            _isOC,
            _syndicateId
        );

        // check if user exist add to mapping if not create new from varibale
        User memory _user = users[msg.sender];

        // get variable for address if already created and update mapping record
        if (msg.sender == _user.addr) {
            posts[msg.sender].push(imageCount); // Update Post array (address => Image.id)
            users[msg.sender].upvotesTotal = _user.upvotesTotal + 1;
            users[msg.sender].postTotal = _user.postTotal + 1;
        } else {
            posts[msg.sender].push(imageCount); // Update Post array (address => Image.id)
            users[msg.sender] = User(msg.sender, 1, 0, postTotal, false);
            userCount++;
        }

        // Trigger an event
        emit ImageCreated(
            imageCount,
            _imgHash,
            _memeTitle,
            msg.sender,
            block.timestamp,
            upvoteScore,
            0,
            _isSpoiler,
            _isOC,
            _syndicateId
        );
    }

    //* Add Comment to an Image(Post) in your Syndicate
    function addComment(
        uint256 _imageId,
        string memory _commentMessage
    ) public {
        require(
            bytes(_commentMessage).length > 0 &&
                bytes(_commentMessage).length <= 280
        );

        // * Get Image Detail
        Image memory image = images[_imageId];

        // * Check if Member of the Syndicate in which the Image is Posted
        require(checkOwnership(msg.sender, image.syndicateId), "Not a Syndicate Member");

        comments[_imageId].push(
            Comment(msg.sender, block.timestamp, _imageId, _commentMessage)
        );
        // increments to reflect number of comments associted with post
        commentOnPosts[_imageId] = commentOnPosts[_imageId] + 1;

        emit CommentAdded(
            msg.sender,
            block.timestamp,
            _imageId,
            _commentMessage
        );
    }

    //* Get All Comments for an Image(Post)
    function getComments(
        uint256 imageId
    ) public view returns (Comment[] memory) {
        return comments[imageId];
    }

    //* Get Total number of upvotes of a User
    function getUserUpvotesTotal(
        address _userAddr
    ) public view returns (uint256) {
        User memory _user = users[_userAddr];
        return _user.upvotesTotal;
    }

    //* Get Total Number of downvotes of a User
    function getUserDownvotesTotal(
        address _userAddr
    ) public view returns (uint256) {
        User memory _user = users[_userAddr];
        return _user.downvotesTotal;
    }

    //* Get Total number of posts by user
    function getUserpostTotal(address _userAddr) public view returns (uint256) {
        User memory _user = users[_userAddr];
        return _user.postTotal;
    }

    //* Upvote a Post in your Syndicate
    function upvoteMeme(uint256 _id) public payable {
        // Make sure the id is valid
        require(_id > 0 && _id <= imageCount);

        // Fetch the image
        Image memory _image = images[_id];

        // * Check if Member of the Syndicate in which the Image is Posted
        require(checkOwnership(msg.sender, _image.syndicateId), "Not a Syndicate Member");

        // Fetch the author
        address _author = _image.author;

        //Increment Upvote Counter
        _image.upvotes = _image.upvotes + 1;

        // user mapping
        User memory _user = users[_author];

        // update userTotalVotes
        users[_image.author].upvotesTotal = _user.upvotesTotal + 1;

        // Update the image
        images[_id] = _image;

        // requires the upvoter not be the poster
        require(
            msg.sender != _author,
            "poster's can not upvote their own content"
        );

        // Trigger an event
        emit ImageUpvotes(
            _id,
            _image.hash,
            _image.memeTitle,
            _author,
            _image.upvotes,
            _image.downvotes,
            _image.syndicateId
        );
    }

    //* Downvote a Post in your Syndicate
    function downvoteMeme(uint256 _id) public payable {
        // Make sure the id is valid
        require(_id > 0 && _id <= imageCount);

        // Fetch the image
        Image memory _image = images[_id];

        // * Check if Member of the Syndicate in which the Image is Posted
        require(checkOwnership(msg.sender, _image.syndicateId), "Not a Syndicate Member");

        // Fetch the author
        address _author = _image.author;

        //Increment Upvote Counter
        _image.downvotes = _image.downvotes + 1;

        // user mapping
        User memory _user = users[_author];

        // update userTotalVotes
        users[_image.author].downvotesTotal = _user.downvotesTotal + 1;

        // Update the image
        images[_id] = _image;

        // Trigger an event
        emit ImageDownvotes(
            _id,
            _image.hash,
            _image.memeTitle,
            _author,
            _image.upvotes,
            _image.downvotes,
            _image.syndicateId
        );
    }

    //* Get Image upvotes
    function getUpvotes(uint256 _id) public view returns (uint256) {
        // Fetch the image
        Image memory _image = images[_id];
        return _image.upvotes;
    }

    //* Get Image upvotes
    function getDownvotes(uint256 _id) public view returns (uint256) {
        // Fetch the image
        Image memory _image = images[_id];
        return _image.downvotes;
    }


    //* View if Spoiler
    function getIsSpoiler(uint256 _id) public view returns (bool) {
        Image memory _image = images[_id];
        return _image.isSpoiler;
    }

    //* View Platform User Count
    function getUserCount() public view returns (uint256) {
        return userCount;
    }

    // Get All Posts by User
    function getUserPosts(
        address _author
    ) public view returns (uint256[] memory) {
        return posts[_author];
    }
}
