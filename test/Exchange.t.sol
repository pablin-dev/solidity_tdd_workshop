// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Exchange} from "../src/Exchange.sol";
import {CustomERC20} from "../src/CustomERC20.sol";
import {CustomERC721} from "../src/CustomERC721.sol";
import {Staking} from "../src/Staking.sol";
import {IStaking} from "../src/IStaking.sol";
import {IExchange} from "../src/IExchange.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {console} from "forge-std/console.sol";

contract ExchangeTest is Test {
    // **Contract Instances**
    CustomERC20 private token; ///< Instance of CustomERC20 (ERC20 Token)
    CustomERC721 private lnft; ///< Instance of CustomERC721 (ERC721 NFT)
    Staking private staking; ///< Instance of Staking contract
    Exchange private exchange; ///< Instance of Exchange contract under test

    // **Test Addresses**
    address public user1 = makeAddr("user1"); ///< First test user address
    address public user2 = makeAddr("user2"); ///< Second test user address (currently unused)

    // **Constants**
    uint256 public fees = 0.01 ether; ///< Fee amount set for Staking and Exchange operations

    uint256 public rewardRate = 1;
    uint256 public tokenCap = 4;

    /**
     * @dev Setup function called before each test
     * @notice Initializes contract instances and test variables
     */
    function setUp() public {
        // **Given**: Test environment setup with users and contracts

        // **When**: Contracts are deployed for testing
        token = new CustomERC20(); ///< Deploy new CustomERC20 (ERC20) token contract
        lnft = new CustomERC721("Custom NFT", "NFT", tokenCap, "ipfs://nfthash/"); ///< Deploy new CustomERC721 (ERC721) NFT contract
        staking = new Staking(address(lnft), rewardRate, fees); ///< Deploy new Staking contract with NFT, reward rate, and fees
        exchange = new Exchange(address(staking), address(token), 2 * fees); ///< Deploy new Exchange contract with Staking, Token, and fees

        // **Then**: Setup is complete, ready for individual test executions
    }

    /**
     * @dev Sanity check test to ensure test suite is operational
     * @notice Always passes if the test suite is correctly set up
     */
    function test_ImReady() public pure {
        // **Given**: Test suite is set up
        // **When**: Sanity check test is executed
        // **Then**: Test passes if the setup is correct
        assert(true); ///< Always true, ensuring test suite operability
    }

    // ... (Previous code remains the same until the new tests)

    // **Happy Path**
    /**
     * @dev Test successful reward exchange
     * @notice Verifies user can exchange earned points for tokens
     */
    function test_exchangeRewards_Success() public {
        // **Given**:
        // 1. User1 has a minted NFT
        // 2. NFT is staked to earn points
        // 3. User has enough points and contract has tokens for exchange
        // 4. User1 has ether to cover fees
        uint256 tokens_to_mint = staking.lockHeights(IStaking.Period.ONE_DAY);
        token.mint(address(exchange), tokens_to_mint); // Ensure contract has tokens
        uint256 balance = token.balanceOf(address(exchange));
        assert(balance == tokens_to_mint);
        staking.addToWhitelist(address(exchange)); // Ensure that the exchage contract is on whitelist

        // Assuming the NFT contract is deployed and token owner is user1
        // And a TokenId1
        lnft.safeMint(user1); // tokenId 0
        deal(user1, 3 * fees);

        // user1 grants to staking contract to transfer
        vm.prank(user1);
        lnft.approve(address(staking), 0);

        vm.prank(user1);
        staking.lock{value: fees}(0, IStaking.Period.ONE_DAY); // Assuming this earns points

        assert(
            staking.rewards(user1) ==
                staking.lockHeights(IStaking.Period.ONE_DAY)
        );

        // **When**: User exchanges rewards
        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit IExchange.ExchangeRewardsSuccess(); // Emit for simulation
        exchange.exchangeRewards{value: 2 * fees}(user1, 1);

        // **Then**:
        // 1. User receives tokens
        // 2. User's points decrease
        // 3. Exchange success event is emitted
        assertEq(token.balanceOf(user1), 1);
        assertEq(
            staking.rewards(user1),
            staking.lockHeights(IStaking.Period.ONE_DAY) - 1
        ); // Points should decrease
    }

    // **Error Paths**

    /**
     * @dev Test exchange with insufficient funds sent
     * @notice Verifies reversion when user doesn't have enough ether for fees
     */
    function test_exchangeRewards_InsufficientFundsSent() public {
        // **Given**: User1 has ether to cover fees
        vm.deal(user1, fees);

        // **When**: User attempts to exchange rewards
        vm.expectRevert(IExchange.InsufficientFundsSent.selector);
        vm.prank(user1);
        exchange.exchangeRewards(user1, 1);

        // **Then**: Transaction reverts with InsufficientFundsSent error
    }

    /**
     * @dev Test exchange with insufficient points to exchange
     * @notice Verifies reversion when user doesn't have enough points
     */
    function test_exchangeRewards_InsufficientPointsToExchange() public {
        deal(user1, 3 * fees);
        // **Given**: User1 doesn't have enough points for exchange
        assertLt(staking.rewards(user1), 1);

        // **When**: User attempts to exchange rewards with sufficient fees
        vm.prank(user1);
        vm.expectRevert(IExchange.InsufficientPointsToExchange.selector);
        exchange.exchangeRewards{value: 2 * fees}(user1, 1);

        // **Then**: Transaction reverts with InsufficientPointsToExchange error
    }

    /**
     * @dev Test exchange with insufficient tokens to exchange
     * @notice Verifies reversion when the contract doesn't have enough tokens
     */
    function test_exchangeRewards_InsufficientTokensToExchange() public {
        // **Given**: Contract doesn't have enough tokens for exchange
        assertEq(token.balanceOf(address(exchange)), 0);
        staking.addToWhitelist(address(exchange)); // Ensure that the exchage contract is on whitelist

        // Assuming the NFT contract is deployed and token owner is user1
        // And a TokenId1
        lnft.safeMint(user1); // tokenId 0
        deal(user1, 3 * fees);

        // user1 grants to staking contract to transfer
        vm.prank(user1);
        lnft.approve(address(staking), 0);

        vm.prank(user1);
        staking.lock{value: fees}(0, IStaking.Period.ONE_DAY); // Assuming this earns points

        assert(
            staking.rewards(user1) ==
                staking.lockHeights(IStaking.Period.ONE_DAY)
        );

        // **When**: User exchanges rewards
        vm.prank(user1);
        vm.expectRevert(IExchange.InsufficientTokensToExchange.selector);
        exchange.exchangeRewards{value: 2 * fees}(user1, 1);
        // **Then**: Transaction reverts with InsufficientTokensToExchange error
    }

    // **Edge Cases**

    /**
     * @dev Test exchanging zero points
     * @notice Verifies behavior when user attempts to exchange 0 points
     * @notice Assuming it either reverts with InsufficientPoints or a specific handler for 0 points
     */
    function test_exchangeRewards_ZeroPoints() public {
        // **Given**: User1 attempts to exchange 0 points
        vm.prank(user1);
        vm.deal(user1, 3 * fees); // Cover fees

        // **When**: User attempts to exchange 0 points
        vm.expectRevert(); // Assuming either InsufficientPoints or a specific handler for 0 points
        exchange.exchangeRewards{value: 2 * fees}(user1, 0);

        // **Then**: Transaction reverts with an appropriate error
    }

    /**
     * @dev Test exchange for a non-existing user
     * @notice Verifies behavior for a user without any stakes or points
     * @notice Assuming it reverts with InsufficientPointsToExchange or another relevant error
     */
    function test_exchangeRewards_NonExistingUser() public {
        // **Given**: Non-existing user with no stakes or points
        address nonExistingUser = makeAddr("nonExisting");

        // **When**: Non-existing user attempts to exchange rewards with sufficient fees
        vm.prank(nonExistingUser);
        vm.deal(nonExistingUser, 3 * fees); // Cover fees
        vm.expectRevert(IExchange.InsufficientPointsToExchange.selector); // Or another relevant error
        exchange.exchangeRewards{value: 2 * fees}(nonExistingUser, 1);

        // **Then**: Transaction reverts with an appropriate error
    }

    /**
     * @dev Test exchanging rewards with a non-whitelisted contract
     * @notice Verifies reversion when the exchange contract isn't whitelisted for staking rewards
     */
    function test_exchangeRewards_NonWhitelistedContract() public {
        // **Given**: Exchange contract is not whitelisted for staking
        assert(!staking.isWhitelisted(address(exchange)));

        // Assuming setup for user1 with rewards (reuse setup from test_exchangeRewards_Success)
        uint256 tokens_to_mint = staking.lockHeights(IStaking.Period.ONE_DAY);
        token.mint(address(exchange), tokens_to_mint);
        lnft.safeMint(user1); // tokenId 0
        deal(user1, 3 * fees);
        vm.prank(user1);
        lnft.approve(address(staking), 0);
        vm.prank(user1);
        staking.lock{value: fees}(0, IStaking.Period.ONE_DAY);
        assert(
            staking.rewards(user1) ==
                staking.lockHeights(IStaking.Period.ONE_DAY)
        );

        // **Snapshot State Before Attempting Exchange**
        uint256 snapshotUserRewards = staking.rewards(user1);
        uint256 snapshotExchangeBalance = token.balanceOf(address(exchange));
        uint256 snapshotUserBalance = token.balanceOf(user1);
        uint256 snapshotUserEthBalance = user1.balance;

        // **When**: Attempt to exchange rewards without being whitelisted
        assert(!staking.isWhitelisted(address(exchange)));
        vm.prank(user1);
        vm.expectRevert(IStaking.NotInWhitelist.selector);
        exchange.exchangeRewards{value: 2 * fees}(user1, 1);

        // **Then**: Transaction reverts with ContractNotWhitelisted error
        // 1. **Reversion Occurred**: Already verified by `vm.expectRevert`.
        // 2. **State Remains Unchanged**
        assertEq(
            staking.rewards(user1),
            snapshotUserRewards,
            "User rewards changed unexpectedly"
        );
        assertEq(
            token.balanceOf(address(exchange)),
            snapshotExchangeBalance,
            "Exchange token balance changed"
        );
        assertEq(
            token.balanceOf(user1),
            snapshotUserBalance,
            "User token balance changed"
        );
        assertEq(
            user1.balance,
            snapshotUserEthBalance,
            "User ETH balance changed unexpectedly (fees deducted)"
        );
    }

    /**
     * @dev Test exchanging rewards with an invalid token ID
     * @notice Verifies reversion for non-existent or invalid token IDs
     */
    function test_exchangeRewards_InvalidPointsCount() public {
        // **Given**: Exchange contract is not whitelisted for staking
        assert(!staking.isWhitelisted(address(exchange)));

        // Assuming setup for user1 with rewards (reuse setup from test_exchangeRewards_Success)
        uint256 tokens_to_mint = staking.lockHeights(IStaking.Period.ONE_DAY);
        token.mint(address(exchange), tokens_to_mint);
        lnft.safeMint(user1); // tokenId 0
        deal(user1, 3 * fees);
        vm.prank(user1);
        lnft.approve(address(staking), 0);
        vm.prank(user1);
        staking.lock{value: fees}(0, IStaking.Period.ONE_DAY);
        assert(
            staking.rewards(user1) ==
                staking.lockHeights(IStaking.Period.ONE_DAY)
        );

        // **Snapshot State Before Attempting Exchange**
        uint256 snapshotUserRewards = staking.rewards(user1);
        uint256 snapshotExchangeBalance = token.balanceOf(address(exchange));
        uint256 snapshotUserBalance = token.balanceOf(user1);
        uint256 snapshotUserEthBalance = user1.balance;

        // whitelist exchange
        staking.addToWhitelist(address(exchange));
        assert(staking.isWhitelisted(address(exchange)));

        // **When**: Attempt to exchange rewards with an invalid token ID
        vm.prank(user1);
        vm.expectRevert(IExchange.InsufficientPointsToExchange.selector);
        exchange.exchangeRewards{value: 2 * fees}(user1, tokens_to_mint + 1);

        // **Then**: Transaction reverts with InsufficientPointsToExchange error
        // 1. **Reversion Occurred**: Already verified by `vm.expectRevert`.
        // 2. **State Remains Unchanged**
        assertEq(
            staking.rewards(user1),
            snapshotUserRewards,
            "User rewards changed unexpectedly"
        );
        assertEq(
            token.balanceOf(address(exchange)),
            snapshotExchangeBalance,
            "Exchange token balance changed"
        );
        assertEq(
            token.balanceOf(user1),
            snapshotUserBalance,
            "User token balance changed"
        );
        assertEq(
            user1.balance,
            snapshotUserEthBalance,
            "User ETH balance changed unexpectedly (fees deducted)"
        );
    }

    function test_getExchangeFees() public view {
        // **Given**: Exchange contract with predefined fees
        uint256 expectedFees = 2 * fees; // Assuming 'fees' is the variable used in setup

        // **When**: Call getExchangeFees function
        uint256 actualFees = exchange.getExchangeFees();

        // **Then**: Verify the returned fees match the expected fees
        assertEq(actualFees, expectedFees, "Exchange fees mismatch");
    }

    function test_getStakingFees() public view {
        // **Given**: Exchange contract with predefined staking fees (fetched from Staking contract)
        uint256 expectedStakingFees = staking.fees(); // Assuming 'staking' is the Staking contract instance

        // **When**: Call getStakingFees function
        uint256 actualStakingFees = exchange.getStakingFees();

        // **Then**: Verify the returned staking fees match the expected staking fees
        assertEq(
            actualStakingFees,
            expectedStakingFees,
            "Staking fees mismatch"
        );
    }

    function test_getFees_AfterConstructorUpdate() public {
        // **Given**: New fees value (different from the initial one)
        uint256 newFees = 1 ether; // Example new fees value

        // **When**: Update the Exchange contract's fees via constructor (for testing purposes only)
        // NOTE: In a real scenario, you wouldn't update the constructor's set value directly.
        //       This is for testing the effect of a different initial fees value.
        Exchange newExchange = new Exchange(address(staking), address(token), newFees);

        // **Then**: Verify the updated fees are reflected in getExchangeFees
        assertEq(
            newExchange.getExchangeFees(),
            newFees,
            "Updated exchange fees mismatch"
        );

        // **And**: Verify getStakingFees remains unchanged (still fetches from Staking contract)
        assertEq(
            newExchange.getStakingFees(),
            staking.fees(),
            "Staking fees unexpectedly changed"
        );
    }
}
