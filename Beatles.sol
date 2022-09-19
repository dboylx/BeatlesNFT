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

    // max sales quantity
    uint256 public constant SALES_MAX_QTY = TOTAL_MAX_QTY - GIFT_MAX_QTY;

    // nft public sales price
    uint256 public constant PUBLIC_SALES_PRICE = 0.01 ether;

    // nft pre sales price
    uint256 public constant PRE_SALES_PRICE = 0.01 ether;


    // ------------------------------------------- variable
    // pre minter
    mapping(address => uint256) public publicSalesMinterToTokenQty;

    // public minter
    mapping(address => uint256) public preSalesMinterToTokenQty;

    // max number of NFTs every wallet can buy
    uint256 public max_qty_per_minter_in_public_sales = 2;

    // max number of NFTs every wallet can buy in presales
    uint256 public max_qty_per_minter_in_presales = 5;

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
            preSalesMinterToTokenQty[msg.sender] + _mintQty <= max_qty_per_minter_in_presales,
            "Exceed max mint per minter!"
        );
        require(
            msg.value >= _mintQty * PRE_SALES_PRICE,
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
            publicSalesMinterToTokenQty[msg.sender] + _mintQty <= max_qty_per_minter_in_public_sales,
            "Exceed max mint per minter!"
        );
        require(
            msg.value >= _mintQty * PUBLIC_SALES_PRICE,
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

    // set the quantity per minter can mint in public sales
    function setQtyPerMinterPublicSales(uint256 qty) external onlyOwner {
        max_qty_per_minter_in_public_sales = qty;
    }

    // set the quantity per minter can mint in pre sales
    function setQtyPerMinterPreSales(uint256 qty) external onlyOwner {
        max_qty_per_minter_in_presales = qty;
    }


    // ------------------------------------------- withdraw
    // withdraw all (if need)
    function withdrawAll() external onlyOwner  {
        require(address(this).balance > 0, "Withdraw: No amount");
        payable(msg.sender).transfer(address(this).balance);
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


    // not other contract
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "not user!");
        _;
    }


}
