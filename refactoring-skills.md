## 2026-01-03: Split interpreter helpers into cohesive files
- Problem: Interpreter helpers and encoders were buried at the end of a large evaluator file.
- Change: Moved error/env helpers, JSON ops, traversal, path helpers, and encoding utilities into focused ast/* files.
- Result: No public API change; moon check still passes.
- Example:
Before: ast/interpreter.mbt contained eval, Env, json ops, and encoding helpers in one file.
After: ast/interpreter.mbt keeps eval, with helpers in ast/interpreter_env.mbt and ast/interpreter_encoding.mbt.

## 2026-01-03: Split tests and keep helpers in test-only files
- Problem: Large test files and helper functions living in production files.
- Change: Split comprehensive/corner tests into focused *_test.mbt files and moved test_query to test_helpers_test.mbt.
- Result: Same coverage with clearer ownership; no public API impact.
- Example:
Before: ast/comprehensive_test.mbt defined test_query and mixed all feature tests.
After: ast/test_helpers_test.mbt holds test_query; tests live in ast/comprehensive_*_test.mbt and ast/corner_cases_*_test.mbt.
