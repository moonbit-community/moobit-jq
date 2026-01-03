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

## 2026-01-03: Extract access/construct/operation evaluators
- Problem: Core expression evaluation cases were bloating the main interpreter file.
- Change: Moved access, construct, and binary operation evaluation into focused helpers.
- Result: Cleaner interpreter dispatch with no behavior change.
- Example:
Before: ast/interpreter.mbt held Key/Index/Slice/Optional and construct/operation logic inline.
After: ast/interpreter_access.mbt, ast/interpreter_construct.mbt, and ast/interpreter_operation.mbt contain those helpers.

## 2026-01-03: Extract array builtins into helpers
- Problem: Map/select/sort/flatten/unique logic cluttered the main evaluator dispatch.
- Change: Moved array builtins into ast/interpreter_array_functions.mbt and routed through helper functions.
- Result: Interpreter case arms are shorter while preserving behavior.
- Example:
Before: ast/interpreter.mbt contained Map/Select/Sort/Reverse/Flatten/Unique bodies inline.
After: ast/interpreter_array_functions.mbt owns those implementations.
