// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// from openzeppelin
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

// local
import "./SalesActivation.sol";
import "./Whitelist.sol";

// Beatles
contract Beatles is
    Ownable,
    ERC721Enumerable,
    SalesActivation,
    Whitelist
{

    // ------------------------------------------- const
    // total sales
    uint256 public constant TOTAL_MAX_QTY = 10000;

    // gift
    uint256 public constant GIFT_MAX_QTY = 500;

    // max number of NFTs every wallet can buy
    uint256 public constant MAX_QTY_PER_MINTER_IN_PUBLIC_SALES = 1;

    // max number of NFTs every wallet can buy in presales
    uint256 public constant MAX_QTY_PER_MINTER_IN_PRESALES = 2;

    // max sales quantity
    uint256 public constant SALES_MAX_QTY = TOTAL_MAX_QTY - GIFT_MAX_QTY;

    // nft price
    uint256 public constant SALES_PRICE = 0.01 ether;


    // ------------------------------------------- variable
    // pre minter
    mapping(address => uint256) public publicSalesMinterToTokenQty;

    // public minter
    mapping(address => uint256) public preSalesMinterToTokenQty;

    // pre sales quantity
    uint256 public preSalesMintedQty = 0;

    // public sales quantity
    uint256 public publicSalesMintedQty = 0;

    // git quantity
    uint256 public giftedQty = 0;

    // contract URI
    string private _contractURI;

    // URI for NFT meta data
    string private _tokenBaseURI;

    // init for the contract
    constructor() ERC721("Beatles", "Beatles")   {}

    // pre mint
    function preMint(uint256 _mintQty)
        external
        isPreSalesActive
        callerIsUser
        payable
    {
        require(
            isInWhitelist(msg.sender),
            "Not in whitelist yet!"
        );
        require(
            publicSalesMintedQty + preSalesMintedQty + _mintQty <= SALES_MAX_QTY,
            "Exceed sales max limit!"
        );
        require(
            preSalesMinterToTokenQty[msg.sender] + _mintQty <= MAX_QTY_PER_MINTER_IN_PRESALES,
            "Exceed max mint per minter!"
        );
        require(
            msg.value >= _mintQty * SALES_PRICE,
            "Insufficient ETH!"
        );

        // update the quantity of the sales
        preSalesMinterToTokenQty[msg.sender] += _mintQty;
        preSalesMintedQty += _mintQty;

        // safe mint for every NFT
        for (uint256 i = 0; i < _mintQty; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }

    }

    // mint for public
    function mint(uint256 _mintQty)
        external
        isPublicSalesActive
        callerIsUser
        payable
    {
        require(
            publicSalesMintedQty + preSalesMintedQty + _mintQty <= SALES_MAX_QTY,
            "Exceed sales max limit!"
        );
        require(
            publicSalesMinterToTokenQty[msg.sender] + _mintQty <= MAX_QTY_PER_MINTER_IN_PUBLIC_SALES,
            "Exceed max mint per minter!"
        );
        require(
            msg.value >= _mintQty * SALES_PRICE,
            "Insufficient ETH"
        );

        // update the quantity of the sales
        publicSalesMinterToTokenQty[msg.sender] += _mintQty;
        publicSalesMintedQty += _mintQty;

        // safe mint for every NFT
        for (uint256 i = 0; i < _mintQty; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }

    }

    // airdrop
    function gift(address[] calldata receivers) external onlyOwner {
        require(
            giftedQty + receivers.length <= GIFT_MAX_QTY,
            "Exceed gift max limit"
        );

        giftedQty += receivers.length;

        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], totalSupply() + 1);
        }

    }


    // set contract URI
    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }

    // set base uri
    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    // get contract uri
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    // get the base uri
    function _baseURI()
        internal
        view
        override(ERC721)
        returns (string memory)
    {
        return _tokenBaseURI;
    }

    // withdraw all (if need)
    function withdrawAll() external onlyOwner  {
        require(address(this).balance > 0, "Withdraw: No amount");
        payable(msg.sender).transfer(address(this).balance);
    }

    // not other contract
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "not user!");
        _;
    }


}
