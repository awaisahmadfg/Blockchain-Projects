// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract MyClub is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, ERC721BurnableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // CountersUpgradeable.Counter private _tokenIdCounter;
    uint256 public chnagegohar;
    uint256 public chnagegohar2;

    // Library usage
    using CountersUpgradeable for CountersUpgradeable.Counter ;
    using SafeMathUpgradeable for uint;
    using StringsUpgradeable for uint256;
    CountersUpgradeable.Counter private _tokenIdCounter;


    // Mappings    
    mapping(uint256 => address) public _owners;
    mapping(uint256 => string) private _tokenURIs;
    mapping(address => uint) public pendingResturns;
    // check if token URI exists
    mapping(string => bool) public tokenURIExists;

    // State Var's
    string private _baseURIextended;
    uint256 public amountfee;
    uint256 public royaltyfee;
    uint256 public highestBid;
    uint256 public default_fee;  
    address public nftminter;
    address public highestBidder;
    address payable public beneficiary;
    address payable public nftOwnerAddress;

    bool ended;
    address public productowner;


// ****************************************************************************************************************************************************
    /// @custom:oz-upgrades-unsafe-allow constructor
   constructor() {_disableInitializers();}

    // constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {_disableInitializers();}

    function initialize(string memory _name, string memory _symbol) initializer public {
        __ERC721_init( _name, _symbol);
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __ERC721Burnable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        default_fee = 20;
        ended = false;
        productowner = 0x95696F1A2c35a48e3F8Aafbfc4b8c8Fb00f3Ff15;
    }

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    // function tokenURI(uint256 tokenId)
    //     public
    //     view
    //     override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    //     returns (string memory)
    // {
    //     return super.tokenURI(tokenId);
    // }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

