// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {stdError} from "forge-std/StdError.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {CustomERC20} from "../src/CustomERC20.sol";
import {stdError} from "forge-std/Test.sol";

contract CustomERC20Test is Test {
    CustomERC20 public CustomERC20;
    address public owner;
    address public user = address(1);

    function setUp() public {
        CustomERC20 = new CustomERC20();
        owner = CustomERC20.owner();
        assertEq(owner, address(this)); // Verify owner setup
    }

    function test_Mint_AsOwner_Succeeds() public {
        uint256 amount = 100;
        CustomERC20.mint(user, amount);
        assertEq(CustomERC20.balanceOf(user), amount);
    }

    function test_Mint_NotAsOwner_Fails() public {
        uint256 amount = 100;
        vm.prank(user); // Simulate call from non-owner
        vm.expectRevert(); // Expect revert for unauthorized access
        CustomERC20.mint(user, amount);
    }

    function test_Mint_ZeroAmount_SucceedsButNoChange() public {
        uint256 initialBalance = CustomERC20.balanceOf(user);
        CustomERC20.mint(user, 0);
        assertEq(CustomERC20.balanceOf(user), initialBalance);
    }

    function test_Mint_ToZeroAddress_Fails() public {
        uint256 amount = 100;
        vm.expectRevert(); // ERC20's _mint reverts on 0x0 address
        CustomERC20.mint(address(0), amount);
    }

    // Fuzz test for minting with a wide range of amounts
    function testFuzz_Mint_Amount(uint256 amount) public {
        vm.prank(owner); // Ensure we're minting as the owner
        if (amount == 0) {
            // Edge case: Minting 0 amount should succeed but not change balance
            uint256 initialBalance = CustomERC20.balanceOf(user);
            CustomERC20.mint(user, amount);
            assertEq(CustomERC20.balanceOf(user), initialBalance);
        } else {
            // General case: Minting non-zero amount should update balance
            CustomERC20.mint(user, amount);
            assertEq(CustomERC20.balanceOf(user), amount);
        }
    }

    // Fuzz test for minting to various addresses
    function testFuzz_Mint_Address(address to) public {
        vm.prank(owner); // Ensure we're minting as the owner
        uint256 amount = 100;
        if (to == address(0)) {
            // Edge case: Minting to 0x0 address should revert
            vm.expectRevert();
            CustomERC20.mint(to, amount);
        } else if (to == owner) {
            // Edge case: Minting to the owner's address
            CustomERC20.mint(to, amount);
            assertEq(CustomERC20.balanceOf(to), amount);
        } else if (to == user) {
            // Existing test case, but included for completeness
            CustomERC20.mint(to, amount);
            assertEq(CustomERC20.balanceOf(to), amount);
        } else {
            // General case: Minting to any other non-zero, non-owner address
            CustomERC20.mint(to, amount);
            assertEq(CustomERC20.balanceOf(to), amount);
        }
    }

    // Fuzz test to ensure mint reverts when not called by the owner (complementary to test_Mint_NotAsOwner_Fails)
    function testFuzz_Mint_NotOwner(address notOwner, uint256 amount) public {
        vm.prank(notOwner); // Simulate call from a non-owner
        vm.expectRevert(); // Expect revert for unauthorized access
        CustomERC20.mint(user, amount);
    }
}
