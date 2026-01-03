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

## 2026-01-03: Extract numeric and math evaluators
- Problem: Numeric/math cases were spread across the evaluator, making it harder to scan.
- Change: Consolidated number helpers into ast/interpreter_numeric.mbt.
- Result: Numeric and math dispatch reads cleaner with no behavior changes.
- Example:
Before: ast/interpreter.mbt contained Add/Floor/Sqrt/Min/Max, Round/Ceil/Abs, and Pow/Log/Exp/Sin/Cos/Tan/Asin/Acos/Atan inline.
After: ast/interpreter_numeric.mbt provides eval_* helpers for those cases.

## 2026-01-03: Extract string operations and trimming
- Problem: String operations and ASCII trimming logic were mixed into the main evaluator.
- Change: Moved string ops and trimming helpers into ast/interpreter_string_ops.mbt.
- Result: String cases are easier to scan and reuse.
- Example:
Before: ast/interpreter.mbt had Split/Join/Contains/Inside and LTrimStr/RTrimStr/AsciiUpcase/AsciiDowncase inline.
After: ast/interpreter_string_ops.mbt owns those implementations.

## 2026-01-03: Extract object/array entry operations
- Problem: Entry conversion and membership checks cluttered the evaluator dispatch.
- Change: Moved Has/In/ToEntries/FromEntries/WithEntries into ast/interpreter_object_array_ops.mbt.
- Result: Collection ops are grouped in one helper file with the same behavior.
- Example:
Before: ast/interpreter.mbt implemented Has/In and *Entries cases inline.
After: ast/interpreter_object_array_ops.mbt provides eval_* helpers for those cases.

## 2026-01-03: Extract iteration and index helpers
- Problem: Indexing helpers were scattered across iteration and array sections.
- Change: Consolidated Range/First/Last/IndicesOf/IndexOf/Nth/RIndex into ast/interpreter_iteration.mbt.
- Result: Iterator and index helpers are grouped for easier maintenance.
- Example:
Before: ast/interpreter.mbt contained range/index helpers inline in multiple blocks.
After: ast/interpreter_iteration.mbt hosts the shared eval_* implementations.

## 2026-01-03: Extract path evaluators
- Problem: Path traversal logic was embedded directly in the evaluator dispatch.
- Change: Moved Paths/LeafPaths/GetPath/SetPath/DelPaths into ast/interpreter_paths.mbt.
- Result: Path behavior stays the same with a smaller eval switch.
- Example:
Before: ast/interpreter.mbt had path evaluation bodies inline.
After: ast/interpreter_paths.mbt provides eval_* helpers for path operations.

## 2026-01-03: Extract regex helpers
- Problem: Regex-like string helpers were inline in the evaluator.
- Change: Moved Test/Match/Capture/Splits/Sub/GSub into ast/interpreter_regex.mbt.
- Result: Regex operations are grouped with clearer dispatch.
- Example:
Before: ast/interpreter.mbt implemented regex helpers inline.
After: ast/interpreter_regex.mbt contains eval_* regex helpers.

## 2026-01-03: Extract extra feature evaluators
- Problem: The "newly added features" block was large and hard to scan in the evaluator.
- Change: Moved MapValues/Range*/Gen*/JSON helpers and related utilities into ast/interpreter_extras.mbt.
- Result: Extra features are grouped together and the main dispatch is shorter.
- Example:
Before: ast/interpreter.mbt housed MapValues, RangeWithStep, UniqueBy, Foreach, Scan, and more inline.
After: ast/interpreter_extras.mbt provides eval_* helpers for those cases.

## 2026-01-03: Extract assignment and traversal helpers
- Problem: Update/Assign and traversal logic were embedded in the evaluator.
- Change: Moved Update/Assign into ast/interpreter_assignment.mbt and RecurseWith/Walk/Path into traversal/path helpers.
- Result: The evaluator dispatch stays concise with behavior preserved.
- Example:
Before: ast/interpreter.mbt contained Update, Assign, Walk, RecurseWith, and Path logic inline.
After: ast/interpreter_assignment.mbt and ast/interpreter_traversal.mbt/ast/interpreter_paths.mbt host eval_* helpers.

## 2026-01-03: Extract control-flow evaluators
- Problem: Control-flow branches were mixed into the main evaluator.
- Change: Moved IfThenElse/TryCatch/Alternative/Limit/Until/While into ast/interpreter_control_flow.mbt.
- Result: Control flow logic is centralized and the dispatcher is leaner.
- Example:
Before: ast/interpreter.mbt implemented control flow inline.
After: ast/interpreter_control_flow.mbt provides eval_* control-flow helpers.

## 2026-01-03: Extract basic builtins
- Problem: Core built-in evaluators cluttered the top of the dispatch.
- Change: Moved Length/Keys/Values/Type/Empty/Not into ast/interpreter_builtins.mbt.
- Result: Built-ins are grouped and the evaluator switch is shorter.
- Example:
Before: ast/interpreter.mbt implemented Length/Keys/Values/Type/Empty/Not inline.
After: ast/interpreter_builtins.mbt hosts eval_* helpers for those cases.

## 2026-01-03: Extract binding helpers
- Problem: Variable lookup, function calls, and As bindings were inline in the evaluator.
- Change: Moved Variable/FunctionCall/As into ast/interpreter_bindings.mbt.
- Result: Binding logic is centralized with no behavior change.
- Example:
Before: ast/interpreter.mbt handled Variable, FunctionCall, and As inline.
After: ast/interpreter_bindings.mbt provides eval_* helpers for binding cases.

## 2026-01-03: Extract aggregate helpers
- Problem: Reduce/SortBy/GroupBy and array predicates were embedded in the evaluator.
- Change: Moved Reduce/SortBy/GroupBy/Any/All into ast/interpreter_aggregates.mbt.
- Result: Aggregation logic is grouped and easier to scan.
- Example:
Before: ast/interpreter.mbt implemented Reduce/SortBy/GroupBy/Any/All inline.
After: ast/interpreter_aggregates.mbt hosts eval_* helpers for those cases.
