// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

/**
 * @title Exchange Contract
 * @author [Your Name]
 * @notice This contract allows users to exchange rewrds for ERC20 Tokens.
 * @dev This contract assumes an ERC20 interface for Token interactions.
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IStaking} from "./IStaking.sol";
import {IExchange} from "./IExchange.sol";
import {CustomERC20} from "./CustomERC20.sol";
import {Staking} from "./Staking.sol";

contract Exchange is IExchange {
    // State Variables
    Staking public staking; // Represents the Staking contract address
    CustomERC20 public token; // Represents the ERC20 token address
    uint256 public fees; // Fees for exchanging rewards
    uint256 public staking_fees; // Fees for exchanging rewards

    // Constructor
    constructor(address _staking, address _token, uint256 _feeAmount) {
        if (_staking == address(0)) {
            revert StakeAddressCannotBeZero();
        }
        if (_token == address(0)) {
            revert TokenAddressCannotBeZero();
        }
        staking = Staking(_staking);
        token = CustomERC20(_token);
        fees = _feeAmount;
        staking_fees = staking.fees();
    }

    // Function to exchange rewards for ERC20 tokens
    function exchangeRewards(address _user, uint256 _points) public payable {
        // Check if funds sent are greater than or equal to fees
        if (msg.value < fees) {
            revert InsufficientFundsSent();
        }

        // Check user rewards balance (assuming `rewardsBalance` function exists in the Staking contract)
        IStaking stakingContract = IStaking(staking);
        uint256 userRewardsBalance = stakingContract.rewards(_user);
        if (userRewardsBalance < _points) {
            revert InsufficientPointsToExchange();
        }

        // Check ERC20 token balance (to ensure sufficient tokens for exchange)
        IERC20 tokenContract = IERC20(token);
        uint256 tokenBalance = tokenContract.balanceOf(address(this));
        if (tokenBalance < _points) {
            revert InsufficientTokensToExchange();
        }

        if (!stakingContract.isWhitelisted(address(this))) {
            revert NotInWhitelist();
        }

        // Consume rewards from the Staking contract (assuming `consumeRewards` function exists)
        stakingContract.consumeRewards{value: staking_fees}(_user, _points);

        // Transfer ERC20 tokens to the user
        tokenContract.transfer(_user, _points);

        // Emit success event
        emit ExchangeRewardsSuccess();
    }

    function getExchangeFees() external view returns (uint256) {
        return fees;
    }

    function getStakingFees() external view returns (uint256) {
        return staking_fees;
    }
}
