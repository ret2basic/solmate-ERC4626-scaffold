// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Asserts} from "@chimera/Asserts.sol";
import {vm} from "@chimera/Hevm.sol";
import {BeforeAfter} from "./BeforeAfter.sol";
import {MockERC20 as ReconMockERC20} from "@recon/MockERC20.sol";
import {ERC20} from "src/tokens/ERC20.sol";

abstract contract Properties is BeforeAfter, Asserts {
	/// === EIP-4626 MUST/MUST NOT Invariants === ///
	///
	/// Invariant ID Table (EIP-4626 MUST/MUST NOT)
	///
	/// | ID         | Invariant |
	/// |------------|-----------|
	/// | ERC4626-01 | totalAssets() MUST equal the underlying asset balance of the vault |
	/// | ERC4626-02 | previewDeposit() MUST equal convertToShares() |
	/// | ERC4626-03 | previewRedeem() MUST equal convertToAssets() |
	/// | ERC4626-04 | previewMint() MUST NOT under-estimate assets vs convertToAssets() |
	/// | ERC4626-05 | previewWithdraw() MUST NOT under-estimate shares vs convertToShares() |
	/// | ERC4626-06 | maxDeposit() MUST return the maximum deposit amount |
	/// | ERC4626-07 | maxMint() MUST return the maximum mint amount |
	/// | ERC4626-08 | maxWithdraw() MUST equal convertToAssets(balanceOf(owner)) |
	/// | ERC4626-09 | maxRedeem() MUST equal balanceOf(owner) |
	/// | ERC4626-10 | asset() MUST NOT revert |
	/// | ERC4626-11 | totalAssets() MUST NOT revert |
	/// | ERC4626-12 | max{Deposit,Mint,Withdraw,Redeem}() MUST NOT revert |
	/// | ERC4626-13 | convertToShares() MUST NOT vary by caller |
	/// | ERC4626-14 | convertToAssets() MUST NOT vary by caller |
	/// | ERC4626-15 | previewDeposit() MUST NOT over-estimate actual deposit shares |
	/// | ERC4626-16 | previewMint() MUST NOT under-estimate actual mint assets |
	/// | ERC4626-17 | previewWithdraw() MUST NOT under-estimate actual withdraw shares |
	/// | ERC4626-18 | previewRedeem() MUST NOT over-estimate actual redeem assets |

	/// ERC4626-01: totalAssets MUST equal the underlying asset balance of the vault.
	function echidna_total_assets_matches_balance() public {
		ERC20 asset = ERC20(erc4626.asset());
		eq(erc4626.totalAssets(), asset.balanceOf(address(erc4626)), "TOTAL_ASSETS_MISMATCH");
	}

	/// ERC4626-02: previewDeposit MUST equal convertToShares.
	function echidna_preview_deposit_matches_convert_to_shares() public {
		if (_convertToSharesWouldRevert()) {
			return;
		}
		uint256 assets = _sampleAssets();
		eq(erc4626.previewDeposit(assets), erc4626.convertToShares(assets), "PREVIEW_DEPOSIT_MISMATCH");
	}

	/// ERC4626-03: previewRedeem MUST equal convertToAssets.
	function echidna_preview_redeem_matches_convert_to_assets() public {
		uint256 shares = _sampleShares();
		eq(erc4626.previewRedeem(shares), erc4626.convertToAssets(shares), "PREVIEW_REDEEM_MISMATCH");
	}

	/// ERC4626-04: previewMint MUST NOT under-estimate assets vs convertToAssets.
	function echidna_preview_mint_rounds_up() public {
		uint256 shares = _sampleShares();
		gte(erc4626.previewMint(shares), erc4626.convertToAssets(shares), "PREVIEW_MINT_NOT_UP");
	}

	/// ERC4626-05: previewWithdraw MUST NOT under-estimate shares vs convertToShares.
	function echidna_preview_withdraw_rounds_up() public {
		if (_convertToSharesWouldRevert()) {
			return;
		}
		uint256 assets = _sampleAssets();
		gte(erc4626.previewWithdraw(assets), erc4626.convertToShares(assets), "PREVIEW_WITHDRAW_NOT_UP");
	}

	/// ERC4626-06: maxDeposit MUST return the maximum deposit amount.
	function echidna_max_deposit_is_unlimited() public {
		address owner = _getActor();
		eq(erc4626.maxDeposit(owner), type(uint256).max, "MAX_DEPOSIT_NOT_UNLIMITED");
	}

	/// ERC4626-07: maxMint MUST return the maximum mint amount.
	function echidna_max_mint_is_unlimited() public {
		address owner = _getActor();
		eq(erc4626.maxMint(owner), type(uint256).max, "MAX_MINT_NOT_UNLIMITED");
	}

	/// ERC4626-08: maxWithdraw MUST equal convertToAssets(balanceOf(owner)).
	function echidna_max_withdraw_matches_convert_to_assets() public {
		address owner = _getActor();
		eq(erc4626.maxWithdraw(owner), erc4626.convertToAssets(erc4626.balanceOf(owner)), "MAX_WITHDRAW_MISMATCH");
	}

	/// ERC4626-09: maxRedeem MUST equal balanceOf(owner).
	function echidna_max_redeem_matches_balance() public {
		address owner = _getActor();
		eq(erc4626.maxRedeem(owner), erc4626.balanceOf(owner), "MAX_REDEEM_MISMATCH");
	}

	/// ERC4626-10: asset MUST NOT revert.
	function echidna_asset_must_not_revert() public {
		erc4626.asset();
	}

	/// ERC4626-11: totalAssets MUST NOT revert.
	function echidna_total_assets_must_not_revert() public {
		erc4626.totalAssets();
	}

	/// ERC4626-12: max{Deposit,Mint,Withdraw,Redeem} MUST NOT revert.
	function echidna_max_functions_must_not_revert() public {
		address caller = _getActor();
		address receiver = address(this);
		address owner = _getActor();
		vm.prank(caller);
		erc4626.maxDeposit(receiver);
		vm.prank(caller);
		erc4626.maxMint(receiver);
		vm.prank(caller);
		erc4626.maxWithdraw(owner);
		vm.prank(caller);
		erc4626.maxRedeem(owner);
	}

	/// ERC4626-13: convertToShares MUST NOT vary by caller.
	function echidna_convert_to_shares_caller_independent() public {
		if (_convertToSharesWouldRevert()) {
			return;
		}
		address caller1 = _getActor();
		address caller2 = address(this);
		uint256 assets = _sampleAssets();
		vm.prank(caller1);
		uint256 res1 = erc4626.convertToShares(assets);
		vm.prank(caller2);
		uint256 res2 = erc4626.convertToShares(assets);
		eq(res1, res2, "CONVERT_TO_SHARES_CALLER_DEP");
	}

	/// ERC4626-14: convertToAssets MUST NOT vary by caller.
	function echidna_convert_to_assets_caller_independent() public {
		address caller1 = _getActor();
		address caller2 = address(this);
		uint256 shares = _sampleShares();
		vm.prank(caller1);
		uint256 res1 = erc4626.convertToAssets(shares);
		vm.prank(caller2);
		uint256 res2 = erc4626.convertToAssets(shares);
		eq(res1, res2, "CONVERT_TO_ASSETS_CALLER_DEP");
	}

	/// ERC4626-15: previewDeposit MUST NOT over-estimate actual deposit shares.
	function echidna_preview_deposit_not_over_estimate() public {
		address caller = _getActor();
		if (_convertToSharesWouldRevert()) {
			return;
		}
		uint256 assets = _sampleAssets();
		assets = _capAmount(assets);
		if (assets == 0) {
			return;
		}
		uint256 preview = erc4626.previewDeposit(assets);
		if (preview == 0) {
			return;
		}
		_mintAndApprove(caller, assets);
		vm.prank(caller);
		uint256 actual = erc4626.deposit(assets, caller);
		gte(actual, preview, "PREVIEW_DEPOSIT_OVER_ESTIMATE");
	}

	/// ERC4626-16: previewMint MUST NOT under-estimate actual mint assets.
	function echidna_preview_mint_not_under_estimate() public {
		address caller = _getActor();
		uint256 shares = _sampleShares();
		if (shares == 0) {
			return;
		}
		uint256 preview = erc4626.previewMint(shares);
		if (preview == 0 || preview > type(uint128).max) {
			return;
		}
		_mintAndApprove(caller, preview);
		vm.prank(caller);
		uint256 actual = erc4626.mint(shares, caller);
		lte(actual, preview, "PREVIEW_MINT_UNDER_ESTIMATE");
	}

	/// ERC4626-17: previewWithdraw MUST NOT under-estimate actual withdraw shares.
	function echidna_preview_withdraw_not_under_estimate() public {
		address caller = _getActor();
		if (_convertToSharesWouldRevert()) {
			return;
		}
		uint256 assets = _sampleAssets();
		assets = _capAmount(assets);
		if (assets == 0) {
			return;
		}
		_mintAndApprove(caller, assets);
		uint256 previewDeposit = erc4626.previewDeposit(assets);
		if (previewDeposit == 0) {
			return;
		}
		vm.prank(caller);
		erc4626.deposit(assets, caller);
		uint256 maxWithdraw = erc4626.maxWithdraw(caller);
		if (maxWithdraw == 0) {
			return;
		}
		assets = _boundUint(assets, maxWithdraw);
		uint256 preview = erc4626.previewWithdraw(assets);
		vm.prank(caller);
		uint256 actual = erc4626.withdraw(assets, caller, caller);
		lte(actual, preview, "PREVIEW_WITHDRAW_UNDER_ESTIMATE");
	}

	/// ERC4626-18: previewRedeem MUST NOT over-estimate actual redeem assets.
	function echidna_preview_redeem_not_over_estimate() public {
		address caller = _getActor();
		uint256 shares = _sampleShares();
		if (shares == 0) {
			return;
		}
		if (_convertToSharesWouldRevert()) {
			return;
		}
		uint256 assets = _capAmount(shares);
		if (assets == 0) {
			return;
		}
		_mintAndApprove(caller, assets);
		uint256 previewDeposit = erc4626.previewDeposit(assets);
		if (previewDeposit == 0) {
			return;
		}
		vm.prank(caller);
		uint256 mintedShares = erc4626.deposit(assets, caller);
		if (mintedShares == 0) {
			return;
		}
		uint256 maxRedeem = erc4626.maxRedeem(caller);
		if (maxRedeem == 0) {
			return;
		}
		shares = _boundUint(shares, mintedShares < maxRedeem ? mintedShares : maxRedeem);
		if (shares == 0) {
			return;
		}
		uint256 preview = erc4626.previewRedeem(shares);
		if (preview == 0) {
			return;
		}
		vm.prank(caller);
		uint256 actual = erc4626.redeem(shares, caller, caller);
		gte(actual, preview, "PREVIEW_REDEEM_OVER_ESTIMATE");
	}

	function _mintAndApprove(address owner, uint256 amount) internal {
		if (amount == 0) {
			return;
		}
		ReconMockERC20 asset = ReconMockERC20(address(erc4626.asset()));
		asset.mint(owner, amount);
		vm.prank(owner);
		asset.approve(address(erc4626), amount);
	}

	function _sampleAssets() internal returns (uint256) {
		uint256 supply = erc4626.totalSupply();
		uint256 maxAssets = supply == 0 ? type(uint256).max : type(uint256).max / supply;
		return _boundUint(_seed(), maxAssets);
	}

	function _sampleShares() internal returns (uint256) {
		uint256 totalAssets = erc4626.totalAssets();
		uint256 maxShares = totalAssets == 0 ? type(uint256).max : type(uint256).max / totalAssets;
		return _boundUint(_seed(), maxShares);
	}

	function _seed() internal view returns (uint256) {
		return uint256(keccak256(abi.encodePacked(_getActor(), erc4626.totalSupply(), erc4626.totalAssets())));
	}

	function _capAmount(uint256 amount) internal returns (uint256) {
		return _boundUint(amount, type(uint128).max);
	}

	function _convertToSharesWouldRevert() internal view returns (bool) {
		return erc4626.totalSupply() > 0 && erc4626.totalAssets() == 0;
	}

	function _boundUint(uint256 value, uint256 max) internal returns (uint256) {
		if (max == type(uint256).max) {
			return value;
		}
		return between(value, 0, max);
	}

}