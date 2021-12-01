pragma solidity >=0.6.12;

contract VariableDebtMock {
    uint256 a;

    function totalSupply() external view returns (uint256) {
        return a;
    }
}
