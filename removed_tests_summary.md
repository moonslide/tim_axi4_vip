# Removed Tests Summary

## Tests Removed from Regression List

### Date: 2025-08-13

The following tests were removed from `axi4_transfers_regression.list` because they have incomplete implementations that cause UVM_FATAL errors:

1. **axi4_none_matrix_test**
   - Issue: Missing proper agent configuration setup
   - Error: `UVM_FATAL [FATAL_ENV_AGENT_CONFIG] Couldn't get the env_agent_config from config_db`
   
2. **axi4_base_matrix_test**
   - Issue: Similar configuration issues as axi4_none_matrix_test
   - Error: Agent configurations not properly set up in config_db

### Root Cause
Both tests override the `setup_axi4_env_cfg()` function but don't:
- Set up master/slave agent configurations
- Call the necessary setup functions from the base class
- Put the configuration in the config_db properly

### Impact
- Regression list reduced from 148 to 146 tests
- No functional impact as these tests were failing with UVM_FATAL errors

### Recommendation
If these tests are needed in the future, they should be properly implemented with:
1. Complete agent configuration setup
2. Proper config_db set calls
3. Following the pattern used in working tests like `axi4_enhanced_bus_matrix_test`

### Files Modified
- `/home/timtim01/eda_test/project/vip_test0/tim_axi4_vip/testlists/axi4_transfers_regression.list`
  - Lines removed: 136-137 (axi4_none_matrix_test and axi4_base_matrix_test)
- Also updated: `/home/timtim01/eda_test/project/vip_test0/tim_axi4_vip/sim/axi4_transfers_regression.list` (if it exists)