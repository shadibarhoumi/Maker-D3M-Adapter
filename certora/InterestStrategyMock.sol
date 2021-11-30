pragma solidity >=0.6.12;

contract InterestStrategyMock {
    uint256 maxVariableBorrowRate;

    function getMaxVariableBorrowRate() external view returns (uint256) {
        return maxVariableBorrowRate;
    }
}
