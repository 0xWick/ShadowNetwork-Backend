// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.12;


import "@openzeppelin/contracts@4.6.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.6.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.6.0/utils/Counters.sol";


// * Push Interface
// PUSH Comm Contract Interface
interface IPUSHCommInterface {
    function sendNotification(address _channel, address _recipient, bytes calldata _identity) external;
}


contract nftContract is ERC721, Ownable {
    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenIdCounter;
    
    constructor(string memory _name,string memory _symbol) ERC721(_name, _symbol) {}

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721) {
        // * Allow only Mint transfers
        require(from == address(0), "Err: token is SOUL BOUND");
        super._beforeTokenTransfer(from, to, tokenId);
    }
}


contract ShadowNetwork {


    // * Push Configuration
    //address public EPNS_COMM_ADDRESS = 0x2b9bE9259a4F5Ba6344c1b1c07911539642a2D33; // eth goerli
    address public EPNS_COMM_ADDRESS = 0xb3971BCef2D791bc4027BbfedFb47319A4AAaaAa; // mumbai polygon


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

    // ? -------Posts
    // Post index
    uint256 public postCount = 0;

    // postId to Post
    mapping(uint256 => Post) public posts;

    //* Get all Post Ids for a User
    // * userAddress => [postIds Array]
    mapping(address => uint256[]) addressToPosts;
    // ? --------------/

    // ? ------Comments
    // create comments mapping (postId -> comment)
    // Array of Comment(Struct) for a Post
    mapping(uint256 => Comment[]) public comments;

    // create mapping to keep inventory on number of comments per Post
    // postId => No of Comments
    mapping(uint256 => uint256) public commentOnPosts;
    // ? --------------/

    // ? ------STRUCTURES
    // Syndicate Structure
    struct Syndicate {
        uint256 syndicateCount;
        // * Add Image to syndicate
        string syndicateImageHash;
        address syndicateCreator;
        uint256 dateCreated;
        string syndicateName;
        string syndicateDescription;
        string _nftName;
        string _nftSymbol;
        address NftContract;
        address channelAddress;
    }

    // Profile of User
    struct User {
        address addr;
        uint256 upvotesTotal;
        uint256 downvotesTotal;
        uint256 postTotal;
    }

    // Post Struct
    struct Post {
        uint256 id;
        string imageHash;
        bool hasImage;
        string description;
        string memeTitle;
        address author;
        uint256 datePosted;
        uint256 upvotes;
        uint256 downvotes;
        //convert to bool
        bool isSpoiler;
        uint256 syndicateId;
    }

    // Comment structure assoicated with Post
    struct Comment {
        address addr;
        uint256 datePosted;
        uint256 postId;
        string commentMessage;
    }
    // ? EVENTS
    event EventCreateSyndicate (
        uint256 indexed syndicateCount,
        string syndicateImageHash,
        address indexed syndicateCreator,
        uint256 dateCreated,
        string syndicateName,
        string syndicateDescription,
        string _nftName,
        string _nftSymbol,
        address indexed NftContract,
        address channelAddress
    );

    event EventJoinSyndicate(uint256 indexed id, address indexed _member);

    event PostCreated(
        uint256 indexed id,
        string imageHash,
        bool hasImage,
        string description,
        string memeTitle,
        address indexed author,
        uint256 datePosted,
        uint256 upvotes,
        uint256 downvotes,
        bool isSpoiler,
        uint256 indexed syndicateId
    );

    event PostUpvotes(
        uint256 indexed id,
        string memeTitle,
        address indexed author,
        uint256 upvotes,
        uint256 downvotes,
        uint256 indexed syndicateId
    );

    event PostDownvotes(
        uint256 indexed id,
        string memeTitle,
        address indexed author,
        uint256 upvotes,
        uint256 downvotes,
        uint256 indexed syndicateId
    );

    event CommentAdded(
        address indexed addr,
        uint256 datePosted,
        uint256 indexed postId,
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
        string memory _nftSymbol,
        string memory _syndicateImageHash,
        address _channelAddress
    ) public {
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

        // * Mint nft to the Owner
        _nftContract.safeMint(msg.sender);

        // Set the owner of the ERC721 contract to the function caller
        _nftContract.transferOwnership(msg.sender);

        // * Add the Creator to the Syndicate
        userSyndicates[msg.sender].push(syndicateCount);

        emit EventJoinSyndicate(syndicateCount, msg.sender);

        // * Create the syndicate
        // Add to spaces mapping
        syndicates[syndicateCount] = Syndicate(
            syndicateCount,
            _syndicateImageHash,
            msg.sender,
            block.timestamp,
            _syndicateName,
            _syndicateDescription,
            _nftName,
            _nftSymbol,
            address(_nftContract),
            _channelAddress
        );

        emit EventCreateSyndicate(
            syndicateCount,
            _syndicateImageHash,
            msg.sender,
            block.timestamp,
            _syndicateName,
            _syndicateDescription,
            _nftName,
            _nftSymbol,
            address(_nftContract),
            _channelAddress
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
    

    // * Add to Syndicate

    function addToSyndicate(address _to,uint256 _syndicateId) public {
        
        // * Get Syndicate
        Syndicate memory _syndicate = syndicates[_syndicateId];

        require(msg.sender == _syndicate.syndicateCreator, "Not Syndicate Owner");

        // * Mint NFT
        // Get the address of the NFT contract for the specified Syndicate
        address nftContractAddress = _syndicate.NftContract;

        // Add Member to Syndicate
        nftContract(nftContractAddress).safeMint(_to);

        // * Notify the Member
        // * Push Notification
        address channelAddress = _syndicate.channelAddress;

        string memory name = _syndicate.syndicateName;

        // * Send Notification to PUSH Comm
        bytes memory identity = abi.encodePacked("Welcome To ", name);
        IPUSHCommInterface(EPNS_COMM_ADDRESS).sendNotification(channelAddress, _to, identity);
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
        bool _hasImage,
        string memory _postImageHash,
        bool _isSpoiler,
        uint _syndicateId
    ) public {
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

        // * Check if Member of the Syndicate in which the Post is being Posted
        require(checkOwnership(msg.sender, _syndicateId), "Not a Syndicate Member");


        // Increment Post id
        postCount++;

        uint256 upvoteScore = 1;
        uint256 postTotal = 1;

        // Add Post to the contract
        posts[postCount] = Post(
            postCount,
            _postImageHash,
            _hasImage,
            _textContent,
            _memeTitle,
            msg.sender,
            block.timestamp,
            upvoteScore,
            0,
            _isSpoiler,
            _syndicateId
        );

        // check if user exist add to mapping if not create new from varibale
        User memory _user = users[msg.sender];

        // get variable for address if already created and update mapping record
        if (msg.sender == _user.addr) {
            // * User Already Exist
            addressToPosts[msg.sender].push(postCount); // Update Post array (address => Post.id)
            users[msg.sender].upvotesTotal = _user.upvotesTotal + 1;
            users[msg.sender].postTotal = _user.postTotal + 1;
        } else {
            // * Create New User
            addressToPosts[msg.sender].push(postCount); // Update Post array (address => Post.id)
            users[msg.sender] = User(msg.sender, 1, 0, postTotal);
            userCount++;
        }

        // Trigger an event
        emit PostCreated(
            postCount,
            _postImageHash,
            _hasImage,
            _textContent,
            _memeTitle,
            msg.sender,
            block.timestamp,
            upvoteScore,
            0,
            _isSpoiler,
            _syndicateId
        );
    }


    //* Add Comment to a Post in your Syndicate
    function addComment(
        uint256 _postId,
        string memory _commentMessage
    ) public {
        require(
            bytes(_commentMessage).length > 0 &&
                bytes(_commentMessage).length <= 280
        );

        // * Get Post Detail
        Post memory post = posts[_postId];

        // * Check if Member of the Syndicate in which the Post is Posted
        require(checkOwnership(msg.sender, post.syndicateId), "Not a Syndicate Member");

        comments[_postId].push(
            Comment(msg.sender, block.timestamp, _postId, _commentMessage)
        );
        // increments to reflect number of comments associted with post
        commentOnPosts[_postId] = commentOnPosts[_postId] + 1;

        emit CommentAdded(
            msg.sender,
            block.timestamp,
            _postId,
            _commentMessage
        );
    }

    //* Get All Comments for an Post
    function getComments(
        uint256 postId
    ) public view returns (Comment[] memory) {
        return comments[postId];
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
    function upvoteMeme(uint256 _id) public {
        // Make sure the id is valid
        require(_id > 0 && _id <= postCount);

        // Fetch the postId
        Post memory _post = posts[_id];

        // * Check if Member of the Syndicate in which the Post is Posted
        require(checkOwnership(msg.sender, _post.syndicateId), "Not a Syndicate Member");

        // Fetch the author
        address _author = _post.author;

        //Increment Upvote Counter
        _post.upvotes = _post.upvotes + 1;

        // user mapping
        User memory _user = users[_author];

        // update userTotalVotes
        users[_post.author].upvotesTotal = _user.upvotesTotal + 1;

        // Update the post
        posts[_id] = _post;

        // requires the upvoter not be the poster
        require(
            msg.sender != _author,
            "poster's can not upvote their own content"
        );

        // Trigger an event
        emit PostUpvotes(
            _id,
            _post.memeTitle,
            _author,
            _post.upvotes,
            _post.downvotes,
            _post.syndicateId
        );
    }

    //* Downvote a Post in your Syndicate
    function downvoteMeme(uint256 _id) public {
        // Make sure the id is valid
        require(_id > 0 && _id <= postCount);

        // Fetch the post
        Post memory _post = posts[_id];

        // * Check if Member of the Syndicate in which the Post is Posted
        require(checkOwnership(msg.sender, _post.syndicateId), "Not a Syndicate Member");

        // Fetch the author
        address _author = _post.author;

        //Increment Upvote Counter
        _post.downvotes = _post.downvotes + 1;

        // user mapping
        User memory _user = users[_author];

        // update userTotalVotes
        users[_post.author].downvotesTotal = _user.downvotesTotal + 1;

        // Update the Post
        posts[_id] = _post;

        // Trigger an event
        emit PostDownvotes(
            _id,
            _post.memeTitle,
            _author,
            _post.upvotes,
            _post.downvotes,
            _post.syndicateId
        );
    }

    //* Get Post upvotes
    function getUpvotes(uint256 _id) public view returns (uint256) {
        // Fetch the Post
        Post memory _post = posts[_id];
        return _post.upvotes;
    }

    //* Get Post upvotes
    function getDownvotes(uint256 _id) public view returns (uint256) {
        // Fetch the Post
        Post memory _post = posts[_id];
        return _post.downvotes;
    }


    //* View if Spoiler
    function getIsSpoiler(uint256 _id) public view returns (bool) {
        Post memory _post = posts[_id];
        return _post.isSpoiler;
    }

    //* View Platform User Count
    function getUserCount() public view returns (uint256) {
        return userCount;
    }

    // Get All Posts by User
    function getUserPosts(
        address _author
    ) public view returns (uint256[] memory) {
        return addressToPosts[_author];
    }
}
