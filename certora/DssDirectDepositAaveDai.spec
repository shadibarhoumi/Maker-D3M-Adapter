// DssDirectDepositAaveDai.spec

using Vat as vat
using InterestStrategyMock as interestStrategy

methods {
    bar() returns (uint256) envfree
    king() returns (address) envfree
    live() returns (uint256) envfree
    tau() returns (uint256) envfree
    vat() returns (address) envfree
    wards(address) returns (uint256) envfree
    vat.live() returns (uint256) envfree
    interestStrategy.getMaxVariableBorrowRate() returns (uint256) envfree
}

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

    assert(revert1 => lastReverted, "Sending ETH did not revert");
    assert(revert2 => lastReverted, "Lack of auth did not revert");

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

    assert(revert1 => lastReverted, "Sending ETH did not revert");
    assert(revert2 => lastReverted, "Lack of auth did not revert");

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

    assert(revert1 => lastReverted, "Sending ETH did not revert");
    assert(revert2 => lastReverted, "Lack of auth did not revert");
    assert(revert3 => lastReverted, "Unrecognized file param did not revert");
    assert(revert4 => lastReverted, "data greater than max variable borrow rate did not revert");
    assert(revert5 => lastReverted, "live == 0 did not revert");

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

    assert(revert1 => lastReverted, "Sending ETH did not revert");
    assert(revert2 => lastReverted, "Lack of auth did not revert");
    assert(revert3 => lastReverted, "Unrecognized file param did not revert");
    assert(revert4 => lastReverted, "Vat not live did not revert");

    assert(lastReverted => revert1 || revert2 || revert3 || revert4, "Revert rules are not covering all the cases");
}
