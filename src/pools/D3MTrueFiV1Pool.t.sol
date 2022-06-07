pragma solidity ^0.8.14;

import { D3MHub } from "../D3MHub.sol";
import { D3MMom } from "../D3MMom.sol";
import { D3MTrueFiV1Pool } from "./D3MTrueFiV1Pool.sol";

import {
    DaiLike,
    PortfolioFactoryLike,
    IERC20WithDecimals,
    ILenderVerifier
} from "../tests/interfaces/interfaces.sol";

import { D3MTrueFiV1Plan } from "../plans/D3MTrueFiV1Plan.sol";
import { AddressRegistry }   from "./AddressRegistry.sol";
import { D3MPoolBaseTest, Hevm } from "./D3MPoolBase.t.sol";

contract D3MTrueFiV1PoolTest is AddressRegistry, D3MPoolBaseTest {
    D3MTrueFiV1Pool d3mPool;
    PortfolioFactoryLike portfolioFactory;

    function setUp() public override {
        hevm = Hevm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));
        dai = DaiLike(DAI);

        _setUpTrueFiDaiPortfolio();
    }

    function testFail_withdraw_wrong_pass() public view {
        portfolioFactory.getPortfolios();
    }

    /************************/
    /*** Helper Functions ***/
    /************************/

    function _setUpTrueFiDaiPortfolio() internal {
        portfolioFactory = PortfolioFactoryLike(MANAGED_PORTFOLIO_FACTORY_PROXY);
        portfolioFactory.createPortfolio("TrueFi-D3M-DAI", "TDD", IERC20WithDecimals(DAI), ILenderVerifier(GLOBAL_WHITELIST_LENDER_VERIFIER), 60 * 60 * 24 * 30, 1_000_000 ether, 20);
    }
}