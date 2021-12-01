all     :; DAPP_BUILD_OPTIMIZE=1 DAPP_BUILD_OPTIMIZE_RUNS=200 dapp --use solc:0.6.12 build
clean   :; dapp clean
test    :; ./test.sh $(match)
deploy  :; make && dapp create DssDirectDepositAaveDai 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F 0x4449524543542d4141564556322d444149000000000000000000000000000000 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9 0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5
ifndef rule
certoraRun :; certoraRun --solc ~/.solc-select/artifacts/solc-0.6.12 src/DssDirectDepositAaveDai.sol certora/Vat.sol certora/InterestStrategyMock.sol certora/StableDebtMock.sol certora/VariableDebtMock.sol --link DssDirectDepositAaveDai:vat=Vat DssDirectDepositAaveDai:interestStrategy=InterestStrategyMock DssDirectDepositAaveDai:stableDebt=StableDebtMock DssDirectDepositAaveDai:variableDebt=VariableDebtMock --verify DssDirectDepositAaveDai:certora/DssDirectDepositAaveDai.spec --rule_sanity
else
certoraRun :; certoraRun --solc ~/.solc-select/artifacts/solc-0.6.12 src/DssDirectDepositAaveDai.sol certora/Vat.sol certora/InterestStrategyMock.sol certora/StableDebtMock.sol certora/VariableDebtMock.sol --link DssDirectDepositAaveDai:vat=Vat DssDirectDepositAaveDai:interestStrategy=InterestStrategyMock DssDirectDepositAaveDai:stableDebt=StableDebtMock DssDirectDepositAaveDai:variableDebt=VariableDebtMock --verify DssDirectDepositAaveDai:certora/DssDirectDepositAaveDai.spec --rule_sanity --rule $(rule)
endif
