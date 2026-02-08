// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "../BeforeAfter.sol";
import {Properties} from "../Properties.sol";
// Chimera deps
import {vm} from "@chimera/Hevm.sol";

// Helpers
import {Panic} from "@recon/Panic.sol";

import "src/tokens/ERC4626.sol";

abstract contract Erc4626Targets is
    BaseTargetFunctions,
    Properties
{
    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///


    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

    function erc4626_approve(address spender, uint256 amount) public asActor {
        erc4626.approve(spender, amount);
    }

    function erc4626_deposit(uint256 assets, address receiver) public asActor {
        erc4626.deposit(assets, receiver);
    }

    function erc4626_mint(uint256 shares, address receiver) public asActor {
        erc4626.mint(shares, receiver);
    }

    function erc4626_permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public asActor {
        erc4626.permit(owner, spender, value, deadline, v, r, s);
    }

    function erc4626_redeem(uint256 shares, address receiver, address owner) public asActor {
        erc4626.redeem(shares, receiver, owner);
    }

    function erc4626_transfer(address to, uint256 amount) public asActor {
        erc4626.transfer(to, amount);
    }

    function erc4626_transferFrom(address from, address to, uint256 amount) public asActor {
        erc4626.transferFrom(from, to, amount);
    }

    function erc4626_withdraw(uint256 assets, address receiver, address owner) public asActor {
        erc4626.withdraw(assets, receiver, owner);
    }
}