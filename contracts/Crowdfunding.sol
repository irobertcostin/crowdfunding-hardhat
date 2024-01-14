// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Crowdfunding is ReentrancyGuard {
    address public owner;
    IERC20 public acceptedToken =
        IERC20(0x7DC2A27B35d7b4e1faD20dAd8c844443C65462DE);
    uint256 public fundTarget = 10 ether;
    uint256 public startTime = 1705240800;
    uint256 public endTime = 1705327200;

    mapping(address => uint256) public contributions;

    event Contribution(address indexed contributor, uint256 amount);
    event RefundClaimed(address indexed contributor, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier isValidToken(IERC20 _token) {
        require(_token == acceptedToken, "Only accepted token allowed");
        _;
    }

    modifier isValidPhase() {
        require(
            block.timestamp >= startTime && block.timestamp <= endTime,
            "Invalid phase"
        );
        _;
    }

    modifier hasNotReachedTarget() {
        require(
            getTotalContributions() < fundTarget,
            "Fundraising target reached"
        );
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function getCurrentPhase() external view returns (string memory) {
        if (block.timestamp < startTime) {
            return "Before Fundraising";
        } else if (block.timestamp <= endTime) {
            return "During Fundraising";
        } else {
            return "After Fundraising";
        }
    }

    function getRemainingTime() external view isValidPhase returns (uint256) {
        return endTime - block.timestamp;
    }

    function contribute(
        uint256 amount,
        IERC20 _token
    )
        external
        isValidToken(_token)
        isValidPhase
        hasNotReachedTarget
        nonReentrant
    {
        if (getTotalContributions() >= fundTarget) {
            revert("Funding target reached");
        }

        require(amount > 0, "Invalid contribution amount");

        uint256 remainingUntilTarget = fundTarget - getTotalContributions();
        uint256 userContribution = amount;
        uint256 differenceToBeRefunded;

        require(
            _token.transferFrom(msg.sender, address(this), userContribution),
            "Token transfer failed"
        );

        if (userContribution > remainingUntilTarget) {
            differenceToBeRefunded = userContribution - remainingUntilTarget;
        }

        contributions[msg.sender] += userContribution;

        emit Contribution(msg.sender, userContribution);

        if (differenceToBeRefunded > 0) {
            _token.transfer(msg.sender, differenceToBeRefunded);
            contributions[msg.sender] -= differenceToBeRefunded;
        }
    }

    function getTotalContributions() public view returns (uint256) {
        return acceptedToken.balanceOf(address(this));
    }

    function claimRefund() external nonReentrant hasNotReachedTarget {
        require(
            block.timestamp > endTime && getTotalContributions() < fundTarget,
            "Either it's not the end of funding, or the fund target has been reached and deploy comes next"
        );

        uint256 refundAmount = contributions[msg.sender];
        require(refundAmount > 0, "No refund available");

        require(
            acceptedToken.transfer(msg.sender, refundAmount),
            "Token transfer failed"
        );

        contributions[msg.sender] = 0;
    }

    function withdrawFunds() external onlyOwner {
        require(
            block.timestamp > endTime && getTotalContributions() >= fundTarget,
            "Either it's not the end of funding, or the fund target hasn't been reached."
        );

        uint256 balance = getTotalContributions();
        require(
            acceptedToken.transfer(owner, balance),
            "Token transfer failed"
        );
    }
}