//******************************************************************************************************************************************
        // Structs
    struct FixedPrice 
    {
        bool isSold;
        bool forsale;
        uint256 paid;
        uint256 price;
        uint256 fixedid;
        uint256 tokenid;
       // uint256 totalcopies;
        address owner;
        address newowner;
    }
    
    struct Auction 
    {
        bool isSold;
        bool OpenForBidding;
        uint256 tokenId;
        uint256 auctionid;
       // uint256 numberofcopies;
        uint256 auctionEndTime;
        uint256 auctionStartTime;
        uint256 currentBidAmount;
        address currentBidOwner;
        address payable beneficiary;        
    }    

    // Dynamic Array
    FixedPrice[] public Fixedprices;
    Auction[] public auctions;

    // Events
    event AuctionStart(uint256 _auctionid);
    event OfferSale(uint256 _fixeditemid);
    event AuctionEnded(address winner, uint amount);
    event HighestBidIcrease(address bidder, uint amount);
    
    // Modifiers
    modifier IsForSale(uint256 id){
        require(Fixedprices[id].isSold == false, "Item is already sold");
        _;
    }

    modifier onlyTokenHolders(uint256 tokenid){
        require(balanceOf(msg.sender) > 0 , "Only owners of this token can access this");
         _;
    }

    modifier ItemExists(uint256 id){
        require(id < Fixedprices.length && Fixedprices[id].fixedid == id, "Could not find Item");
        _;
    }

    // Functions    
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual override {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function setBaseURI(string memory baseURI_) internal virtual{
        _baseURIextended = baseURI_;
    }

    function tokenURI(uint256 tokenId) public view virtual override (ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        
        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    function mint(address account, string memory tokenuri)  public
    {    
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(account, tokenId);
        // _setURI(tokenId,tokenuri);
        // check if the token URI already exists or not
        require(!tokenURIExists[tokenuri],"URI Already Exists");
        // make passed token URI as exists
        tokenURIExists[tokenuri] = true;
        _setTokenURI(tokenId,tokenuri);
        _owners[tokenId] = account;
         nftminter = account;     
    }

    // Auction --------------------------------------------------------------------------------
    
    function putOnSale(uint256 _tokenId,uint256 _price) public  onlyTokenHolders(_tokenId) returns(uint256)
    {
        uint256 newItemId = Fixedprices.length;
        Fixedprices.push(FixedPrice(false,true,0,_price,newItemId,_tokenId,msg.sender,address(0)));
        emit OfferSale(newItemId);
        return newItemId;
    }

    function startAuction(uint _biddingStartTime,uint _biddingendtime , address payable _beneficiary , uint256 tokenId) public onlyTokenHolders(tokenId) returns(uint256)
    {
        uint256 newauctionid = auctions.length;
        auctions.push(Auction(false,true,tokenId,newauctionid,_biddingStartTime,_biddingendtime,0,address(0),_beneficiary));
        emit AuctionStart(newauctionid);
        return newauctionid;
    }        

    function BuyFixedPriceNFT(uint256 Id)payable public ItemExists(Id) IsForSale(Id) returns (bool)
    {
        require(msg.value >=  Fixedprices[Id].price,"send wrong amount in fixed price");
        require(Fixedprices[Id].forsale,"This NFT is not for sale");
    
        Fixedprices[Id].paid = msg.value; 
        Fixedprices[Id].newowner = msg.sender;
        transferFrom(Fixedprices[Id].owner,Fixedprices[Id].newowner,Fixedprices[Id].tokenid);
    
        uint256 onePercentofTokens  = Fixedprices[Id].paid.mul(100).div(100 * 10 ** uint256(2));
        uint256 twoPercentOfTokens  = onePercentofTokens.mul(2);
        uint256 halfPercentOfTokens = onePercentofTokens.div(2);
    
        amountfee = twoPercentOfTokens + halfPercentOfTokens;
        royaltyfee = twoPercentOfTokens + halfPercentOfTokens;
    
        payable(Fixedprices[Id].owner).transfer(Fixedprices[Id].paid.sub(amountfee+royaltyfee));
        payable(nftminter).transfer(royaltyfee);
        payable(productowner).transfer(amountfee);
    
        Fixedprices[Id].isSold = true;
    
        return true;
    }

  
    function bid( uint256 Id) payable public
    {   
        require(auctions[Id].OpenForBidding,"Bidding is not open yet");
        require(_owners[Id] != msg.sender, "owner cannot bid");

        address  currentBidOwner = auctions[Id].currentBidOwner;
        uint256  currentBidAmount = auctions[Id].currentBidAmount;
     
        if(msg.value <=  currentBidAmount) {
            revert("There is already higher or equal bid exist");
        }
        if( currentBidAmount !=0) {
            pendingResturns[currentBidOwner] += currentBidAmount;
        }
        if(msg.value > currentBidAmount ) {
            payable(currentBidOwner).transfer(currentBidAmount);
        }
     
        auctions[Id].currentBidOwner  = msg.sender;
        auctions[Id].currentBidAmount = msg.value; 
        highestBidder =  auctions[Id].currentBidOwner;
        highestBid    =  auctions[Id].currentBidAmount;
     
        emit HighestBidIcrease(msg.sender , msg.value);
    }

    function auctionEnd(uint256 Id) public 
    {
        if(!auctions[Id].OpenForBidding){
            revert("The function auctionEnded is already called");
        }
        
        if(auctions[Id].currentBidOwner != address(0))
        {
        
        emit AuctionEnded(highestBidder , highestBid);
        
        uint256 onePercentofTokens = highestBid.mul(100).div(100 * 10 ** uint256(2));
        uint256 twoPercentOfTokens = onePercentofTokens.mul(2);
        uint256 halfPercentOfTokens = onePercentofTokens.div(2);
        
        amountfee = twoPercentOfTokens + halfPercentOfTokens;
        royaltyfee = twoPercentOfTokens + halfPercentOfTokens;
        auctions[Id].beneficiary.transfer(highestBid.sub(amountfee+royaltyfee));
        
        payable(nftminter).transfer(royaltyfee);
        payable(productowner).transfer(amountfee);
        
        transferFrom(auctions[Id].beneficiary,highestBidder,auctions[Id].tokenId);
        auctions[Id].isSold = true;
        }
    }

    function claimNft(uint256 Id) public  returns(bool) 
    {
        if(!auctions[Id].OpenForBidding){
            revert("You already have claimed for your NFT");
        }
        emit AuctionEnded(highestBidder, highestBid);
        
        uint256 onePercentofTokens = highestBid.mul(100).div(100 * 10 ** uint256(2));
        uint256 twoPercentOfTokens = onePercentofTokens.mul(2);
        uint256 halfPercentOfTokens = onePercentofTokens.div(2);
        
        amountfee = twoPercentOfTokens + halfPercentOfTokens;
        royaltyfee = twoPercentOfTokens + halfPercentOfTokens;
        auctions[Id].beneficiary.transfer(highestBid.sub(amountfee+royaltyfee));
        
        payable(nftminter).transfer(royaltyfee);
        payable(productowner).transfer(amountfee);
        
        transferFrom(auctions[Id].beneficiary,msg.sender,auctions[Id].tokenId);
        auctions[Id].isSold = true;
       
        return true;   
    }
////////////////////////////////////////////////////////////////////////////

  // get owner of the token
  function getTokenOwner(uint256 _tokenId) public view returns(address) {
    address _tokenOwner = ownerOf(_tokenId);
    return _tokenOwner;
  }

  // get metadata of the token
  function getTokenMetaData(uint _tokenId) public view returns(string memory) {
    string memory tokenMetaData = tokenURI(_tokenId);
    return tokenMetaData;
  }

  // get total number of tokens minted so far
  function getNumberOfTokensMinted() public view returns(uint256) {
    uint256 totalNumberOfTokensMinted = totalSupply();
    return totalNumberOfTokensMinted;
  }

  // get total number of tokens owned by an address
  function getTotalNumberOfTokensOwnedByAnAddress(address _owner) public view returns(uint256) {
    uint256 totalNumberOfTokensOwned = balanceOf(_owner);
    return totalNumberOfTokensOwned;
  }

    // check if the token already exists
  function getTokenExists(uint256 _tokenId) public view returns(bool) {
    bool tokenExists = _exists(_tokenId);
    return tokenExists;
  }  




}