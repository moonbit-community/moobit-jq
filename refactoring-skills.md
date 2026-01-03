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

## 2026-01-03: Split JSON operation helpers
- Problem: ast/interpreter_json_ops.mbt mixed literal evaluation, binary ops, and comparison logic.
- Change: Split into ast/interpreter_literal_eval.mbt, ast/interpreter_binary_ops.mbt, and ast/interpreter_compare.mbt.
- Result: JSON operations are grouped by responsibility with smaller files.
- Example:
Before: ast/interpreter_json_ops.mbt contained eval_literal, eval_binary_op, and compare_json together.
After: literal, binary, and compare helpers live in dedicated files.

## 2026-01-03: Split iteration helpers by role
- Problem: ast/interpreter_iteration.mbt mixed sequence iteration and index lookups.
- Change: Split into ast/interpreter_iteration_sequence.mbt and ast/interpreter_iteration_index.mbt.
- Result: Iteration helpers are grouped by concern with smaller files.
- Example:
Before: ast/interpreter_iteration.mbt handled range/first/last with index helpers in one file.
After: sequence and index helpers live in dedicated files.

## 2026-01-03: Split assignment helpers by role
- Problem: ast/interpreter_assignment.mbt mixed update logic, simple assignment, and compound helpers.
- Change: Split into ast/interpreter_assignment_update.mbt, ast/interpreter_assignment_basic.mbt, and ast/interpreter_assignment_compound.mbt.
- Result: Assignment helpers are grouped by concern with smaller files.
- Example:
Before: ast/interpreter_assignment.mbt contained eval_update, eval_assign, and compound helpers together.
After: assignment update/basic/compound helpers live in dedicated files.

## 2026-01-03: Split encoding helpers by format
- Problem: ast/interpreter_encoding.mbt grouped URI, HTML, and base64 helpers in one file.
- Change: Split into ast/interpreter_encoding_uri.mbt, ast/interpreter_encoding_html.mbt, and ast/interpreter_encoding_base64.mbt.
- Result: Encoding helpers are organized by format with no behavior change.
- Example:
Before: ast/interpreter_encoding.mbt contained uri_encode, html_escape, and base64 helpers together.
After: encoding helpers live in dedicated uri/html/base64 files.

## 2026-01-03: Split interpreter smoke tests by theme
- Problem: ast/interpreter_test.mbt combined helper logic with identity, access, operator, and builtin tests.
- Change: Moved test_eval into ast/interpreter_eval_helpers_test.mbt and split tests into focused files.
- Result: Interpreter smoke tests are grouped by concern without changing coverage.
- Example:
Before: ast/interpreter_test.mbt contained all basic eval tests in one file.
After: ast/interpreter_basic_test.mbt, ast/interpreter_access_test.mbt, ast/interpreter_operators_test.mbt, and ast/interpreter_builtins_test.mbt organize the cases.

## 2026-01-03: Split parser operator tests by category
- Problem: parser/parse_ops_test.mbt combined pipe, arithmetic, precedence, comparison, and logic tests.
- Change: Split tests into parser/parse_ops_pipe_comma_test.mbt, parser/parse_ops_arithmetic_test.mbt, parser/parse_ops_comparison_test.mbt, and parser/parse_ops_logic_test.mbt.
- Result: Operator parsing tests are grouped by operator class with no behavioral changes.
- Example:
Before: parser/parse_ops_test.mbt housed all operator parsing snapshots together.
After: pipe/comma, arithmetic, comparison, and logic tests live in dedicated files.

## 2026-01-03: Split new feature tests by behavior
- Problem: ast/new_features_test.mbt mixed string, object, iteration, predicate, numeric, and binding cases.
- Change: Moved run_jq into ast/new_features_helpers_test.mbt and split tests into focused files.
- Result: New feature coverage stays the same with clearer grouping.
- Example:
Before: ast/new_features_test.mbt held all new feature tests in one file.
After: ast/new_features_string_test.mbt, ast/new_features_object_test.mbt, ast/new_features_iteration_test.mbt, ast/new_features_predicate_test.mbt, ast/new_features_numeric_test.mbt, ast/new_features_collection_test.mbt, and ast/new_features_binding_test.mbt organize the cases.

## 2026-01-03: Split integration tests by scenario
- Problem: ast/integration_test.mbt mixed helper logic with basic ops, operators, built-ins, control flow, and scenario tests.
- Change: Moved jq into ast/integration_helpers_test.mbt and split tests into focused integration files.
- Result: Integration coverage remains intact with clearer grouping by concern.
- Example:
Before: ast/integration_test.mbt bundled all integration cases in one file.
After: ast/integration_basic_test.mbt, ast/integration_operators_test.mbt, ast/integration_constructs_test.mbt, ast/integration_builtins_test.mbt, ast/integration_control_flow_test.mbt, and ast/integration_scenarios_test.mbt organize the cases.

## 2026-01-03: Extract lexer symbol handling
- Problem: parser/lexer.mbt embedded a large punctuation/operator match in the main lex loop.
- Change: Moved symbol handling into parser/lexer_symbol.mbt and delegated via lex_symbol.
- Result: The main lex loop is shorter with identical tokenization behavior.
- Example:
Before: parser/lexer.mbt matched punctuation and operator cases inline.
After: parser/lexer_symbol.mbt hosts lex_symbol with the same cases.

## 2026-01-03: Consolidate coverage eval helpers
- Problem: Coverage tests repeated nearly identical parse/eval helpers under different names.
- Change: Added ast/coverage_eval_helpers_test.mbt with coverage_eval and routed coverage tests to it.
- Result: Coverage tests share one helper without changing behavior.
- Example:
Before: ast/coverage_extensive_test.mbt defined cov_eval2 and ast/regex_coverage_test.mbt defined regex_eval.
After: both use coverage_eval from ast/coverage_eval_helpers_test.mbt.

## 2026-01-03: Split corner case misc tests by topic
- Problem: ast/corner_cases_misc_test.mbt mixed limit, alternatives, nested transforms, recursion, interpolation, and error handling in one file.
- Change: Split into focused corner case test files by theme.
- Result: Corner case tests are easier to locate without changing coverage.
- Example:
Before: ast/corner_cases_misc_test.mbt bundled all corner case topics.
After: ast/corner_cases_limit_test.mbt, ast/corner_cases_alternative_test.mbt, ast/corner_cases_nested_transform_test.mbt, ast/corner_cases_recursion_test.mbt, ast/corner_cases_interpolation_test.mbt, and ast/corner_cases_error_handling_test.mbt group the cases.

## 2026-01-03: Split conversion and iteration corner cases
- Problem: ast/corner_cases_conversion_iteration_test.mbt mixed string conversion cases with range/iteration behavior.
- Change: Split into ast/corner_cases_conversion_test.mbt and ast/corner_cases_iteration_test.mbt.
- Result: Conversion and iteration edge cases are separated with identical coverage.
- Example:
Before: ast/corner_cases_conversion_iteration_test.mbt housed explode/implode and range/repeat/until in one file.
After: conversion cases live in ast/corner_cases_conversion_test.mbt; iteration cases live in ast/corner_cases_iteration_test.mbt.
