// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// from openzeppelin
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

// local
import "./SalesActivation.sol";

// Beatles
contract Beatles is
    Ownable,
    SalesActivation,
    EIP712,
    ERC721Enumerable
{

    string private _contractURI;
    string private _tokenBaseURI;

    // ------------------------------------------- const
    // total sales
    uint256 public constant TOTAL_MAX_QTY = 10000;

    // gift
    uint256 public constant GIFT_MAX_QTY = 1000;

    // max number of NFTs every wallet can buy
    uint256 public constant MAX_QTY_PER_MINTER = 1;

    // max number in presales
    uint256 public constant MAX_QTY_PER_MINTER_IN_PRESALES = 2;

    // max sales quantity
    uint256 public constant SALES_MAX_QTY = 9000;

    // ------------------------------------------- variable
    // minter
    mapping(address => uint256) public salesMinterToTokenQty;

    // sales quantity
    uint256 public salesMintedQty = 0;

    // gift quantity
    uint256 public giftedQty = 0;

    // init
    constructor() ERC721("Beatles", "Beatles") EIP712("Beatles", "1") {}

    // mint
    function mint(uint256 _mintQty)
        external
        isSalesActive
        callerIsUser
        payable
    {
        require(
            salesMintedQty + _mintQty <= SALES_MAX_QTY,
            "Exceed sales max limit!"
        );

        // plus one NFT if still in presales
        uint256 qtyPerMinter = MAX_QTY_PER_MINTER;
        if( isInPresales() ) {
            qtyPerMinter = MAX_QTY_PER_MINTER_IN_PRESALES;
        }
        require(
            salesMinterToTokenQty[msg.sender] + _mintQty <= qtyPerMinter,
            "Exceed max mint per minter!"
        );

        // update the quantity of the sales
        salesMinterToTokenQty[msg.sender] += _mintQty;
        salesMintedQty += _mintQty;

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
