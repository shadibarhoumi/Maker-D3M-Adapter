// DssDirectDepositAaveDai.spec

using Vat as vat
using InterestStrategyMock as interestStrategy
using StableDebtMock as stableDebt
using VariableDebtMock as variableDebt

methods {
    bar() returns (uint256) envfree
    king() returns (address) envfree
    live() returns (uint256) envfree
    tau() returns (uint256) envfree
    vat() returns (address) envfree
    wards(address) returns (uint256) envfree
    interestStrategy() returns (address) envfree
    stableDebt() returns (address) envfree
    variableDebt() returns (address) envfree
    calculateTargetSupply(uint256) returns (uint256) envfree
    vat.live() returns (uint256) envfree
    interestStrategy.baseVariableBorrowRate() returns (uint256) envfree
    interestStrategy.getMaxVariableBorrowRate() returns (uint256) envfree
    interestStrategy.variableRateSlope1() returns (uint256) envfree
    interestStrategy.variableRateSlope2() returns (uint256) envfree
    interestStrategy.OPTIMAL_UTILIZATION_RATE() returns (uint256) envfree
    interestStrategy.EXCESS_UTILIZATION_RATE() returns (uint256) envfree
    stableDebt.totalSupply() returns (uint256) envfree
    variableDebt.totalSupply() returns (uint256) envfree
}

definition RAY() returns uint256 = 10^27;

// Verify that wards behaves correctly on rely
rule rely(address usr) {
    env e;

    rely(e, usr);

    assert(wards(usr) == 1, "rely did not set the wards as expected");
}

// Verify revert rules on rely
rule rely_revert(address usr) {
    env e;

    uint256 ward = wards(e.msg.sender);

    rely@withrevert(e, usr);

    bool revert1 = e.msg.value > 0;
    bool revert2 = ward != 1;

    assert(revert1 => lastReverted, "revert1 failed");
    assert(revert2 => lastReverted, "revert2 failed");

    assert(lastReverted => revert1 || revert2, "Revert rules are not covering all the cases");
}

// Verify that wards behaves correctly on deny
rule deny(address usr) {
    env e;

    deny(e, usr);

    assert(wards(usr) == 0, "deny did not set the wards as expected");
}

// Verify revert rules on deny
rule deny_revert(address usr) {
    env e;

    uint256 ward = wards(e.msg.sender);

    deny@withrevert(e, usr);

    bool revert1 = e.msg.value > 0;
    bool revert2 = ward != 1;

    assert(revert1 => lastReverted, "revert1 failed");
    assert(revert2 => lastReverted, "revert2 failed");

    assert(lastReverted => revert1 || revert2, "Revert rules are not covering all the cases");
}

// Verify that cap behaves correctly on file
rule file_uint256(bytes32 what, uint256 data) {
    env e;

    file(e, what, data);

    assert(what == 0x6261720000000000000000000000000000000000000000000000000000000000 => bar() == data, "file did not set bar as expected");
    assert(what == 0x7461750000000000000000000000000000000000000000000000000000000000 => tau() == data, "file did not set tau as expected");
}

// Verify revert rules on file
rule file_uint256_revert(bytes32 what, uint256 data) {
    env e;

    uint256 ward = wards(e.msg.sender);
    uint256 maxVariableBorrowRate = interestStrategy.getMaxVariableBorrowRate();
    uint256 live = live();

    file@withrevert(e, what, data);

    bool revert1 = e.msg.value > 0;
    bool revert2 = ward != 1;
    bool revert3 = what != 0x6261720000000000000000000000000000000000000000000000000000000000 && what != 0x7461750000000000000000000000000000000000000000000000000000000000; // what is not "bar" or "tau"
    bool revert4 = what == 0x6261720000000000000000000000000000000000000000000000000000000000 && data > maxVariableBorrowRate;
    bool revert5 = what == 0x7461750000000000000000000000000000000000000000000000000000000000 && live != 1;

    assert(revert1 => lastReverted, "revert1 failed");
    assert(revert2 => lastReverted, "revert2 failed");
    assert(revert3 => lastReverted, "revert3 failed");
    assert(revert4 => lastReverted, "revert4 failed");
    assert(revert5 => lastReverted, "revert5 failed");

    assert(lastReverted => revert1 || revert2 || revert3 || revert4 || revert5, "Revert rules are not covering all the cases");
}

// Verify that cap behaves correctly on file
rule file_address(bytes32 what, address data) {
    env e;

    file(e, what, data);

    assert(king() == data, "file did not set king as expected");
}

