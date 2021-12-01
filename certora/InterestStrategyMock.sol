pragma solidity >=0.6.12;

contract InterestStrategyMock {
    function baseVariableBorrowRate() external pure returns (uint256) {
        return 0;
    }

    function getMaxVariableBorrowRate() external pure returns (uint256) {
        return 40000000000000000000000000 + 750000000000000000000000000;
    }

    function variableRateSlope1() external pure returns (uint256) {
        return 40000000000000000000000000;
    }

    function variableRateSlope2() external pure returns (uint256) {
        return 750000000000000000000000000;
    }

    function OPTIMAL_UTILIZATION_RATE() external pure returns (uint256) {
        return 800000000000000000000000000;
    }

    function EXCESS_UTILIZATION_RATE() external pure returns (uint256) {
        return 200000000000000000000000000;
    }
}

// contract InterestStrategyMock {
//     uint256 a;
//     uint256 b;
//     uint256 c;
//     uint256 d;
//     uint256 e;
//     uint256 f;

//     function baseVariableBorrowRate() external view returns (uint256) {
//         return a;
//     }

//     function getMaxVariableBorrowRate() external view returns (uint256) {
//         return b;
//     }

//     function variableRateSlope1() external view returns (uint256) {
//         return c;
//     }

//     function variableRateSlope2() external view returns (uint256) {
//         return d;
//     }

//     function OPTIMAL_UTILIZATION_RATE() external view returns (uint256) {
//         return e;
//     }

//     function EXCESS_UTILIZATION_RATE() external view returns (uint256) {
//         return f;
//     }
// }
