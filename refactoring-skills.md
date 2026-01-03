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

## 2026-01-03: Extract compound assignment helpers
- Problem: Compound assignment operators duplicated Update/Operation wiring.
- Change: Added eval_compound_assign/eval_alt_assign in ast/interpreter_assignment.mbt and routed AddAssign/SubAssign/etc through them.
- Result: Assignment handling is centralized with fewer repeated expressions.
- Example:
Before: ast/interpreter.mbt inlined Update(Operation(...)) for each compound assignment.
After: ast/interpreter_assignment.mbt provides shared helpers for compound assignment cases.

## 2026-01-03: Split extra feature helpers into focused modules
- Problem: ast/interpreter_extras.mbt grew into a mixed bag of generators, collections, and string/JSON utilities.
- Change: Split generator helpers into ast/interpreter_generators.mbt, collection helpers into ast/interpreter_collection_extras.mbt, JSON string helpers into ast/interpreter_json_string.mbt, and moved scan/explode/implode and paths_with_filter into string/path modules.
- Result: Extra features are organized by responsibility, and the monolithic extras file is removed.
- Example:
Before: ast/interpreter_extras.mbt contained MapValues, RangeWithStep, Foreach, Scan, and conversions.
After: those helpers live in dedicated generator/collection/string/json/path files.

## 2026-01-03: Split parser built-in dispatch by category
- Problem: parser/parser_builtin.mbt had a massive match over every built-in.
- Change: Moved category-specific parsing into parser/parser_builtin_* helpers and routed through parse_builtin_by_name.
- Result: Built-in parsing is modular and easier to extend.
- Example:
Before: parser/parser_builtin.mbt handled all built-ins in one match.
After: parser/parser_builtin_core.mbt, parser/parser_builtin_array.mbt, parser/parser_builtin_string.mbt, parser/parser_builtin_numeric.mbt, parser/parser_builtin_object.mbt, parser/parser_builtin_path.mbt, and parser/parser_builtin_flow.mbt split the logic.

## 2026-01-03: Split missing feature tests by theme
- Problem: ast/missing_features_test.mbt bundled unrelated tests and helpers in one large file.
- Change: Moved test_feature into ast/missing_features_helpers_test.mbt and split tests into themed files.
- Result: Tests are easier to locate and maintain without behavior changes.
- Example:
Before: ast/missing_features_test.mbt contained all missing feature tests.
After: ast/missing_features_array_path_test.mbt, ast/missing_features_string_test.mbt, ast/missing_features_format_regex_test.mbt, ast/missing_features_math_test.mbt, ast/missing_features_ops_flow_test.mbt, and ast/missing_features_functions_test.mbt organize them by topic.

## 2026-01-03: Split path helpers by responsibility
- Problem: ast/interpreter_paths.mbt mixed enumeration, access, and mutation helpers.
- Change: Split into ast/interpreter_path_enumeration.mbt, ast/interpreter_path_access.mbt, and ast/interpreter_path_mutation.mbt.
- Result: Path logic is grouped by concern with smaller files.
- Example:
Before: ast/interpreter_paths.mbt contained collect_paths_with_filter, eval_get_path, and set/delete helpers together.
After: enumeration/access/mutation helpers live in separate path-focused files.

## 2026-01-03: Split string helpers by theme
- Problem: ast/interpreter_string_ops.mbt mixed core string ops, trim/case, and scan helpers.
- Change: Split into ast/interpreter_string_core.mbt, ast/interpreter_string_trim.mbt, and ast/interpreter_string_scan.mbt.
- Result: String helpers are organized by intent with smaller files.
- Example:
Before: ast/interpreter_string_ops.mbt contained split/join, trim/case, and scan/explode/implode together.
After: string core, trim/case, and scan helpers live in dedicated files.

## 2026-01-03: Split generator helpers by role
- Problem: ast/interpreter_generators.mbt mixed range, stream, predicate, and foreach helpers.
- Change: Split into ast/interpreter_generator_range.mbt, ast/interpreter_generator_stream.mbt, ast/interpreter_generator_predicates.mbt, and ast/interpreter_generator_foreach.mbt.
- Result: Generator helpers are grouped by responsibility with smaller files.
- Example:
Before: ast/interpreter_generators.mbt contained range, any/all, first/last, repeat, and foreach logic together.
After: generator helpers live in dedicated range/stream/predicate/foreach files.

## 2026-01-03: Split parser flow built-ins by theme
- Problem: parser/parser_builtin_flow.mbt grouped range, predicates, control flow, reduce/foreach, and traversal parsing.
- Change: Split into parser/parser_builtin_flow_range.mbt, parser/parser_builtin_flow_predicates.mbt, parser/parser_builtin_flow_control.mbt, parser/parser_builtin_flow_reduce.mbt, and parser/parser_builtin_flow_traversal.mbt.
- Result: Flow built-in parsing is modular and easier to extend.
- Example:
Before: parser/parser_builtin_flow.mbt matched all flow built-ins in one file.
After: parser flow built-ins are routed through focused helper files.

## 2026-01-03: Split collection helpers by role
- Problem: ast/interpreter_collection_extras.mbt mixed object transforms, ordering, and matrix helpers.
- Change: Split into ast/interpreter_collection_object.mbt, ast/interpreter_collection_order.mbt, and ast/interpreter_collection_matrix.mbt.
- Result: Collection helpers are grouped by concern with smaller files.
- Example:
Before: ast/interpreter_collection_extras.mbt contained MapValues, UniqueBy/MinBy/MaxBy, and Combinations/Transpose together.
After: collection helpers live in dedicated object/order/matrix files.

## 2026-01-03: Split parser string built-ins
- Problem: parser/parser_builtin_string.mbt grouped core ops, trim/case, codec, and regex parsing.
- Change: Split into parser/parser_builtin_string_core.mbt, parser/parser_builtin_string_trim.mbt, parser/parser_builtin_string_codec.mbt, and parser/parser_builtin_string_regex.mbt.
- Result: String built-in parsing is modular and easier to extend.
- Example:
Before: parser/parser_builtin_string.mbt handled all string built-ins in one match.
After: string built-ins are routed through focused helper files.

## 2026-01-03: Split parser precedence parsing
- Problem: parser/parser_precedence.mbt contained every precedence layer in one file.
- Change: Split into parser/parser_parse_pipe.mbt, parser/parser_parse_assignment.mbt, parser/parser_parse_logic.mbt, and parser/parser_parse_arithmetic.mbt.
- Result: Precedence parsing stays modular and easier to navigate.
- Example:
Before: parser/parser_precedence.mbt defined parse_pipe through parse_unary in one file.
After: each precedence tier lives in a focused parser file.

## 2026-01-03: Split numeric helpers by role
- Problem: ast/interpreter_numeric.mbt mixed basic ops, rounding, and math functions.
- Change: Split into ast/interpreter_numeric_basic.mbt, ast/interpreter_numeric_round.mbt, and ast/interpreter_numeric_math.mbt.
- Result: Numeric helpers are grouped by concern with smaller files.
- Example:
Before: ast/interpreter_numeric.mbt held add/min/max, round/ceil/abs, and trig/exp helpers together.
After: numeric helpers live in dedicated basic/round/math files.
