// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "../src/Staking.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {IStaking} from "../src/IStaking.sol";
import {CustomERC721} from "../src/CustomERC721.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {console} from "forge-std/console.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract StakingTest is Test {
    CustomERC721 private lnft;
    Staking private staking;
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    address public exchangeApp = makeAddr("exchange");
    uint256 public fees = 0.01 ether;
    uint256 public rewardRate = 1;
    uint256 public tokenCap = 4;

    function setUp() public {
        lnft = new CustomERC721("Custom NFT", "NFT", tokenCap, "ipfs://nfthash/");
        staking = new Staking(address(lnft), rewardRate, fees);
    }

    function test_ImReady() public pure {
        assert(true);
    }

    // TDD Challenges
    // Step 1: Constructor Tests
    // Step 2: lock Function Tests
    // Step 3: Additional Tests for Acceptance Criteria and Edge Cases
    // Step 4: Additional Security Measures Tests
    // Step 5: Unstake Functionality

    // ======================
    // Step 1: Constructor Tests
    //      What parameters needs the constructor according to the specifications documents?
    //      What need are the `sannity` checks that I must consider?

    // Test 1.1: Constructor Parameters
    // Happy Path
    function test_ConstructorHappyPath() public view {
        // Successful deployment with both parameters
        assert(address(staking) != address(0));
    }

    // Test 1.2: Sanity Checks - Zero Address
    // Assertion: Verify the constructor reverts with a zero address for 0001-nft-start-staking.md.
    function test_Constructor_ZeroAddressSanity() public {
        // Expect Revert "NFTAddressCannotBeZero"
        vm.expectRevert(IStaking.MissingNftAddress.selector);
        new Staking(address(0), tokenCap, fees);
    }

    // Test 1.3: Sanity Checks - Invalid Reward Rate
    // Assertion: Verify the constructor reverts with an invalid (e.g., negative) rewardRate.
    function test_Constructor_InvalidRewardRateSanity() public {
        // Expect Revert "InvalidRewardRate"
        vm.expectRevert(IStaking.InvalidRewardRate.selector);
        new Staking(address(0x123456), 0, fees);
    }

    // ======================
    // Step 2: lock Function Tests
    //      What parameters needs the `stake` function according to the specifications documents.
    //      What need are the `sannity` checks that I must consider?
    //      How will I calculate the rewards earning?

    // Test 2.1: Function Parameters
    // Assertion: Verify lock requires tokenId as a parameter.
    // Test 2.2: Token Ownership
    // Assertion: Verify only the token owner can start staking.
    function test_lock_TokenOwnership() public {
        // CustomERC721 mint an NFT tokenId == 0 and trnasfer to user1
        lnft.safeMint(user1);
        assertEq(lnft.balanceOf(user1), 1);
        // Ensure user1 balance can pay fees
        deal(user1, fees);

        // user1 grants to staking contract to transfer
        vm.prank(user1);
        lnft.approve(address(staking), 0);
        assert(lnft.getApproved(0) == address(staking));

        // Simulate non-owner trying to stake
        // Expect Revert NotYourNFTToken
        vm.prank(user2);
        deal(user2, fees);
        vm.expectRevert(IStaking.NotYourNFTToken.selector);
        staking.lock{value: fees}(0, IStaking.Period.ONE_DAY);
    }

    // Test 2.3: Fee Payment
    // Assertion: Verify sufficient funds are required for the transaction.
    function test_lock_FeePayment() public {
        // CustomERC721 mint an NFT tokenId == 0 and trnasfer to user1
        lnft.safeMint(user1);
        assertEq(lnft.balanceOf(user1), 1);
        // Ensure user1 balance can pay fees
        deal(user1, fees);

        // user1 grants to staking contract to transfer
        vm.prank(user1);
        lnft.approve(address(staking), 0);
        assert(lnft.getApproved(0) == address(staking));

        // Simulate insufficient funds
        // Expect Revert InsufficientFundsSent
        vm.prank(user1);
        vm.expectRevert(IStaking.InsufficientFundsSent.selector);
        staking.lock(0, IStaking.Period.ONE_DAY);
    }

    // Test 2.4: Successful Staking
    // Assertion: Verify staking is successfully initiated.
    function test_lock_Success() public {
        // CustomERC721 mint an NFT tokenId == 0 and trnasfer to user1
        lnft.safeMint(user1);
        assertEq(lnft.balanceOf(user1), 1);
        // Ensure user1 balance can pay fees
        deal(user1, fees);

        // user1 grants to staking contract to transfer
        vm.prank(user1);
        lnft.approve(address(staking), 0);
        assert(lnft.getApproved(0) == address(staking));

        // stake with sufficient funds and correct owner
        vm.prank(user1);
        staking.lock{value: fees}(0, IStaking.Period.ONE_DAY);

        // Assert staking initiated correctly
        (uint256 startHeight, ) = staking.users(user1, 0);
        assert(startHeight == block.number);
    }

    // ======================
    // Step 3: Additional Tests for Acceptance Criteria and Edge Cases

    // Test 3.1: NFT Not Found
    // Assertion: Verify the contract reverts when attempting to stake a non-existent NFT.
    function test_NFTNotFound() public {
        // CustomERC721 mint an NFT tokenId == 0 and trnasfer to user1
        lnft.safeMint(user1);
        assertEq(lnft.balanceOf(user1), 1);
        // Ensure user1 balance can pay fees
        deal(user1, fees);

        // user1 grants to staking contract to transfer
        vm.prank(user1);
        lnft.approve(address(staking), 0);
        assert(lnft.getApproved(0) == address(staking));

        // Attempt to stake non-existent NFT
        // Expect Revert NFTNotFound
        // with enough fee ether to pay a draw()
        vm.prank(user1);
        vm.expectRevert();
        staking.lock{value: fees}(99999, IStaking.Period.ONE_DAY);
    }

    // Test 3.4: Edge Case - Staking Already Started
    // Assertion: Verify the contract reverts when attempting to restart staking for an already staking NFT.
    // Preconditions:
    //   - An NFT with already started staking is used for testing.
    // Verify the contract reverts with the expected error message ("StakingAlreadyStarted").
    function test_StakingAlreadyStarted() public {
        // CustomERC721 mint an NFT tokenId == 0 and trnasfer to user1
        lnft.safeMint(user1);
        assertEq(lnft.balanceOf(user1), 1);
        // Ensure user1 balance can pay fees
        deal(user1, 2 * fees);

        // user1 grants to staking contract to transfer
        vm.prank(user1);
        lnft.approve(address(staking), 0);
        assert(lnft.getApproved(0) == address(staking));

        // Stake NFT 1
        vm.prank(user1);
        staking.lock{value: fees}(0, IStaking.Period.ONE_DAY);

        // Assert staking initiated correctly
        (uint256 startHeight, uint256 endHeight) = staking.users(user1, 0);
        uint256 expectedEnd = vm.getBlockNumber() +
            staking.lockHeights(IStaking.Period.ONE_DAY);
        uint256 expectedReward = (endHeight - startHeight) *
            staking.rewardRate();

        assert(staking.rewards(user1) == expectedReward);
        assert(startHeight == block.number);
        assert(endHeight == expectedEnd);

        // Attempt to restart staking for the same NFT
        // Expect Revert StakingAlreadyStarted
        vm.prank(user1);
        vm.expectRevert(IStaking.AlreadyLocked.selector);
        staking.lock{value: fees}(0, IStaking.Period.ONE_DAY);
    }
    // ======================
    // Step 4: Additional Security Measures Tests

    // 1. Reentrancy Protection
    // Assertion: Verify the contract is not vulnerable to reentrancy attacks.
    // Consider using openzeppeling ReentrancyGuard

    // 2. Access Control
    // Assertion: Verify only the admin can perform sensitive operations (e.g., updating rewardRate).

    // 3. Denial of Service (DoS) Protection
    // Assertion: Verify the contract has measures against DoS attacks via gas limit.
    // Ex: on contract function lock -> require(gasleft() >= 200000, "GasLimitExceeded")

    // 4. Emergency Stop (Circuit Breaker)
    // Assertion: Verify the contract can be paused in case of an emergency.
    // Consider using OpenZeppelin's Pausable

    // ======================
    // Step 5: Unstake Functionality
    //  - What parameters needs the `unstake` function according to the specifications documents.
    //  - What need are the `sannity` checks that I must consider?
    //  - How do I calculate the `rewards` earned?

    // Test 3.5: Unstake - Successful Unstaking
    // Assertion: Verify unstaking is successfully initiated for an NFT that is currently staking.
    // Preconditions:
    //  - An NFT with ongoing staking is used for testing.
    function test_Unstake_Success() public {
        // CustomERC721 mint an NFT tokenId == 0 and trnasfer to user1
        lnft.safeMint(user1);
        assertEq(lnft.balanceOf(user1), 1);
        // Ensure user1 balance can pay fees
        deal(user1, 2 * fees);

        // user1 grants to staking contract to transfer
        vm.prank(user1);
        lnft.approve(address(staking), 0);
        assert(lnft.getApproved(0) == address(staking));

        // Given an Staking initialized contract with 1 staking
        vm.prank(user1);
        staking.lock{value: fees}(0, IStaking.Period.ONE_DAY);

        // Assert staking initiated correctly
        (uint256 startHeight, uint256 endHeight) = staking.users(user1, 0);
        uint256 expectedEnd = vm.getBlockNumber() +
            staking.lockHeights(IStaking.Period.ONE_DAY);
        uint256 expectedReward = staking.lockHeights(IStaking.Period.ONE_DAY) *
            staking.rewardRate();

        assert(staking.rewards(user1) == expectedReward);
        assert(startHeight == block.number);
        assert(endHeight == expectedEnd);

        // That the new onwer is the Staking contract
        assert(lnft.ownerOf(0) == address(staking));
        assert(lnft.balanceOf(user1) == 0);

        // jump to future to the unlock time + 1
        vm.roll(endHeight + 1);

        // Then assert unstakingunlock is successful
        vm.prank(user1);
        staking.unlock{value: fees}(0);

        (startHeight, endHeight) = staking.users(user1, 0);
        assert(staking.rewards(user1) == expectedReward);
        assert(startHeight == 0);
        // That the new onwer is the user1
        assert(lnft.ownerOf(0) == address(user1));
        assert(lnft.balanceOf(user1) == 1);
    }

    // Test 3.7: Unstake - Insufficient Funds for Fees
    // Assertion: Verify the contract reverts when attempting to unstake without sufficient funds for fees.
    // Preconditions:
    //  - An NFT with ongoing staking and insufficient user balance for fees is used.
    // Expect Revert "InsufficientFundsSent".
    function test_Unstake_InsufficientFunds() public {
        // And a TokenId1
        lnft.safeMint(user1);
        assertEq(lnft.balanceOf(user1), 1);
        deal(user1, 3 * fees);

        // user1 grants to staking contract to transfer
        vm.prank(user1);
        lnft.approve(address(staking), 0);
        assert(lnft.getApproved(0) == address(staking));

        // Given an Staking initialized contract with 1 staking
        vm.prank(user1);
        staking.lock{value: fees}(0, IStaking.Period.ONE_DAY);

        uint256 balance = lnft.balanceOf(user1);
        assert(balance == 0);
        // And user1 having insufficient balance for fees

        // When attempting to unstake 1 with insufficient funds
        (, uint256 endHeight) = staking.users(user1, 0);
        vm.roll(endHeight + 1);
        // Expect revert InsufficientFundsSent
        vm.prank(user1);
        vm.expectRevert(IStaking.InsufficientFundsSent.selector);
        staking.unlock(0);

        vm.prank(user1);
        staking.unlock{value: fees}(0);

        balance = lnft.balanceOf(user1);
        assert(balance == 1);
    }

    // Test 3.9: Unstake - Reward Calculation Correctness
    function test_RewardCalculation() public {
        // Given
        // - `1` is staking with a known staking period and height
        // - Expected reward amount for the staking period
        // And a TokenId1
        lnft.safeMint(user1);
        deal(user1, fees);

        // user1 grants to staking contract to transfer
        vm.prank(user1);
        lnft.approve(address(staking), 0);

        // When
        // - Unstake `1`

        // Then
        // - Verify the reward amount transferred matches the expected calculation

        // Stake NFT 1
        vm.prank(user1);
        staking.lock{value: fees}(0, IStaking.Period.ONE_DAY);

        (uint256 startHeight, uint256 endHeight) = staking.users(user1, 0);
        // Check reward amount transferred
        uint256 expectedReward = (endHeight - startHeight) *
            staking.rewardRate();

        assert(staking.rewards(user1) == expectedReward);
    }

    // ======================
    // Step 6: Whitelisting Tests

    // Test 4.1: Add to Whitelist - Success
    // Assertion: Verify an admin can successfully add an address to the whitelist.
    function test_AddToWhitelist_Success() public {
        // Arrange
        address appContract = address(
            0x1234567890123456789012345678901234567890
        );

        // Act
        staking.addToWhitelist(appContract);

        // Assert
        assert(staking.isWhitelisted(appContract) == true);
    }

    // Test 4.2: Add to Whitelist - Non-Admin Revert
    // Assertion: Verify a non-admin cannot add an address to the whitelist.
    function test_AddToWhitelist_NonAdminRevert() public {
        // Arrange
        address appContract = address(
            0x9876543210987654321098765432109876543210
        );

        // Act & Assert
        vm.prank(user1); // Assume 'user1' is not an admin
        vm.expectRevert(); // Ownable.OwnableUnauthorizedAccount.selector
        staking.addToWhitelist(appContract);
    }

    // Test 4.3: Remove from Whitelist - Success
    // Assertion: Verify an admin can successfully remove an address from the whitelist.
    function test_RemoveFromWhitelist_Success() public {
        // Arrange
        address appContract = address(
            0x1234567890123456789012345678901234567890
        );
        staking.addToWhitelist(appContract); // Precondition: Ensure the user is whitelisted
        assert(staking.isWhitelisted(appContract) == true);

        // Act
        staking.removeFromWhitelist(appContract);

        // Assert
        assert(staking.isWhitelisted(appContract) == false);
    }

    // Test 4.4: Remove from Whitelist - Non-Admin Revert
    // Assertion: Verify a non-admin cannot remove an address from the whitelist.
    function test_RemoveFromWhitelist_NonAdminRevert() public {
        // Arrange
        address appContract = address(
            0x1234567890123456789012345678901234567890
        );
        staking.addToWhitelist(appContract); // Precondition: Ensure the user is whitelisted
        assert(staking.isWhitelisted(appContract) == true);
        vm.prank(user1); // Assume 'user1' is not an admin

        // Act & Assert
        vm.expectRevert(); // Ownable.OwnableUnauthorizedAccount.selector
        staking.removeFromWhitelist(appContract);
    }

    // Test 4.5: Whitelist Status - Edge Case (Zero Address)
    // Assertion: Verify the contract behaves as expected when querying the zero address.
    function test_WhitelistStatus_ZeroAddress() public view {
        // Act & Assert
        assert(staking.isWhitelisted(address(0)) == false);
    }

    // ======================
    // Step 7: Additional Staking Functionality Tests

    // Test 5.1: Stake - Multiple NFTs by Same User
    // Assertion: Verify a user can stake multiple NFTs successfully.
    function test_MultipleStakesSameUser() public {
        // Arrange
        lnft.safeMint(user1);
        lnft.safeMint(user1);
        deal(user1, 4 * fees); // For two stakes and potential unstakes

        // Act
        vm.prank(user1);
        lnft.approve(address(staking), 0);
        vm.prank(user1);
        lnft.approve(address(staking), 1);
        vm.prank(user1);
        staking.lock{value: fees}(0, IStaking.Period.ONE_DAY);
        vm.prank(user1);
        staking.lock{value: fees}(1, IStaking.Period.ONE_DAY);

        // Assert
        assert(lnft.ownerOf(0) == address(staking));
        assert(lnft.ownerOf(1) == address(staking));
        assert(lnft.balanceOf(user1) == 0);
    }

    // Test 5.2: Stake - Different Periods
    // Assertion: Verify staking with different periods updates correctly.
    function test_StakeDifferentPeriods() public {
        // Arrange
        lnft.safeMint(user1);
        deal(user1, 2 * fees);

        // Act
        vm.prank(user1);
        lnft.approve(address(staking), 0);
        vm.prank(user1);
        staking.lock{value: fees}(0, IStaking.Period.ONE_DAY);

        // Stake another NFT with a different period
        lnft.safeMint(user1);
        vm.prank(user1);
        lnft.approve(address(staking), 1);
        vm.prank(user1);
        staking.lock{value: fees}(1, IStaking.Period.SEVEN_DAYS);

        // Assert
        (, uint256 endHeightDay) = staking.users(user1, 0);
        (, uint256 endHeightWeek) = staking.users(user1, 1);
        assert(endHeightWeek > endHeightDay);
    }

    // Test 5.6: View Functions - Correctness
    // Assertion: Verify view/pure functions return correct values.
    function test_ViewFunctions() public {
        // Arrange & Act & Assert (Example with `users` function)
        lnft.safeMint(user1);
        deal(user1, fees);
        vm.prank(user1);
        lnft.approve(address(staking), 0);
        vm.prank(user1);
        staking.lock{value: fees}(0, IStaking.Period.ONE_DAY);

        (uint256 startHeight, uint256 endHeight) = staking.users(user1, 0);
        assert(startHeight == block.number);
        assert(
            endHeight ==
                block.number + staking.lockHeights(IStaking.Period.ONE_DAY)
        );
    }

    // Test for NFTPeriodNotReady in unlock function
    function test_Unlock_NFTPeriodNotReady() public {
        // Arrange & Act & Assert (Example with `users` function)
        lnft.safeMint(user1);
        deal(user1, fees);
        vm.prank(user1);
        lnft.approve(address(staking), 0);
        vm.prank(user1);
        staking.lock{value: fees}(0, IStaking.Period.ONE_DAY);

        (uint256 startHeight, uint256 endHeight) = staking.users(user1, 0);
        assert(startHeight == block.number);
        assert(
            endHeight ==
                block.number + staking.lockHeights(IStaking.Period.ONE_DAY)
        );
        vm.roll(endHeight); // Move block number but not past the endHeight

        // Act & Assert
        vm.expectRevert(IStaking.NFTPeriodNotReady.selector);
        vm.prank(user1);
        staking.unlock(0);
    }

    // Test for NFTNotLocked in unlock function (Already covered in previous response, duplicated for completeness)
    function test_Unlock_NFTNotLocked() public {
        // Act & Assert
        vm.prank(user1);
        vm.expectRevert(IStaking.NFTNotLocked.selector);
        staking.unlock(0);
    }

    // Test for NotInWhitelist in consumeRewards function
    function test_ConsumeRewards_NotInWhitelist() public {
        // CustomERC721 mint an NFT tokenId == 0 and trnasfer to user1
        lnft.safeMint(user1);
        assertEq(lnft.balanceOf(user1), 1);
        // Ensure user1 balance can pay fees
        deal(user1, 2 * fees);

        // user1 grants to staking contract to transfer
        vm.prank(user1);
        lnft.approve(address(staking), 0);
        assert(lnft.getApproved(0) == address(staking));

        // Given an Staking initialized contract with 1 staking
        vm.prank(user1);
        staking.lock{value: fees}(0, IStaking.Period.ONE_DAY);

        // Assert staking initiated correctly
        (uint256 startHeight, uint256 endHeight) = staking.users(user1, 0);
        uint256 expectedEnd = vm.getBlockNumber() +
            staking.lockHeights(IStaking.Period.ONE_DAY);
        uint256 expectedReward = staking.lockHeights(IStaking.Period.ONE_DAY) *
            staking.rewardRate();

        assert(staking.rewards(user1) == expectedReward);
        assert(startHeight == block.number);
        assert(endHeight == expectedEnd);

        // That the new onwer is the Staking contract
        assert(lnft.ownerOf(0) == address(staking));
        assert(lnft.balanceOf(user1) == 0);

        // jump to future to the unlock time + 1
        vm.roll(endHeight + 1);

        // Then assert unstakingunlock is successful
        vm.prank(user1);
        staking.unlock{value: fees}(0);

        (startHeight, endHeight) = staking.users(user1, 0);
        assert(staking.rewards(user1) == expectedReward);
        assert(startHeight == 0);
        // That the new onwer is the user1
        assert(lnft.ownerOf(0) == address(user1));
        assert(lnft.balanceOf(user1) == 1);

        // Act & Assert
        // Ensure staking.addToWhitelist() prerequisite not complian.
        vm.expectRevert(IStaking.NotInWhitelist.selector);
        staking.consumeRewards{value: fees}(user1, 0);
    }

    // Test for InsufficientRewardsPoints in consumeRewards function
    function test_ConsumeRewards_InsufficientRewardsPoints() public {
        staking.addToWhitelist(exchangeApp); // Precondition: Ensure the user is whitelisted
        deal(exchangeApp, fees);

        vm.prank(user2);
        uint256 rewardsBalance = staking.rewards(user2);
        assert(rewardsBalance == 0);

        // Act & Assert
        vm.prank(exchangeApp);
        vm.expectRevert(IStaking.InsufficientRewardsPoints.selector);
        staking.consumeRewards{value: fees}(user2, 1);
    }
}
