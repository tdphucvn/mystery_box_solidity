// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/IERC1155Receiver.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/ERC165.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract MysteryBox is IERC1155Receiver, ERC165, VRFConsumerBase {
    // Contract of the Rewards
    IERC1155 Token = IERC1155(0x36031F8d2aDA94739B191dc889fb5F538f8d3FAC);

    mapping(bytes32 => address) public requestIdToSender;
    mapping(bytes32 => uint256) public requestIdToTokenId;
    event requestedCollectible(bytes32 indexed requestId);

    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult = 0;
    uint256 public randomReward = 0;

    constructor()
        VRFConsumerBase(
            0xa555fC018435bef5A13C6c6870a9d4C11DEC329C, // VRF Coordinator
            0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06 // LINK Token
        )
    {
        keyHash = 0xcaf3c3727e033261d383b315559476f48034c13b18f8cafed4d871abe5049186;
        fee = 0.1 * 10**18; // 0.1 LINK (Varies by network)
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function openMysteryBox() public returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        bytes32 requestIdReturned = requestRandomness(keyHash, fee);
        requestIdToSender[requestIdReturned] = msg.sender;
        emit requestedCollectible(requestIdReturned);

        return requestIdReturned;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomNumber)
        internal
        override
    {
        uint256 reward;
        uint256 random = (randomNumber % 100) + 1;

        randomResult = random;

        if (random <= 71) {
            reward = 0;
        } else if (random <= 78) {
            reward = 1;
        } else if (random <= 80) {
            reward = 2;
        } else {
            reward = 3;
        }

        randomReward = reward;

        require(
            Token.balanceOf(address(this), reward) > 0,
            "Not enough rewards"
        );
        Token.safeTransferFrom(
            address(this),
            requestIdToSender[requestId],
            reward,
            1,
            ""
        );
    }
}
