// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";



/// Contract ///
contract MyNFT is ERC721A, Ownable, ReentrancyGuard {  
    using Address for address;
    using Strings for uint256;

    // Constants //

    //supply
    uint256 constant MAX_SUPPLY = 999;
    //price
    uint256 public price = 0.005 ether;
    //MaxPerWallet 
    uint256 public maxMint = 2; 
    uint256 public maxPresaleMint = 2; 
        address public proxyRegistryAddress;



    bool public saleActive;
    bool public presaleActive;

    string public _baseTokenURI;
    string public NFTProvenance;

    mapping (address => uint256) public _tokensMintedByAddress;
    mapping (address => uint256) public publicsaleAddressMinted;
     mapping(address => bool) public projectProxy;
    bytes32 public presaleMerkleRoot;
    

    // Founders and Project Addresses //
    address a1 = 0xEa64073446E6AFd80574D8a72c8E9af547a43018;
    address a2 = 0xEa64073446E6AFd80574D8a72c8E9af547a43018;
  

    // Constructor //
    constructor(address _proxyRegistryAddress )
        ERC721A("MyNFT", "MNFT") {    
                           proxyRegistryAddress = _proxyRegistryAddress;
      
    }

    // Modifiers //
    modifier onlySaleActive() {
        require(saleActive, "Public sale is not active");
        _;
    }

    modifier onlyPresaleActive() {
        require(presaleActive, "Presale is not active");
        _;
    }

    // Minting Functions //

    // Public sale minting function, max 2 per wallet
    function mintToken(uint256 quantity) external payable onlySaleActive nonReentrant() {
        require(quantity <= maxMint, "You can not mint more than alowed");
        require(price * quantity == msg.value, "Wrong amout of ETH sent");
        require(publicsaleAddressMinted[msg.sender] + quantity <= maxMint, "Can only mint 2 per wallet");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Can not mint more than max supply");

        publicsaleAddressMinted[msg.sender] += quantity;
           _safeMint( msg.sender, quantity);
    } 

    // Presale minting function, max (x).
    function mintPresale(uint256 quantity, bytes32[] memory proof) external payable onlyPresaleActive nonReentrant() {
        require(MerkleProof.verify(proof, presaleMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Address is not on 1 MINT Allowlist");
        require(price * quantity == msg.value, "Wrong amout of ETH sent");
        require(_tokensMintedByAddress[msg.sender] + quantity == maxPresaleMint, "Can only mint 1 token during PreSale");
        require(totalSupply() + quantity < MAX_SUPPLY, "Can not mint more than max supply");

        _tokensMintedByAddress[msg.sender] += quantity;
         _safeMint(msg.sender, quantity);
     
    }


   

    // Dev minting function 
        function mintDev(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Minting too many");
        _safeMint(msg.sender, quantity);
    }
    
    // Metadata //
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // Setters //
	function setPresaleMerkleRoot(bytes32 presaleRoot) public onlyOwner {
		presaleMerkleRoot = presaleRoot;
	}

 

    function setPresaleActive(bool val) external onlyOwner {
        presaleActive = val;
    }

    function setSaleActive(bool val) external onlyOwner {
        saleActive = val;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setMaxMint(uint256 _maxMint) external onlyOwner {
        maxMint = _maxMint;
    }

    function setMaxPresaleMint(uint256 _maxPresaleMint) external onlyOwner {
        maxPresaleMint = _maxPresaleMint;
    }


    function setProvenanceHash(string memory provenanceHash) external onlyOwner {
        NFTProvenance = provenanceHash;
    }

    // Withdraw funds from contract for the founders and Project Wallet.
    // This is a template. Modify according to your needs.
    function withdrawAll() public payable onlyOwner {
        uint256 _balance = address(this).balance;
        uint256 percent = _balance / 100;
        // 50/50 Split among the team
        require(payable(a1).send(percent * 50));
        require(payable(a2).send(percent * 50));
        
       
    }

        // Proxy Functions
    function setProxyRegistryAddress(address _proxyRegistryAddress)  external view onlyOwner {
        _proxyRegistryAddress = _proxyRegistryAddress;
    }

    function flipProxyState(address _proxyAddress) public onlyOwner {
        projectProxy[_proxyAddress] = !projectProxy[_proxyAddress];
    }

    // OpenSea Secondary Contract Approval - Removes initial approval gas fee from sellers
    // Allow future contract approval
    function isApprovedForAll(address _owner, address _operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator || projectProxy[_operator]) return true;
        return super.isApprovedForAll(_owner, _operator);
    }


}
 


contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}