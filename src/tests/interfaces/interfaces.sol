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

interface AuthLike {
    function wards(address) external view returns (uint256);
}

interface TokenLike {
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

interface DaiLike is TokenLike {
    function allowance(address, address) external returns (uint256);
} // declared for dai-specific expansions

interface DaiJoinLike {
    function join(address, uint256) external;
}

interface EndLike {
    function wait() external view returns (uint256);
    function cage() external;
    function cage(bytes32) external;
    function skim(bytes32, address) external;
    function thaw() external;
}

interface SpotLike {
    function file(bytes32, bytes32, address) external;
    function file(bytes32, bytes32, uint256) external;
    function poke(bytes32) external;
}

interface VatLike {
    function debt() external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function can(address, address) external returns (uint256);
    function hope(address) external;
    function nope(address) external;
    function urns(bytes32, address) external view returns (uint256, uint256);
    function gem(bytes32, address) external view returns (uint256);
    function dai(address) external view returns (uint256);
    function sin(address) external view returns (uint256);
    function Line() external view returns (uint256);
    function init(bytes32) external;
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
    function cage() external;
    function frob(bytes32, address, address, address, int256, int256) external;
    function grab(bytes32, address, address, address, int256, int256) external;
    function fold(bytes32, address, int256) external;
}

interface VowLike {
    function flapper() external view returns (address);
    function Sin() external view returns (uint256);
    function Ash() external view returns (uint256);
    function heal(uint256) external;
}

interface CanLike {
    function can(address, address) external returns (uint256);
    function hope(address) external;
    function nope(address) external;
}

interface D3mHubLike {
    function vat() external view returns (address);
}

/*************/
/*** TrueFi ***/
/*************/

interface ERC20Like {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function totalSupply() external view returns (uint256);
}

interface IERC20WithDecimals is ERC20Like {}

interface ILenderVerifier {
    function isAllowed(
        address lender,
        uint256 amount,
        bytes memory signature
    ) external view returns (bool);
}

interface PortfolioLike {
    enum PortfolioStatus {
        Open,
        Frozen,
        Closed
    }

    function getAmountToMint(uint256 amount) external view returns (uint256);
    function getStatus() external view returns (PortfolioStatus);
}

interface PortfolioFactoryLike {
    function createPortfolio(
        string memory name,
        string memory symbol,
        IERC20WithDecimals _underlyingToken,
        ILenderVerifier _lenderVerifier,
        uint256 _duration,
        uint256 _maxSize,
        uint256 _managerFee
    ) external;

    function getPortfolios() external view returns (address[] memory);
}