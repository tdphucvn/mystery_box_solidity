// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/IERC1155Receiver.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/ERC165.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./MyToken.sol";

contract MysteryBox is IERC1155Receiver, ERC165, VRFConsumerBase {
    IERC1155 Token = IERC1155(0x831a991E53121021a9E09D0A2d1c7B40cCD613c0);
    MyToken public myToken;

    mapping(uint256 => address) public requestIdToSender;
    mapping(bytes32 => uint256) public requestIdToTokenId;
    mapping(uint256 => Box) public boxes;

    event requestedCollectible(bytes32 indexed requestId);
    event Withdraw(address admin, uint256 amount);
    event Received(address indexed sender, uint256 amount);
    event Result(
        uint256 id,
        uint256 randomSeed,
        uint256 randomReward,
        uint256 randomResult,
        uint256 time
    );

    bytes32 internal keyHash;
    uint256 internal fee;
    address payable public admin;
    uint256 public boxId = 0;
    uint256 public lastBoxId = 0;
    uint256 public randomResult = 0;
    uint256 public randomReward = 0;

    constructor(MyToken _myToken)
        VRFConsumerBase(
            0xa555fC018435bef5A13C6c6870a9d4C11DEC329C, // VRF Coordinator
            0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06 // LINK Token
        )
    {
        myToken = _myToken;
        keyHash = 0xcaf3c3727e033261d383b315559476f48034c13b18f8cafed4d871abe5049186;
        admin = payable(msg.sender);
        fee = 0.1 * 10**18; // 0.1 LINK (Varies by network)
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "caller is not the admin");
        _;
    }

    modifier onlyVFRC() {
        require(
            msg.sender == 0xa555fC018435bef5A13C6c6870a9d4C11DEC329C,
            "only VFRC can call this function"
        );
        _;
    }

    struct Box {
        uint256 id;
        uint256 seed;
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

    function openMysteryBox(uint256 seed)
        public
        payable
        returns (bytes32 requestId)
    {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        require(msg.value >= 0, "Ether must be greater than 0");
        bytes32 requestIdReturned = requestRandomness(keyHash, fee);
        requestIdToSender[boxId] = msg.sender;
        boxes[boxId] = Box(boxId, seed);
        emit requestedCollectible(requestIdReturned);

        boxId = boxId + 1;

        return requestIdReturned;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomNumber)
        internal
        override
    {
        uint256 randomness = randomNumber;
        verdict(randomness);
    }

    function verdict(uint256 random) public payable onlyVFRC {
        uint256 randomVerdict = (random % 100) + 1;
        randomResult = randomVerdict;

        //check bets from latest betting round, one by one
        for (uint256 i = lastBoxId; i < boxId; i++) {
            //reset reward for current user
            uint256 reward;

            if (randomResult <= 71) {
                reward = 0;
            } else if (randomResult <= 78) {
                reward = 1;
            } else if (randomResuslt <= 80) {
                reward = 2;
            } else {
                reward = 3;
            }
            randomReward = reward;

            // require(Token.balanceOf(address(this), reward) > 0, "Not enough rewards");
            if (reward < 3) {
                Token.safeTransferFrom(
                    address(this),
                    requestIdToSender[i],
                    reward,
                    1,
                    ""
                );
            } else {
                myToken.transfer(requestIdToSender[i], 10 * 10**18);
            }
            emit Result(
                boxes[i].id,
                boxes[i].seed,
                randomReward,
                randomResult,
                block.timestamp
            );
        }
        //save current gameId to lastGameId for the next betting round
        lastBoxId = boxId;
    }

    /**
     * Withdraw LINK from this contract (admin option).
     */
    function withdrawLink(uint256 amount) external onlyAdmin {
        require(LINK.transfer(msg.sender, amount), "Error, unable to transfer");
    }

    /**
     * Withdraw Ether from this contract (admin option).
     */
    function withdrawEther(uint256 amount) external payable onlyAdmin {
        require(
            address(this).balance >= amount,
            "Error, contract has insufficent balance"
        );
        admin.transfer(amount);

        emit Withdraw(admin, amount);
    }
}
