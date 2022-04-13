// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021-2022 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.12;

import { Hevm, D3MPoolBaseTest, FakeHub, FakeVat } from "./D3MPoolBase.t.sol";
import { DaiLike, TokenLike } from "../tests/interfaces/interfaces.sol";
import { D3MTestGem } from "../tests/stubs/D3MTestGem.sol";

import { D3MAaveDaiPool, LendingPoolLike } from "./D3MAaveDaiPool.sol";

interface RewardsClaimerLike {
    function getRewardsBalance(address[] calldata assets, address user) external view returns (uint256);
}

interface ATokenLike is TokenLike {
    function scaledBalanceOf(address) external view returns (uint256);
}

contract FakeRewardsClaimer {
    struct ClaimCall {
        address[] assets;
        uint256 amt;
        address dst;
    }
    ClaimCall public lastClaim;

    function claimRewards(address[] calldata assets, uint256 amt, address dst) external returns (uint256) {
        lastClaim = ClaimCall(
            assets,
            amt,
            dst
        );
        return amt;
    }

    function getAssetsFromClaim() external view returns (address[] memory) {
        return lastClaim.assets;
    }
}

contract FakeLendingPool {
    address public adai;
    address public interestStrategy;

    struct DepositCall {
        address asset;
        uint256 amt;
        address forWhom;
        uint16 code;
    }
    DepositCall public lastDeposit;

    struct WithdrawCall {
        address asset;
        uint256 amt;
        address dst;
    }
    WithdrawCall public lastWithdraw;

    constructor(address adai_, address interestStrategy_) public {
        adai = adai_;
        interestStrategy = interestStrategy_;
    }

    function file(bytes32 what, address data) public {
        if (what == "interestStrategy") interestStrategy = data;
    }

    function getReserveData(address asset) external view returns(
        uint256,    // Configuration
        uint128,    // the liquidity index. Expressed in ray
        uint128,    // variable borrow index. Expressed in ray
        uint128,    // the current supply rate. Expressed in ray
        uint128,    // the current variable borrow rate. Expressed in ray
        uint128,    // the current stable borrow rate. Expressed in ray
        uint40,     // last updated timestamp
        address,    // address of the adai interest bearing token
        address,    // address of the stable debt token
        address,    // address of the variable debt token
        address,    // address of the interest rate strategy
        uint8       // the id of the reserve
    ) {
        asset;
        return (
            0,
            1,
            2,
            3,
            4,
            5,
            6,
            adai,
            address(2),
            address(3),
            interestStrategy,
            7
        );
    }

    function deposit(address asset, uint256 amt, address forWhom, uint16 code) external {
        lastDeposit = DepositCall(
            asset,
            amt,
            forWhom,
            code
        );
        D3MTestGem(adai).mint(forWhom, amt);
    }

    function withdraw(address asset, uint256 amt, address dst) external {
        lastWithdraw = WithdrawCall(
            asset,
            amt,
            dst
        );
    }

    // TODO possibly remove
    function getReserveNormalizedIncome(address asset) external {}
}

