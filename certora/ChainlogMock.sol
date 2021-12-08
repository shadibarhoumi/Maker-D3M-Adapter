// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.6.12;

contract ChainlogMock {
    address public end;

    function getAddress(bytes32 key) external view returns (address ret) {
        // if (key == bytes32("MCD_END")) {
        //     ret = end;
        // }
        ret = end;
    }
}
