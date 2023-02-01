// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";


contract Reddit {
    address owner;

    // ? ------User
    // User Mapping
    mapping(address => User) public users;

    // user curated spaces (join spaces)
    // Space Ids user have joined
    mapping(address => uint256[]) public userSpaces;

    // Unique wallets / users
    uint256 public userCount = 0;

    // ? -------Image (Posts)
    // Image index
    uint256 public imageCount = 0;

    // Id to Image
    mapping(uint256 => Image) public images;

    // create array to store image hash (addr -> hash[])
    mapping(address => uint256[]) posts;

    // ? ------Space
    // Space name Index
    uint256 public spaceCount = 0;

    // Id to Space
    mapping(uint256 => Space) public spaces;

    // ? ------Comments
    // create comments mapping (imageId -> comment)
    mapping(uint256 => Comment[]) public comments;

    // create mapping to keep inventory on number of comments per image
    mapping(uint256 => uint256) public commentOnPosts;

    // Creator earned index
    // Address to Earning
    mapping(address => uint256) public totalEarnings;

    // ? ------STRUCTURES
    // Space Structure
    struct Space {
        uint256 spaceCount;
        address spaceCreator;
        uint256 dateCreated;
        string spaceName;
        string spaceDescription;
        address NftContract;
    }

    // Profile of User
    struct User {
        address addr;
        uint256 upvotesTotal;
        uint256 downvotesTotal;
        uint256 postTotal;
        bool isVerified;
    }

    // Image Proprerty Struct
    struct Image {
        uint256 id;
        string hash;
        string memeTitle;
        string creditSource;
        uint256 tipAmount;
        address payable author;
        uint256 datePosted;
        uint256 upvotes;
        uint256 downvotes;
        //convert to bool
        bool isSpoiler;
        bool isOC;
        uint256 spaceName;
    }

    // Comment structure assoicated with image
    struct Comment {
        address addr;
        uint256 datePosted;
        uint256 imageId;
        string commentMessage;
    }

    // ? EVENTS

    event EventCreateSpace(
        uint256 spaceCount,
        address spaceCreator,
        uint256 dateCreated,
        string spaceName,
        string spaceDescription,
        address NftContract
    );

    event EventJoinSpaces(uint256 id);

    event ImageCreated(
        uint256 id,
        string hash,
        string memeTitle,
        string creditSource,
        uint256 tipAmount,
        address payable author,
        uint256 datePosted,
        uint256 upvotes,
        uint256 downvotes,
        bool isSpoiler,
        bool isOC,
        uint256 spaceName
    );

    event ImageTipped(
        uint256 id,
        string hash,
        string memeTitle,
        string description,
        uint256 tipAmount,
        address payable author,
        address patron
    );

    event ImageUpvotes(
        uint256 id,
        string hash,
        string memeTitle,
        string description,
        uint256 tipAmount,
        address payable author,
        uint256 upvotes,
        uint256 downvotes
    );

    event ImageDownvotes(
        uint256 id,
        string hash,
        string memeTitle,
        string description,
        uint256 tipAmount,
        address payable author,
        uint256 upvotes,
        uint256 downvotes
    );

    event CommentAdded(
        address addr,
        uint256 datePosted,
        uint256 imageId,
        string commentMessage
    );

    

    event TransferReceived(address _from, uint256 _amount);
    event TransferSent(address _from, address _destAddr, uint256 _amount);

    constructor() {
        owner = msg.sender;
        console.log("Deploying JoinSpace Smart Contract by Owner Add:", owner);
    }

    // * Contract Owner Only
    modifier onlyOwner() {
        require(owner == msg.sender, "Not the Owner");
        _;
    }

    // Space Members
    modifier onlyMembers(uint256 _spaceId) {
        require(checkOwnership(msg.sender, _spaceId), "Not authorized");
        _;
    }

    // * Check Member Function
    function checkOwnership(address _user, uint256 _spaceId) public view returns (bool) {
        // Get the address of the NFT contract for the specified space
        address nftContract = spaceArray[_spaceId].NftContract;

        // Call the balanceOf function on the NFT contract to get the number of NFTs owned by the user
        uint256 balance = ERC721(nftContract).balanceOf(_user);

        // Return true if the user has at least one NFT in the NFT contract, otherwise return false
        return balance > 0;
    }


    // Create JoinSpace Spaces
    // Requirement: Wallet Address must reach the minimum threashold of ETH and ERC20 Tokens
    function createSpace(
        string memory _spaceName,
        string memory _spaceDescription,
        IERC20 token
    ) public payable {
        // Requires space name to be less than 21 words
        require(bytes(_spaceName).length > 0 && bytes(_spaceName).length <= 21);
        require(
            bytes(_spaceDescription).length > 0 &&
                bytes(_spaceDescription).length <= 100
        );

        // Add to index
        spaceCount++;

        // Create an instance of the ERC721 contract
        ERC721 erc721 = new ERC721(_name, _symbol);

        // Add to spaces mapping
        spaces[spaceCount] = Space(
            spaceCount,
            msg.sender,
            block.timestamp,
            _spaceName,
            _spaceDescription,
            address(erc721)
        );

        emit EventCreateSpace(
            spaceCount,
            msg.sender,
            block.timestamp,
            _spaceName,
            _spaceDescription,
            address(erc721)
        );
    }

    // JoinSpace - join a space based on the spaceId
    function joinSpaces(uint256 _spaceId) public {
        userSpaces[msg.sender].push(_spaceId);
        emit EventJoinSpaces(_spaceId);
    }

    // return all the spaces associated with the user
    function getJoinSpaces(
        address _user
    ) public view returns (uint256[] memory) {
        return userSpaces[_user];
    }

    // retrieve the space name by search
    function getCreatorSpace(uint256 _id) public view returns (string memory) {
        return spaces[_id].spaceName;
    }

    // Upload Text Content
    function uploadTextContent(
        string memory _textContent,
        string memory _memeTitle,
        string memory _creditSource,
        bool _isSpoiler,
        bool _isOC,
        uint256 _spaceName
    ) public payable {
        // Enure the text content exists
        require(
            bytes(_textContent).length > 0 && bytes(_textContent).length <= 500
        );
        // Ensure image description
        require(
            bytes(_memeTitle).length > 0 && bytes(_memeTitle).length <= 100
        );
        // Ensure image description
        require(bytes(_creditSource).length <= 140);
        // Enure uploader address exists
        require(msg.sender != address(0));

        // Increment image id
        imageCount++;

        uint256 upvoteScore = 1;
        uint256 postTotal = 1;

        // Add Image to the contract
        images[imageCount] = Image(
            imageCount,
            _textContent,
            _memeTitle,
            _creditSource,
            0,
            payable(msg.sender),
            block.timestamp,
            upvoteScore,
            0,
            _isSpoiler,
            _isOC,
            _spaceName
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
            _textContent,
            _memeTitle,
            _creditSource,
            0,
            payable(msg.sender),
            block.timestamp,
            upvoteScore,
            0,
            _isSpoiler,
            _isOC,
            _spaceName
        );
    }

    // Upload image
    function uploadImage(
        string memory _imgHash,
        string memory _memeTitle,
        bool _isSpoiler,
        bool _isOC,
        uint256 _spaceName
    ) public payable {
        // Enure the image title hash exists
        require(bytes(_imgHash).length > 0 && bytes(_imgHash).length <= 100);
        // Ensure image description
        require(
            bytes(_memeTitle).length > 0 && bytes(_memeTitle).length <= 100
        );

        // Enure uploader address exists
        require(msg.sender != address(0));

        // Increment image id
        imageCount++;

        uint256 upvoteScore = 1;
        uint256 postTotal = 1;

        // Add Image to the contract
        images[imageCount] = Image(
            imageCount,
            _imgHash,
            _memeTitle,
            _creditSource,
            0,
            payable(msg.sender),
            block.timestamp,
            upvoteScore,
            0,
            _isSpoiler,
            _isOC,
            _spaceName
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
            _creditSource,
            0,
            payable(msg.sender),
            block.timestamp,
            upvoteScore,
            0,
            _isSpoiler,
            _isOC,
            _spaceName
        );
    }

    // add a comment to an image. Comments structs appended to comment mapping of struct
    function addComment(
        uint256 _imageId,
        string memory _commentMessage
    ) public {
        require(
            bytes(_commentMessage).length > 0 &&
                bytes(_commentMessage).length <= 280
        );

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

    // get following comments
    function getComments(
        uint256 imageId
    ) public view returns (Comment[] memory) {
        return comments[imageId];
    }

    // total number of upvotes by user
    function getUserUpvotesTotal(
        address _userAddr
    ) public view returns (uint256) {
        User memory _user = users[_userAddr];
        return _user.upvotesTotal;
    }

    // total number of downvotes by user
    function getUserDownvotesTotal(
        address _userAddr
    ) public view returns (uint256) {
        User memory _user = users[_userAddr];
        return _user.downvotesTotal;
    }

    // total number of post by user
    function getUserpostTotal(address _userAddr) public view returns (uint256) {
        User memory _user = users[_userAddr];
        return _user.postTotal;
    }

    // Verify User based on Twitter Post -> can be unverified
    function verifyUser(bool check) public {
        // Requires user to have already posted
        User memory _user = users[msg.sender];
        require(
            _user.addr == msg.sender,
            "You need to post before verification"
        );
        users[msg.sender].isVerified = check;
    }

    // getVerified Status of User
    function isVerifiedUser(address _userAddr) public view returns (bool) {
        User memory _user = users[_userAddr];
        return users[_userAddr].isVerified;
    }

    //tip owner any amount of ETH
    function tipImageOwner(uint256 _id) public payable {
        // Make sure the id is valid
        require(_id > 0 && _id <= imageCount);

        // Fetch the image
        Image memory _image = images[_id];

        // Fetch the author
        address payable _author = _image.author;

        // Pay the author by sending them Ether
        payable(_author).transfer(msg.value);

        // Increment the tip amount
        _image.tipAmount = _image.tipAmount + msg.value;

        // Increment total earnings overall
        totalEarnings[_image.author] += _image.tipAmount;

        // Update the image
        images[_id] = _image;

        // Trigger an event
        emit ImageTipped(
            _id,
            _image.hash,
            _image.memeTitle,
            _image.creditSource,
            _image.tipAmount,
            _author,
            msg.sender
        );
    }

    function upvoteMeme(uint256 _id, IERC20 token) public payable {
        // Make sure the id is valid
        require(_id > 0 && _id <= imageCount);

        // Fetch the image
        Image memory _image = images[_id];

        // Fetch the author
        address payable _author = _image.author;

        //Increment Upvote Counter
        _image.upvotes = _image.upvotes + 1;

        // user mapping
        User memory _user = users[_author];

        // update userTotalVotes
        users[_image.author].upvotesTotal = _user.upvotesTotal + 1;

        // Update the image
        images[_id] = _image;

        //  Upvote Token Amount
        uint256 tokenUpvote = 100;

        // requires the upvoter not be the poster
        require(
            msg.sender != _author,
            "poster's can not upvote their own content"
        );

        //balance of the smart contract -> note ".this" refers to the contract instance
        // Send balance to the contract not the address of the minter
        uint256 erc20balance = token.balanceOf(address(this));
        require(tokenUpvote <= erc20balance, "balance is low");
        token.transfer(_author, tokenUpvote);
        emit TransferSent(msg.sender, _author, tokenUpvote);

        // Trigger an event
        emit ImageUpvotes(
            _id,
            _image.hash,
            _image.memeTitle,
            _image.creditSource,
            _image.tipAmount,
            _author,
            _image.upvotes,
            _image.downvotes
        );
    }

    function downvoteMeme(uint256 _id) public payable {
        // Make sure the id is valid
        require(_id > 0 && _id <= imageCount);

        // Fetch the image
        Image memory _image = images[_id];

        // Fetch the author
        address payable _author = _image.author;

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
            _image.creditSource,
            _image.tipAmount,
            _author,
            _image.upvotes,
            _image.downvotes
        );
    }

    //Get Image upvotes
    function getUpvotes(uint256 _id) public view returns (uint256) {
        // Fetch the image
        Image memory _image = images[_id];
        return _image.upvotes;
    }

    //Get Image upvotes
    function getDownvotes(uint256 _id) public view returns (uint256) {
        // Fetch the image
        Image memory _image = images[_id];
        return _image.downvotes;
    }

    //View Post Earnings
    function imageEarnings(uint256 _id) public view returns (uint256) {
        // Fetch the image
        Image memory _image = images[_id];
        return _image.tipAmount;
    }

    //View User Earnings
    function getTotalEarnings(address _author) public view returns (uint256) {
        uint256 totalEarned = totalEarnings[_author];
        return totalEarned;
    }

    // View if Spoiler
    function getIsSpoiler(uint256 _id) public view returns (bool) {
        Image memory _image = images[_id];
        return _image.isSpoiler;
    }

    // View Platform User Count
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