contract D3MAaveDaiPoolTest is D3MPoolBaseTest {

    ATokenLike adai;
    LendingPoolLike aavePool;
    address rewardsClaimer;

    function setUp() override public {
        hevm = Hevm(
            address(bytes20(uint160(uint256(keccak256("hevm cheat code")))))
        );

        dai = DaiLike(address(new D3MTestGem(18)));
        adai = ATokenLike(address(new D3MTestGem(18)));
        aavePool = LendingPoolLike(address(new FakeLendingPool(address(adai), address(123))));
        rewardsClaimer = address(new FakeRewardsClaimer());

        d3mTestPool = address(new D3MAaveDaiPool(address(new FakeHub()), address(dai), address(aavePool), rewardsClaimer));
    }

    function test_can_file_king() public {
        assertEq(D3MAaveDaiPool(d3mTestPool).king(), address(0));

        D3MAaveDaiPool(d3mTestPool).file("king", address(123));

        assertEq(D3MAaveDaiPool(d3mTestPool).king(), address(123));
    }

    function testFail_cannot_file_king_not_live() public {
        assertEq(D3MAaveDaiPool(d3mTestPool).king(), address(0));

        D3MAaveDaiPool(d3mTestPool).cage();

        D3MAaveDaiPool(d3mTestPool).file("king", address(123));
    }

    function testFail_cannot_file_king_no_auth() public {
        assertEq(D3MAaveDaiPool(d3mTestPool).king(), address(0));

        D3MAaveDaiPool(d3mTestPool).deny(address(this));

        D3MAaveDaiPool(d3mTestPool).file("king", address(123));
    }

    function testFail_cannot_file_unknown_param() public {
        D3MAaveDaiPool(d3mTestPool).file("fail", address(123));
    }

    function test_validTarget_when_interestStrategy_same() public {
        (,,,,,,,,,, address poolStrategy,) = aavePool.getReserveData(address(dai));
        assertEq(D3MAaveDaiPool(d3mTestPool).interestStrategy(), poolStrategy);
        assertTrue(D3MAaveDaiPool(d3mTestPool).validTarget());
    }

    function test_validTarget_false_when_changed() public {
        FakeLendingPool(address(aavePool)).file("interestStrategy", address(456));
        (,,,,,,,,,, address poolStrategy,) = aavePool.getReserveData(address(dai));
        assertTrue(D3MAaveDaiPool(d3mTestPool).interestStrategy() != poolStrategy);
        assertTrue(D3MAaveDaiPool(d3mTestPool).validTarget() == false);
    }

    function test_deposit_calls_lending_pool_deposit() public {
        D3MTestGem(address(adai)).rely(address(aavePool));
        D3MAaveDaiPool(d3mTestPool).deposit(1);
        (address asset, uint256 amt, address dst, uint256 code) = FakeLendingPool(address(aavePool)).lastDeposit();
        assertEq(asset, address(dai));
        assertEq(amt, 1);
        assertEq(dst, d3mTestPool);
        assertEq(code, 0);
    }

    function testFail_deposit_requires_auth() public {
        D3MAaveDaiPool(d3mTestPool).deny(address(this));

        D3MAaveDaiPool(d3mTestPool).deposit(1);
    }

    function test_withdraw_calls_lending_pool_withdraw() public {
        D3MAaveDaiPool(d3mTestPool).withdraw(1);
        (address asset, uint256 amt, address dst) = FakeLendingPool(address(aavePool)).lastWithdraw();
        assertEq(asset, address(dai));
        assertEq(amt, 1);
        assertEq(dst, D3MAaveDaiPool(d3mTestPool).hub());
    }

    function testFail_withdraw_requires_auth() public {
        D3MAaveDaiPool(d3mTestPool).deny(address(this));

        D3MAaveDaiPool(d3mTestPool).withdraw(1);
    }

    function test_collect_claims_for_king() public {
        address king = address(123);
        D3MAaveDaiPool(d3mTestPool).file("king", king);

        address[] memory tokens = new address[](1);
        tokens[0] = address(adai);

        D3MAaveDaiPool(d3mTestPool).collect(tokens, 1);

        (uint256 amt, address dst) = FakeRewardsClaimer(rewardsClaimer).lastClaim();
        address[] memory assets = FakeRewardsClaimer(rewardsClaimer).getAssetsFromClaim();

        assertEq(tokens[0], assets[0]);
        assertEq(amt, 1);
        assertEq(dst, king);
    }

    function testFail_collect_no_king() public {
        assertEq(D3MAaveDaiPool(d3mTestPool).king(), address(0));
        address[] memory tokens = new address[](1);
        tokens[0] = address(adai);

        D3MAaveDaiPool(d3mTestPool).collect(tokens, 1);
    }

    function test_transferShares_tranfer_adai() public {
        uint256 tokens = adai.totalSupply();
        adai.transfer(d3mTestPool, tokens);
        assertEq(adai.balanceOf(address(this)), 0);
        assertEq(adai.balanceOf(d3mTestPool), tokens);

        D3MAaveDaiPool(d3mTestPool).transferShares(address(this), tokens);

        assertEq(adai.balanceOf(address(this)), tokens);
        assertEq(adai.balanceOf(d3mTestPool), 0);
    }

    function test_transferAllShares_moves_balance() public {
        uint256 tokens = adai.totalSupply();
        adai.transfer(d3mTestPool, tokens);
        assertEq(adai.balanceOf(address(this)), 0);
        assertEq(adai.balanceOf(d3mTestPool), tokens);

        D3MAaveDaiPool(d3mTestPool).transferAllShares(address(this));

        assertEq(adai.balanceOf(address(this)), tokens);
        assertEq(adai.balanceOf(d3mTestPool), 0);
    }

    function test_assetBalance_gets_adai_balanceOf_pool() public {

    }

    // TODO to be completed once we determine shareBalance
    function test_shareBalance_gets_adai_balanceOf_pool() internal {}

    function test_maxWithdraw_gets_available_assets_assetBal() public {
        uint256 tokens = dai.totalSupply();
        dai.transfer(address(adai), tokens);
        assertEq(dai.balanceOf(address(adai)), tokens);
        assertEq(adai.balanceOf(d3mTestPool), 0);

        assertEq(D3MAaveDaiPool(d3mTestPool).maxWithdraw(), 0);
    }

    function test_maxWithdraw_gets_available_assets_daiBal() public {
        uint256 tokens = adai.totalSupply();
        adai.transfer(d3mTestPool, tokens);
        assertEq(dai.balanceOf(address(adai)), 0);
        assertEq(adai.balanceOf(d3mTestPool), tokens);

        assertEq(D3MAaveDaiPool(d3mTestPool).maxWithdraw(), 0);
    }

    // TODO to be completed once we determine shareBalance
    function test_convertShares() internal {}
}