// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface PoolLike {
	function getReserveNormalizedVariableDebt() external view returns (uint256);
}

contract ADaiMock {
	PoolLike public immutable POOL;
	mapping (address => uint256) internal _balances;
	uint256 internal _totalSupply;

	/**
	* @dev Only lending pool can call functions marked by this modifier
	**/
	modifier onlyLendingPool {
		require(msg.sender == address(POOL));
		_;
	}

	constructor(
		address pool,
		address underlyingAssetAddress
	) public {
		POOL = PoolLike(pool);
	}

	uint256 internal constant RAY = 1e27;
	uint256 internal constant halfRAY = RAY / 2;

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

	function balanceOf(address user) public view returns (uint256) {
		uint256 scaledBalance = _balances[user];
		if (scaledBalance == 0) {
			return 0;
		}
		return rayMul(scaledBalance, POOL.getReserveNormalizedVariableDebt());
	}

	function mint(
		address onBehalfOf,
		uint256 amount,
		uint256 index
	) external onlyLendingPool returns (bool) {
		uint256 previousBalance = _balances[onBehalfOf];
		uint256 amountScaled = rayDiv(amount, index);
		require(amountScaled != 0);

		_balances[onBehalfOf] = add(_balances[onBehalfOf], amountScaled);
		_totalSupply = add(_totalSupply, amountScaled);

		return previousBalance == 0;
	}

	function burn(
		address user,
		uint256 amount,
		uint256 index
	) external onlyLendingPool {
		uint256 amountScaled = rayDiv(amount, index);
		require(amountScaled != 0);

		_balances[user] = sub(_balances[user], amountScaled);
		_totalSupply = sub(_totalSupply, amountScaled);
	}

	function scaledBalanceOf(address user) public view returns (uint256) {
		return _balances[user];
	}

	function totalSupply() public view returns (uint256) {
		return rayMul(_totalSupply, POOL.getReserveNormalizedVariableDebt());
	}

	function scaledTotalSupply() public view returns (uint256) {
		return _totalSupply;
	}

	function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256) {
		return (_balances[user], _totalSupply);
	}
}
