pragma solidity >=0.6.12;

contract StableDebtMock {
    uint256 a;

    function totalSupply() external view returns (uint256) {
        return a;
    }
}
