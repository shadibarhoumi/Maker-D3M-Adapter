// SPDX-FileCopyrightText: © 2021-2022 Dai Foundation <www.daifoundation.org>
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

pragma solidity ^0.8.14;
import { DSTest } from "../../lib/ds-test/src/test.sol";
import {DaiLike, CanLike, D3mHubLike} from "../tests/interfaces/interfaces.sol";

import "./ID3MPool.sol";

interface Hevm {
    function warp(uint256) external;

    function store(
        address,
        bytes32,
        bytes32
    ) external;

    function load(address, bytes32) external view returns (bytes32);
}

contract D3MPoolBase is ID3MPool, DSTest {

    DaiLike public immutable asset; // Dai

    // --- Auth ---
    mapping (address => uint256) public wards;
    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }
    modifier auth {
        require(wards[msg.sender] == 1, "D3MPoolBase/not-authorized");
        _;
    }

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    constructor(address hub_, address dai_) {
        asset = DaiLike(dai_);

        CanLike(D3mHubLike(hub_).vat()).hope(hub_);

        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    function hope(address hub) external override auth{
        CanLike(D3mHubLike(hub).vat()).hope(hub);
    }

    function nope(address hub) external override auth{
        CanLike(D3mHubLike(hub).vat()).nope(hub);
    }

    function deposit(uint256 wad) external override returns (bool) {}

    function withdraw(uint256 wad) external override returns (bool) {}

    function transfer(address dst, uint256 wad)
        external
        override
        returns (bool)
    {}

    function preDebtChange(bytes32 what) external override {}

    function postDebtChange(bytes32 what) external override {}

    function assetBalance() external view override returns (uint256) {}

    function transferAll(address dst) external override returns (bool) {}

    function maxDeposit() external view override returns (uint256) {}

    function maxWithdraw() external view override returns (uint256) {}

    function active() external override pure returns(bool) {
        return true;
    }
}

contract FakeVat {
    mapping(address => mapping (address => uint)) public can;
    function hope(address usr) external { can[msg.sender][usr] = 1; }
    function nope(address usr) external { can[msg.sender][usr] = 0; }
}

contract FakeHub {
    address public immutable vat;

    constructor(address vat_) {
        vat = vat_;
    }
}

contract D3MPoolBaseTest is DSTest {
    uint256 constant WAD = 10**18;

    Hevm hevm;

    DaiLike dai;

    address d3mTestPool;
    address hub;
    address vat;

    function setUp() public virtual {
        hevm = Hevm(
            address(bytes20(uint160(uint256(keccak256("hevm cheat code")))))
        );

        dai = DaiLike(0x6B175474E89094C44Da98b954EedeAC495271d0F);

        vat = address(new FakeVat());

        hub = address(new FakeHub(vat));

        d3mTestPool = address(new D3MPoolBase(hub, address(dai)));
    }

    function _giveTokens(DaiLike token, uint256 amount) internal {
        // Edge case - balance is already set for some reason
        if (token.balanceOf(address(this)) == amount) return;

        for (int256 i = 0; i < 100; i++) {
            // Scan the storage for the balance storage slot
            bytes32 prevValue = hevm.load(
                address(token),
                keccak256(abi.encode(address(this), uint256(i)))
            );
            hevm.store(
                address(token),
                keccak256(abi.encode(address(this), uint256(i))),
                bytes32(amount)
            );
            if (token.balanceOf(address(this)) == amount) {
                // Found it
                return;
            } else {
                // Keep going after restoring the original value
                hevm.store(
                    address(token),
                    keccak256(abi.encode(address(this), uint256(i))),
                    prevValue
                );
            }
        }

        // We have failed if we reach here
        assertTrue(false);
    }

    function test_sets_creator_as_ward() public {
        assertEq(D3MPoolBase(d3mTestPool).wards(address(this)), 1);
    }

    function test_hopes_on_hub() public {
        assertEq(CanLike(vat).can(d3mTestPool, hub), 1);
    }

    function test_can_hope() public {
        address newHub = address(new FakeHub(vat));
        assertEq(CanLike(vat).can(d3mTestPool, newHub), 0);
        D3MPoolBase(d3mTestPool).hope(newHub);
        assertEq(CanLike(vat).can(d3mTestPool, newHub), 1);
    }

    function test_can_nope() public {
        assertEq(CanLike(vat).can(d3mTestPool, hub), 1);
        D3MPoolBase(d3mTestPool).nope(hub);
        assertEq(CanLike(vat).can(d3mTestPool, hub), 0);
    }

    function testFail_cannot_hope_without_auth() public {
        D3MPoolBase(d3mTestPool).deny(address(this));
        address newHub = address(new FakeHub(vat));
        D3MPoolBase(d3mTestPool).hope(newHub);
    }

    function testFail_cannot_nope_without_auth() public {
        D3MPoolBase(d3mTestPool).deny(address(this));
        D3MPoolBase(d3mTestPool).nope(hub);
    }

    function test_can_rely() public {
        assertEq(D3MPoolBase(d3mTestPool).wards(address(123)), 0);

        D3MPoolBase(d3mTestPool).rely(address(123));

        assertEq(D3MPoolBase(d3mTestPool).wards(address(123)), 1);
    }

    function test_can_deny() public {
        assertEq(D3MPoolBase(d3mTestPool).wards(address(this)), 1);

        D3MPoolBase(d3mTestPool).deny(address(this));

        assertEq(D3MPoolBase(d3mTestPool).wards(address(this)), 0);
    }

    function testFail_cannot_rely_without_auth() public {
        assertEq(D3MPoolBase(d3mTestPool).wards(address(this)), 1);

        D3MPoolBase(d3mTestPool).deny(address(this));
        D3MPoolBase(d3mTestPool).rely(address(this));
    }

    function test_implements_preDebtChange() public {
        D3MPoolBase(d3mTestPool).preDebtChange("test");
    }

    function test_implements_postDebtChange() public {
        D3MPoolBase(d3mTestPool).postDebtChange("test");
    }

    function test_implements_active() public view {
        D3MPoolBase(d3mTestPool).active();
    }
}
