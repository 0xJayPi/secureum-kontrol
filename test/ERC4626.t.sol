// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console, StdCheats} from "forge-std/Test.sol";
import {ERC4626} from "../src/tokens/ERC4626.sol";
import {ERC20} from "../src/tokens/ERC20.sol";
import {ERC20Mock} from "../src/mocks/ERC20Mock.sol";
import "kontrol-cheatcodes/KontrolCheats.sol";

contract ERC4626Test is Test, KontrolCheats {
    ERC20 public asset;
    ERC4626 public vault;
    address public alice;
    address public bob;

    function _notBuiltinAddress(address addr) internal view {
        vm.assume(addr != address(this));
        vm.assume(addr != address(vm));
        vm.assume(addr != address(asset));
        vm.assume(addr != address(vault));
    }

    function setUp() public {
        asset = new ERC20Mock();
        vault = new ERC4626(ERC20(address(asset)), "Vault", "VAULT");

        kevm.symbolicStorage(address(vault));
    }

    // totalAssets MUST NOT revert
    function test_totalAssets_doesNotRevert(address caller) public {
        _notBuiltinAddress(caller);
        vm.prank(caller);
        vault.totalAssets();
    }

    // totalAssets MUST revert when paused
    function test_totalAssets_revertsWhenPaused(address caller) public {
        _notBuiltinAddress(caller);

        vault.pause();

        vm.startPrank(caller);

        vm.expectRevert();
        vault.totalAssets();
    }

    function test_approve_emitsEvent(address from, address to, uint256 amount) public {
        _notBuiltinAddress(from);
        _notBuiltinAddress(to);

        vm.expectEmit(true, true, false, true);
        emit ERC20.Approval(from, to, amount);

        vm.prank(from);
        vault.approve(to, amount);
    }

    function test_assume_noOverflow(uint256 x, uint256 y) public {
        vm.assume(x <= x + y);
        assert(true);
    }

    function test_assume_noOverflow_freshVars() public {
        uint256 x = kevm.freshUInt(32);
        uint256 y = kevm.freshUInt(32);
        vm.assume(x <= x + y);
        assert(true);
    }

    function test_asset(address caller) public {
        _notBuiltinAddress(caller);

        vm.prank(caller);
        vault.asset();
    }

    function test_decimals(address caller) public {
        _notBuiltinAddress(caller);

        vm.startPrank(caller);
        assert(asset.decimals() <= vault.decimals());
    }

    // Fuzzing OK
    // @todo Symbolic
    function test_convertToShares_reverts(address from, uint128 amount) public {
        _notBuiltinAddress(from);

        ERC20Mock(address(asset)).mint(address(this), 1);
        asset.approve(address(vault), 1);
        vault.deposit(1, address(this));

        vault.pause();

        vm.startPrank(from);
        vm.expectRevert(bytes4(keccak256("EnforcedPause()")));
        vault.convertToShares(amount);
    }

    // make `from` and `amount` symbolic - DONE
    // assume `from` isn’t a built-in address - DONE
    // assume `vault`’s `totalSupply` is positive (otherwise, it’ll be symbolic and the execution with branch)
    // ensure the contract is paused - DONE
    // ensure `convertToShares` is called by a symbolic `from` - DONE
    // check that `convertToShares` always reverts - DONE

    // @todo in the assignment, it mentions storage mapping manipulation, review the recording
    function test_transfer(address from, address to, uint256 amount) public {
        _notBuiltinAddress(from);
        _notBuiltinAddress(to);
        vm.assume(from != to);
        // vm.assume(amount > 1 ether);

        ERC20Mock(address(asset)).mint(from, amount);

        uint256 fromPrevBalance = vault.balanceOf(from);
        uint256 toPrevBalance = vault.balanceOf(to);

        vm.startPrank(from);
        asset.approve(address(vault), amount);
        uint256 shares = vault.deposit(amount, from);
        vault.transfer(to, shares);
        vm.stopPrank();

        uint256 fromPostBalance = vault.balanceOf(from);
        uint256 toPostBalance = vault.balanceOf(to);

        unchecked {
            assert(fromPostBalance == fromPrevBalance - amount);
            assert(toPostBalance == toPrevBalance + amount);
        }
    }
    // make `from`, `to`,  and `amount` symbolic - DONE
    // assume `from` and `to` aren’t built-in addresses - DONE
    // assume `from` has enough `vault` tokens to transfer - DONE
    // assume `from` and `to` are different addresses - DONE
    // record `from` and `to` balances pre-`transfer` - DONE
    // ensure `vault.transfer()` is called by a symbolic `from` with `to` and `amount` as parameters - DONE
    // record `from` and `to` balances post-`transfer` - DONE
    // check if the balances have been updated correctly wrt the `amount` transferred - DONE
    // be wary of overflow checks — for the purposes of this exercise, ignore the possible overflow in `to`’s balance, as discussed with respect to test_assume_overflow
}
