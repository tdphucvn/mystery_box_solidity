// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol";

//Create ERC1155 token as the standard for the Rewards
contract Rewards is ERC1155 {
    uint256 public constant COMMON = 0;
    uint256 public constant RARE = 1;
    uint256 public constant EXCLUSIVE = 2;
    uint256 public constant ADEN = 3;

    //mint 100 rewards of each category for the creator of the contract
    //after minting the creator has to send the rewards to the contract of the mystery box
    constructor() ERC1155("") {
        _mint(msg.sender, COMMON, 100, "");
        _mint(msg.sender, RARE, 100, "");
        _mint(msg.sender, EXCLUSIVE, 100, "");
    }
}
