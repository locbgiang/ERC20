// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployOurToken} from "../script/DeployOurToken.s.sol";
import {OurToken} from "../src/OurToken.sol";

contract OurTokenTest is Test {
    OurToken public ourToken;
    DeployOurToken public deployer;

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");
    address charlie = makeAddr("charlie");
    uint256 public constant STARTING_BALANCE = 100 ether;

    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();

        vm.prank(msg.sender);
        ourToken.transfer(bob, STARTING_BALANCE);
    }

    function testBobBalance() public view {
        assertEq(STARTING_BALANCE, ourToken.balanceOf(bob));
    }

    function testAllowances() public {
        uint256 initialAllowance = 1000;

        // Bob approves Alice to spend tokens on her behalf
        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);

        uint256 transferAmount = 500;

        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmount);

        assertEq(ourToken.balanceOf(alice), transferAmount);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
    }

    function testAllowanceReductionAfterTransfer() public {
        uint256 initialAllowance = 1000;

        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);

        uint256 transferAmmount = 400;
        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmmount);

        assertEq(ourToken.allowance(bob, alice), initialAllowance - transferAmmount);
    }

    function testCannotExceedAllowance() public {
        uint256 initialAllowance = 1000;

        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);

        uint256 transferAmmount = 1100;
        vm.prank(alice);
        vm.expectRevert();
        ourToken.transferFrom(bob, alice, transferAmmount);
    }

    function testTransfers() public {
        uint256 transferAmmount = 50 ether;

        vm.prank(bob);
        ourToken.transfer(alice, transferAmmount);

        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmmount);
        assertEq(ourToken.balanceOf(alice), transferAmmount);
    }

    function testCannotTransferMoreThanBalance() public {
        uint256 transferAmmount = STARTING_BALANCE + 1;

        vm.prank(bob);
        vm.expectRevert();
        ourToken.transfer(alice, transferAmmount);
    }

    function testTotalSupplyUnchangedAfterTransfer() public {
        uint256 initialSupply = ourToken.totalSupply();

        vm.prank(bob);
        ourToken.transfer(alice, 50 ether);

        vm.prank(alice);
        ourToken.transfer(charlie, 30 ether);

        assertEq(ourToken.totalSupply(), initialSupply);
    }
}
