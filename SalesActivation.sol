// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

// sales config
contract SalesActivation is Ownable {

    // public sales start time
    uint256 public publicSalesStartTime;

    // pre sales seconds
    uint256 public preSalesSeconds = 3600;

    modifier isSalesActive() {
        require(
            isPublicSalesActivated(),
            "Public sales: Sale is not activated"
        );
        _;
    }

    constructor() {}

    // set public sales time
    function setPublicSalesTime(uint256 _startTime) external onlyOwner {
        publicSalesStartTime = _startTime;
    }

    // set pre sales seconds
    function setPreSalesSeconds(uint256 _seconds) external onlyOwner {
        preSalesSeconds = _seconds;
    }

    // is public sales activated
    function isPublicSalesActivated() public view returns (bool) {
        return
            publicSalesStartTime > 0 && block.timestamp >= publicSalesStartTime;
    }

    // is the time still in presales
    function isInPresales() public view returns (bool) {
        return block.timestamp - publicSalesStartTime < preSalesSeconds;
    }
}
