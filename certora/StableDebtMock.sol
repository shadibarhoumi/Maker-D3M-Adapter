pragma solidity >=0.6.12;

contract StableDebtMock {
    uint256 _totalSupply;
    // uint40  _totalSupplyTimestamp;
    // uint256 _avgStableRate;

    // uint256 internal constant RAY = 1e27;
	// uint256 internal constant halfRAY = RAY / 2;

    // function add(uint x, uint y) internal pure returns (uint z) {
    //     require((z = x + y) >= x);
    // }

    // function sub(uint x, uint y) internal pure returns (uint z) {
    //     require((z = x - y) <= x);
    // }

	// function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    //     require(y == 0 || (z = x * y) / y == x);
    // }

    // function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
	// 	if (a == 0 || b == 0) {
	// 		return 0;
	// 	}

	// 	require(a <= (type(uint256).max - halfRAY) / b);

	// 	return (a * b + halfRAY) / RAY;
	// }

    // function calculateCompoundedInterest(
	// 	uint256 rate,
	// 	uint40 lastUpdateTimestamp,
	// 	uint256 currentTimestamp
	// ) internal pure returns (uint256) {
	// 	uint256 exp = sub(currentTimestamp, uint256(lastUpdateTimestamp));

	// 	if (exp == 0) {
	// 		return RAY;
	// 	}

	// 	uint256 expMinusOne = exp - 1;

	// 	uint256 expMinusTwo = exp > 2 ? exp - 2 : 0;

	// 	uint256 ratePerSecond = rate / 365 days;

	// 	uint256 basePowerTwo = rayMul(ratePerSecond, ratePerSecond);
	// 	uint256 basePowerThree = rayMul(basePowerTwo, ratePerSecond);

	// 	uint256 secondTerm = mul(mul(exp, expMinusOne), basePowerTwo) / 2;
	// 	uint256 thirdTerm = mul(mul(mul(exp, expMinusOne), expMinusTwo), basePowerThree) / 6;

	// 	return add(add(add(RAY, mul(ratePerSecond, exp)), secondTerm), thirdTerm);
	// }

	// function calculateCompoundedInterest(uint256 rate, uint40 lastUpdateTimestamp) internal view returns (uint256) {
	// 	return calculateCompoundedInterest(rate, lastUpdateTimestamp, block.timestamp);
	// }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // function totalSupply() public view returns (uint256) {
    //     return _calcTotalSupply(_avgStableRate);
    // }

    // function _calcTotalSupply(uint256 avgRate) internal view virtual returns (uint256) {
    //     uint256 principalSupply = _totalSupply;

    //     if (principalSupply == 0) {
    //         return 0;
    //     }

    //     uint256 cumulatedInterest = calculateCompoundedInterest(avgRate, _totalSupplyTimestamp);

    //     return rayMul(principalSupply, cumulatedInterest);
    // }

    // function getTotalSupplyAndAvgRate() public view returns (uint256, uint256) {
    //     uint256 avgRate = _avgStableRate;
    //     return (_calcTotalSupply(avgRate), avgRate);
    // }
}
