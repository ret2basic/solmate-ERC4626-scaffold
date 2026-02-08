// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

// Chimera deps
import {BaseSetup} from "@chimera/BaseSetup.sol";
import {vm} from "@chimera/Hevm.sol";

// Managers
import {ActorManager} from "@recon/ActorManager.sol";
import {AssetManager} from "@recon/AssetManager.sol";

// Helpers
import {Utils} from "@recon/Utils.sol";

// Your deps
import {ERC20} from "src/tokens/ERC20.sol";
import {ERC4626} from "src/tokens/ERC4626.sol";
import {MockERC4626} from "src/test/utils/mocks/MockERC4626.sol";

abstract contract Setup is BaseSetup, ActorManager, AssetManager, Utils {
    ERC4626 erc4626;
    MockERC4626 mockERC4626;
    
    /// === Setup === ///
    /// This contains all calls to be performed in the tester constructor, both for Echidna and Foundry
    function setup() internal virtual override {
        ERC20 underlying = ERC20(_newAsset(18));
        mockERC4626 = new MockERC4626(underlying, "Mock Vault", "mVLT");
        erc4626 = mockERC4626;
    }

    /// === MODIFIERS === ///
    /// Prank admin and actor
    
    modifier asAdmin {
        vm.prank(address(this));
        _;
    }

    modifier asActor {
        vm.prank(address(_getActor()));
        _;
    }
}
