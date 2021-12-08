pragma solidity >=0.6.12;

contract InterestStrategyMock {
    uint256 constant public baseVariableBorrowRate = 0;
    uint256 constant public getMaxVariableBorrowRate = 40000000000000000000000000 + 750000000000000000000000000;
    uint256 constant public variableRateSlope1 = 40000000000000000000000000;
    uint256 constant public variableRateSlope2 = 750000000000000000000000000;
    uint256 constant public stableRateSlope1 = 20000000000000000000000000;
    uint256 constant public stableRateSlope2 = 750000000000000000000000000;
    uint256 constant public OPTIMAL_UTILIZATION_RATE = 800000000000000000000000000;
    uint256 constant public EXCESS_UTILIZATION_RATE  = 200000000000000000000000000;

    uint256 constant internal DAI_MARKET_BORROW_RATE = 100000000000000000000000000;

    struct CalcInterestRatesLocalVars {
        uint256 totalDebt;
        uint256 currentVariableBorrowRate;
        uint256 currentStableBorrowRate;
        uint256 currentLiquidityRate;
        uint256 utilizationRate;
    }

    uint256 internal constant RAY = 1e27;
	uint256 internal constant halfRAY = RAY / 2;
    uint256 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
    uint256 constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;
    uint256 internal constant WAD_RAY_RATIO = 1e9;

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }

	function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0 || b == 0) {
			return 0;
		}

		require(a <= (type(uint256).max - halfRAY) / b);

		return (a * b + halfRAY) / RAY;
	}

	function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b != 0);
		uint256 halfB = b / 2;

		require(a <= (type(uint256).max - halfB) / RAY);

		return (a * RAY + halfB) / b;
	}

    function percentMul(uint256 value, uint256 percentage) internal pure returns (uint256) {
        if (value == 0 || percentage == 0) {
            return 0;
        }

        require(value <= (type(uint256).max - HALF_PERCENT) / percentage);

        return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR;
    }

    function wadToRay(uint256 a) internal pure returns (uint256) {
        uint256 result = a * WAD_RAY_RATIO;
        require(result / WAD_RAY_RATIO == a);
        return result;
    }

    function _getOverallBorrowRate(
        uint256 totalStableDebt,
        uint256 totalVariableDebt,
        uint256 currentVariableBorrowRate,
        uint256 currentAverageStableBorrowRate
    ) internal pure returns (uint256) {
        uint256 totalDebt = add(totalStableDebt, totalVariableDebt);

        if (totalDebt == 0) return 0;

        uint256 weightedVariableRate = rayMul(wadToRay(totalVariableDebt), currentVariableBorrowRate);

        uint256 weightedStableRate = rayMul(wadToRay(totalStableDebt), currentAverageStableBorrowRate);

        uint256 overallBorrowRate = rayDiv(add(weightedVariableRate, weightedStableRate), wadToRay(totalDebt));

        return overallBorrowRate;
    }

    function calculateInterestRates(
        address,
        uint256 availableLiquidity,
        uint256 totalStableDebt,
        uint256 totalVariableDebt,
        uint256 averageStableBorrowRate,
        uint256 reserveFactor
    ) external pure returns (uint256, uint256, uint256) {
        CalcInterestRatesLocalVars memory vars;

        vars.totalDebt = add(totalStableDebt, totalVariableDebt);
        vars.currentVariableBorrowRate = 0;
        vars.currentStableBorrowRate = 0;
        vars.currentLiquidityRate = 0;

        uint256 utilizationRate =
            vars.totalDebt == 0
                ? 0
                : rayDiv(vars.totalDebt, add(availableLiquidity, vars.totalDebt));

        vars.currentStableBorrowRate = DAI_MARKET_BORROW_RATE;

        if (utilizationRate > OPTIMAL_UTILIZATION_RATE) {
            uint256 excessUtilizationRateRatio =
                rayDiv(
                    sub(
                        utilizationRate,
                        OPTIMAL_UTILIZATION_RATE
                    ),
                    EXCESS_UTILIZATION_RATE
                );

            vars.currentStableBorrowRate =
                add(
                    add(
                        vars.currentStableBorrowRate,
                        stableRateSlope1
                    ),
                    rayMul(
                        stableRateSlope2,
                        excessUtilizationRateRatio
                    )
                );

            vars.currentVariableBorrowRate =
                add(
                    add(
                        baseVariableBorrowRate,
                        variableRateSlope1
                    ),
                    rayMul(
                        variableRateSlope2,
                        excessUtilizationRateRatio
                    )
                );
        } else {
            vars.currentStableBorrowRate =
                add(
                    vars.currentStableBorrowRate,
                    rayMul(
                        stableRateSlope1,
                        rayDiv(
                            utilizationRate,
                            OPTIMAL_UTILIZATION_RATE
                        )
                    )
                );
            vars.currentVariableBorrowRate =
                add(
                    baseVariableBorrowRate,
                    rayDiv(
                        rayMul(
                            utilizationRate,
                            variableRateSlope1
                        ),
                        OPTIMAL_UTILIZATION_RATE
                    )
                );
        }
    
        vars.currentLiquidityRate =
            percentMul(
                rayMul(
                    _getOverallBorrowRate(
                        totalStableDebt,
                        totalVariableDebt,
                        vars.currentVariableBorrowRate,
                        averageStableBorrowRate
                    ),
                    utilizationRate
                ),
                sub(
                    PERCENTAGE_FACTOR,
                    reserveFactor
                )
            );

        return (
            vars.currentLiquidityRate,
            vars.currentStableBorrowRate,
            vars.currentVariableBorrowRate
        );
    }
}
