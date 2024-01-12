// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Crowdfunding is ReentrancyGuard {
    address public owner;
    IERC20 public acceptedToken =
        IERC20(0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846);
    uint256 public fundTarget = 10 ether;
    uint256 public startTime = 1705070688;
    uint256 public endTime = 1705090688;

    mapping(address => uint256) public contributions;

    event Contribution(address indexed contributor, uint256 amount);
    event RefundClaimed(address indexed contributor, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier isValidToken(IERC20 _token) {
        require(_token == acceptedToken, "Invalid token");
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
        require(amount > 0, "Invalid contribution amount");

        uint256 remainingTarget = fundTarget - getTotalContributions();
        uint256 contributionAmount = amount;

        if (amount > remainingTarget) {
            contributionAmount = remainingTarget;
        }

        require(
            acceptedToken.transferFrom(
                msg.sender,
                address(this),
                contributionAmount
            ),
            "Token transfer failed"
        );

        contributions[msg.sender] += contributionAmount;

        emit Contribution(msg.sender, contributionAmount);

        // Refund the excess amount
        uint256 excessAmount = amount - contributionAmount;
        if (excessAmount > 0) {
            require(
                acceptedToken.transfer(msg.sender, excessAmount),
                "Token transfer failed"
            );
        }
    }

    function getTotalContributions() public view returns (uint256) {
        return acceptedToken.balanceOf(address(this));
    }

    function claimRefund() external isValidPhase {
        require(
            block.timestamp > endTime && getTotalContributions() < fundTarget,
            "Cannot claim refund now"
        );

        uint256 refundAmount = contributions[msg.sender];
        require(refundAmount > 0, "No refund available");

        // Ensure that the requested refund amount does not exceed the user's contribution
        require(
            refundAmount <= contributions[msg.sender],
            "Invalid refund amount"
        );

        // Transfer Tokens to User
        require(
            acceptedToken.transfer(msg.sender, refundAmount),
            "Token transfer failed"
        );

        // Update User's Contribution to Zero after a successful transfer
        contributions[msg.sender] = 0;
    }

    function withdrawFunds() external onlyOwner isValidPhase nonReentrant {
        require(
            block.timestamp > endTime && getTotalContributions() >= fundTarget,
            "Cannot withdraw funds now"
        );

        uint256 balance = getTotalContributions();
        require(
            acceptedToken.transfer(owner, balance),
            "Token transfer failed"
        );
    }
}