// Verify revert rules on file
rule file_address_revert(bytes32 what, address data) {
    env e;

    uint256 ward    = wards(e.msg.sender);
    uint256 vatLive = vat.live();

    file@withrevert(e, what, data);

    bool revert1 = e.msg.value > 0;
    bool revert2 = ward != 1;
    bool revert3 = what != 0x6b696e6700000000000000000000000000000000000000000000000000000000; // what is not "king"
    bool revert4 = vatLive != 1; // vat is not live

    assert(revert1 => lastReverted, "revert1 failed");
    assert(revert2 => lastReverted, "revert2 failed");
    assert(revert3 => lastReverted, "revert3 failed");
    assert(revert4 => lastReverted, "revert4 failed");

    assert(lastReverted => revert1 || revert2 || revert3 || revert4, "Revert rules are not covering all the cases");
}

rule calculateTargetSupply(uint256 targetInterestRate) {
    env e;

    require(interestStrategy() == interestStrategy);
    require(stableDebt() == stableDebt);
    require(variableDebt() == variableDebt);
    uint256 targetUtil;

    uint256 base = interestStrategy.baseVariableBorrowRate();
    uint256 slope1 = interestStrategy.variableRateSlope1();
    uint256 slope2 = interestStrategy.variableRateSlope2();
    uint256 excess = interestStrategy.EXCESS_UTILIZATION_RATE();
    uint256 optimal = interestStrategy.OPTIMAL_UTILIZATION_RATE();
    uint256 sTotalSupply = stableDebt.totalSupply();
    uint256 vTotalSupply = variableDebt.totalSupply();

    if (targetInterestRate > base + slope1) {
        uint256 r = targetInterestRate - base - slope1;
        targetUtil = (excess * r / RAY()) * RAY() / slope2 + optimal;
    } else {
        targetUtil = ((targetInterestRate - base) * optimal / RAY()) * RAY() / slope1;
    }

    require(targetUtil > 0);

    uint256 calculated = (sTotalSupply + vTotalSupply) * RAY() / targetUtil;

    uint256 result = calculateTargetSupply(targetInterestRate);

    assert(calculated == result, "Target Supply doesn't match");
}

rule calculateTargetSupply_revert(uint256 targetInterestRate) {
    env e;

    uint256 base = interestStrategy.baseVariableBorrowRate();
    uint256 max = interestStrategy.getMaxVariableBorrowRate();

    uint256 slope1 = interestStrategy.variableRateSlope1();
    uint256 slope2 = interestStrategy.variableRateSlope2();
    uint256 excess = interestStrategy.EXCESS_UTILIZATION_RATE();
    uint256 optimal = interestStrategy.OPTIMAL_UTILIZATION_RATE();
    uint256 sTotalSupply = stableDebt.totalSupply();
    uint256 vTotalSupply = variableDebt.totalSupply();

    calculateTargetSupply@withrevert(targetInterestRate);

    bool revert1 = targetInterestRate <= base;
    bool revert2 = targetInterestRate > max;
    bool revert3 = base + slope1 > max_uint256;
    mathint aux = excess * (targetInterestRate - base - slope1);
    bool revert4 = (targetInterestRate > base + slope1) && aux > max_uint256;
    bool revert5 = (targetInterestRate > base + slope1) && ((aux / RAY()) * RAY() / slope2) + optimal > max_uint256;
    bool revert6 = (targetInterestRate <= base + slope1) && targetInterestRate - base < 0;
    bool revert7 = (targetInterestRate <= base + slope1) && (targetInterestRate - base) * optimal > max_uint256;
    bool revert8 = sTotalSupply + vTotalSupply > max_uint256;
    bool revert9 = (sTotalSupply + vTotalSupply) * RAY() > max_uint256;
    bool revert10 = (targetInterestRate > base + slope1) && ((aux / RAY()) * RAY() / slope2) + optimal == 0;
    bool revert11 = (targetInterestRate <= base + slope1) && ((targetInterestRate - base) * optimal / RAY()) * RAY() / slope1 == 0;

    assert(revert1 => lastReverted, "revert1 failed");
    assert(revert2 => lastReverted, "revert2 failed");
    assert(revert3 => lastReverted, "revert3 failed");
    assert(revert4 => lastReverted, "revert4 failed");
    assert(revert5 => lastReverted, "revert5 failed");
    assert(revert6 => lastReverted, "revert6 failed");
    assert(revert7 => lastReverted, "revert7 failed");
    assert(revert8 => lastReverted, "revert8 failed");
    assert(revert9 => lastReverted, "revert9 failed");
    assert(revert10 => lastReverted, "revert10 failed");
    assert(revert11 => lastReverted, "revert11 failed");

    assert(lastReverted => revert1 || revert2 || revert3 || revert4
                        || revert5 || revert6 || revert7 || revert8
                        || revert9 || revert10 || revert11, "Revert rules are not covering all the cases");
}
