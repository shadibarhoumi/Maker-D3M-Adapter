pragma solidity >=0.6.12;

// interface PoolLike {
// 	function getReserveNormalizedVariableDebt() external view returns (uint256);
// }

contract VariableDebtMock {
    uint256 supply;
    // address POOL;

    // uint256 internal constant RAY = 1e27;
    // uint256 internal constant halfRAY = RAY / 2;

    // function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
    //     if (a == 0 || b == 0) {
    //         return 0;
    //     }

    //     require(a <= (type(uint256).max - halfRAY) / b);

    //     return (a * b + halfRAY) / RAY;
    // }

    // function scaledTotalSupply() external view returns (uint256) {
    //     return supply;
    // }

    // function totalSupply() public view returns (uint256) {
    //     return rayMul(supply, PoolLike(POOL).getReserveNormalizedVariableDebt());
    // }

    function totalSupply() public view returns (uint256) {
        return supply;
    }
}
