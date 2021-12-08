// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface VariableDebtLike {
	function scaledTotalSupply() external view returns (uint256);
}

interface StableDebtLike {
	function getTotalSupplyAndAvgRate() external view returns (uint256, uint256);
}

interface TokenLike {
	function balanceOf(address) external view returns (uint256);
	function burn(address, uint256, uint256) external;
	function mint(address, uint256, uint256) external returns (bool);
	function transfer(address, uint256) external;
	function transferFrom(address, address, uint256) external;
}

interface InterestStrategyLike {
	function calculateInterestRates(address, uint256, uint256, uint256, uint256, uint256) external returns (uint256, uint256, uint256);
}

contract PoolMock {
	// //stores the reserve configuration
	// ReserveConfigurationMap configuration;
	//the liquidity index. Expressed in ray
	uint128 liquidityIndex;
	//variable borrow index. Expressed in ray
	uint128 variableBorrowIndex;
	//the current supply rate. Expressed in ray
	uint128 currentLiquidityRate;
	//the current variable borrow rate. Expressed in ray
	uint128 currentVariableBorrowRate;
	//the current stable borrow rate. Expressed in ray
	uint128 currentStableBorrowRate;
	uint40 lastUpdateTimestamp;
	//tokens addresses
	address aTokenAddress;
	address stableDebtTokenAddress;
	address variableDebtTokenAddress;
	//address of the interest rate strategy
	address interestRateStrategyAddress;

	uint256 reserveFactor;

	// struct MintToTreasuryLocalVars {
	// 	uint256 currentStableDebt;
	// 	uint256 principalStableDebt;
	// 	uint256 previousStableDebt;
	// 	uint256 currentVariableDebt;
	// 	uint256 previousVariableDebt;
	// 	uint256 avgStableRate;
	// 	uint256 cumulatedStableInterest;
	// 	uint256 totalDebtAccrued;
	// 	uint256 amountToMint;
	// 	uint256 reserveFactor;
	// 	uint40 stableSupplyUpdatedTimestamp;
	// }

	struct UpdateInterestRatesLocalVars {
		address stableDebtTokenAddress;
		uint256 availableLiquidity;
		uint256 totalStableDebt;
		uint256 newLiquidityRate;
		uint256 newStableRate;
		uint256 newVariableRate;
		uint256 avgStableRate;
		uint256 totalVariableDebt;
	}

	uint256 internal constant RAY = 1e27;
	uint256 internal constant halfRAY = RAY / 2;

	function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }

	function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

	function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0 || b == 0) {
			return 0;
		}

		require(a <= (type(uint256).max - halfRAY) / b);

		return (a * b + halfRAY) / RAY;
	}

	function calculateLinearInterest(uint256 rate, uint40 lastUpdateTimestamp) internal view returns (uint256) {
		uint256 timeDifference = sub(block.timestamp, uint256(lastUpdateTimestamp));

		return add(mul(rate, timeDifference) / 365 days, RAY);
	}

	function calculateCompoundedInterest(
		uint256 rate,
		uint40 lastUpdateTimestamp,
		uint256 currentTimestamp
	) internal pure returns (uint256) {
		uint256 exp = sub(currentTimestamp, uint256(lastUpdateTimestamp));

		if (exp == 0) {
			return RAY;
		}

		uint256 expMinusOne = exp - 1;

		uint256 expMinusTwo = exp > 2 ? exp - 2 : 0;

		uint256 ratePerSecond = rate / 365 days;

		uint256 basePowerTwo = rayMul(ratePerSecond, ratePerSecond);
		uint256 basePowerThree = rayMul(basePowerTwo, ratePerSecond);

		uint256 secondTerm = mul(mul(exp, expMinusOne), basePowerTwo) / 2;
		uint256 thirdTerm = mul(mul(mul(exp, expMinusOne), expMinusTwo), basePowerThree) / 6;

		return add(add(add(RAY, mul(ratePerSecond, exp)), secondTerm), thirdTerm);
	}

	function calculateCompoundedInterest(uint256 rate, uint40 lastUpdateTimestamp) internal view returns (uint256) {
		return calculateCompoundedInterest(rate, lastUpdateTimestamp, block.timestamp);
	}

	function getReserveNormalizedVariableDebt() external view returns (uint256) {
		uint40 timestamp = lastUpdateTimestamp;

		if (timestamp == uint40(block.timestamp)) {
			//if the index was updated in the same block, no need to perform any calculation
			return variableBorrowIndex;
		}

		uint256 cumulated = 
			rayMul(
				calculateCompoundedInterest(currentVariableBorrowRate, timestamp),
				variableBorrowIndex
			);

		return cumulated;
	}

	function getReserveNormalizedIncome(address) external view returns (uint256) {
		uint40 timestamp = lastUpdateTimestamp;

		if (timestamp == uint40(block.timestamp)) {
			//if the index was updated in the same block, no need to perform any calculation
			return liquidityIndex;
		}

		uint256 cumulated = 
			rayMul(
				calculateLinearInterest(currentLiquidityRate, timestamp),
				liquidityIndex
			);

		return cumulated;
	}

	function _updateIndexes(
		uint256 scaledVariableDebt,
		uint256 liquidityIndex,
		uint256 variableBorrowIndex,
		uint40 timestamp
	) internal returns (uint256, uint256) {
		uint256 newLiquidityIndex = liquidityIndex;
		uint256 newVariableBorrowIndex = variableBorrowIndex;

		//only cumulating if there is any income being produced
		if (currentLiquidityRate > 0) {
			uint256 cumulatedLiquidityInterest = calculateLinearInterest(currentLiquidityRate, timestamp);
			newLiquidityIndex = rayMul(cumulatedLiquidityInterest, liquidityIndex);
			require(newLiquidityIndex <= type(uint128).max);

			liquidityIndex = uint128(newLiquidityIndex);

			//as the liquidity rate might come only from stable rate loans, we need to ensure
			//that there is actual variable debt before accumulating
			if (scaledVariableDebt != 0) {
				uint256 cumulatedVariableBorrowInterest =
				calculateCompoundedInterest(currentVariableBorrowRate, timestamp);
				newVariableBorrowIndex = rayMul(cumulatedVariableBorrowInterest, variableBorrowIndex);
				require(newVariableBorrowIndex <= type(uint128).max);
				variableBorrowIndex = uint128(newVariableBorrowIndex);
			}
		}

		lastUpdateTimestamp = uint40(block.timestamp);
		return (newLiquidityIndex, newVariableBorrowIndex);
	}

	// function _mintToTreasury(
	// 	uint256 scaledVariableDebt,
	// 	uint256 previousVariableBorrowIndex,
	// 	uint256 newLiquidityIndex,
	// 	uint256 newVariableBorrowIndex,
	// 	uint40 timestamp
	// ) internal {
	// 	MintToTreasuryLocalVars memory vars;

	// 	vars.reserveFactor = configuration.getReserveFactor();

	// 	if (vars.reserveFactor == 0) {
	// 		return;
	// 	}

	// 	//fetching the principal, total stable debt and the avg stable rate
	// 	(
	// 		vars.principalStableDebt,
	// 		vars.currentStableDebt,
	// 		vars.avgStableRate,
	// 		vars.stableSupplyUpdatedTimestamp
	// 	) = IStableDebtToken(stableDebtTokenAddress).getSupplyData();

	// 	//calculate the last principal variable debt
	// 	vars.previousVariableDebt = rayMul(scaledVariableDebt, previousVariableBorrowIndex);

	// 	//calculate the new total supply after accumulation of the index
	// 	vars.currentVariableDebt = rayMul(scaledVariableDebt, newVariableBorrowIndex);

	// 	//calculate the stable debt until the last timestamp update
	// 	vars.cumulatedStableInterest = calculateCompoundedInterest(
	// 		vars.avgStableRate,
	// 		vars.stableSupplyUpdatedTimestamp,
	// 		timestamp
	// 	);

	// 	vars.previousStableDebt = rayMul(vars.principalStableDebt, vars.cumulatedStableInterest);

	// 	//debt accrued is the sum of the current debt minus the sum of the debt at the last update
	// 	vars.totalDebtAccrued = vars
	// 	.currentVariableDebt
	// 	.add(vars.currentStableDebt)
	// 	.sub(vars.previousVariableDebt)
	// 	.sub(vars.previousStableDebt);

	// 	vars.amountToMint = percentMul(vars.totalDebtAccrued, vars.reserveFactor);

	// 	// if (vars.amountToMint != 0) {
	// 	// 	TokenLike(aTokenAddress).mintToTreasury(vars.amountToMint, newLiquidityIndex);
	// 	// }
	// }

	function updateState() internal {
		uint256 scaledVariableDebt = VariableDebtLike(variableDebtTokenAddress).scaledTotalSupply();
		uint256 previousVariableBorrowIndex = variableBorrowIndex;
		uint256 previousLiquidityIndex = liquidityIndex;
		uint40 lastUpdatedTimestamp = lastUpdateTimestamp;

		(uint256 newLiquidityIndex, uint256 newVariableBorrowIndex) =
		_updateIndexes(
			scaledVariableDebt,
			previousLiquidityIndex,
			previousVariableBorrowIndex,
			lastUpdatedTimestamp
		);

		// _mintToTreasury(
		// 	scaledVariableDebt,
		// 	previousVariableBorrowIndex,
		// 	newLiquidityIndex,
		// 	newVariableBorrowIndex,
		// 	lastUpdatedTimestamp
		// );
	}

	function updateInterestRates(
		address reserveAddress,
		address aTokenAddress,
		uint256 liquidityAdded,
		uint256 liquidityTaken
	) internal {
		UpdateInterestRatesLocalVars memory vars;

		vars.stableDebtTokenAddress = stableDebtTokenAddress;

		(vars.totalStableDebt, vars.avgStableRate) = StableDebtLike(vars.stableDebtTokenAddress).getTotalSupplyAndAvgRate();

		//calculates the total variable debt locally using the scaled total supply instead
		//of totalSupply(), as it's noticeably cheaper. Also, the index has been
		//updated by the previous updateState() call
		vars.totalVariableDebt = rayMul(VariableDebtLike(variableDebtTokenAddress).scaledTotalSupply(), variableBorrowIndex);

		vars.availableLiquidity = TokenLike(reserveAddress).balanceOf(aTokenAddress);

		(
			vars.newLiquidityRate,
			vars.newStableRate,
			vars.newVariableRate
		) = InterestStrategyLike(interestRateStrategyAddress).calculateInterestRates(
			reserveAddress,
			sub(add(vars.availableLiquidity, liquidityAdded), liquidityTaken),
			vars.totalStableDebt,
			vars.totalVariableDebt,
			vars.avgStableRate,
			reserveFactor
		);
		require(vars.newLiquidityRate <= type(uint128).max);
		require(vars.newStableRate <= type(uint128).max);
		require(vars.newVariableRate <= type(uint128).max);

		currentLiquidityRate = uint128(vars.newLiquidityRate);
		currentStableBorrowRate = uint128(vars.newStableRate);
		currentVariableBorrowRate = uint128(vars.newVariableRate);
	}

	function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external {
		require(amount != 0);

		// updateState();
		// updateInterestRates(asset, aTokenAddress, amount, 0);

		TokenLike(asset).transferFrom(msg.sender, aTokenAddress, amount);

		bool isFirstDeposit = TokenLike(aTokenAddress).mint(onBehalfOf, amount, liquidityIndex);

		// if (isFirstDeposit) {
		// 	_usersConfig[onBehalfOf].setUsingAsCollateral(id, true);
		// }

	}

	function withdraw(address asset, uint256 amount, address to) external returns (uint256) {
		uint256 userBalance = TokenLike(aTokenAddress).balanceOf(msg.sender);

		uint256 amountToWithdraw = amount == type(uint256).max ? userBalance : amount;

		// ValidationLogic.validateWithdraw(
		// 	asset,
		// 	amountToWithdraw,
		// 	userBalance,
		// 	_reserves,
		// 	_usersConfig[msg.sender],
		// 	_reservesList,
		// 	_reservesCount,
		// 	_addressesProvider.getPriceOracle()
		// );
		require(amountToWithdraw != 0);
		require(amountToWithdraw <= userBalance);
		// require(
		// 	GenericLogic.balanceDecreaseAllowed(
		// 		reserveAddress,
		// 		msg.sender,
		// 		amountToWithdraw,
		// 		reservesData,
		// 		_usersConfig[msg.sender],
		// 		reserves,
		// 		reservesCount,
		// 		oracle
		// 	)
		// );

		// updateState();

		// updateInterestRates(asset, aTokenAddress, 0, amountToWithdraw);

		// if (amountToWithdraw == userBalance) {
		// 	_usersConfig[msg.sender].setUsingAsCollateral(id, false);
		// }

		TokenLike(aTokenAddress).burn(msg.sender, amountToWithdraw, liquidityIndex);

		TokenLike(asset).transfer(to, amountToWithdraw);

		return amountToWithdraw;
	}

	// function getReserveData(address) returns (,,,,,,,,,, address strategy,) {

	// }
}
