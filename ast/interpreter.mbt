///|
/// Evaluate an expression with input JSON, returns iterator of results
pub fn eval(expr : Expr, input : Json) -> Iter[Json] raise {
  eval_with_env(expr, input, Env::new())
}

///|
/// Evaluate with environment
fn eval_with_env(
  expr : Expr,
  input : Json,
  env : Env,
) -> Iter[Json] raise InterpreterError {
  match expr {
    // Identity returns input as-is
    Identity => Iter::singleton(input)

    // Literals ignore input and return the literal value
    Literal(lit) => Iter::singleton(eval_literal(lit))

    // Pipe: feed results of left into right
    Pipe(left, right) => {
      // Special case: if left is a function definition, update env
      if left is FunctionDef(name, params, body) {
        let new_env = env.set_function(name, body, params)
        return eval_with_env(right, input, new_env)
      }
      let left_results = eval_with_env(left, input, env).collect()
      let right_iters : Array[Iter[Json]] = []
      for v in left_results {
        right_iters.push(eval_with_env(right, v, env))
      }
      right_iters.iter().flatten()
    }

    // Comma: produce multiple outputs
    Comma(left, right) =>
      Iter::concat(
        eval_with_env(left, input, env),
        eval_with_env(right, input, env),
      )

    // Field access
    Key(key) => eval_key_access(key, input)

    // Array indexing and iteration
    Index(indices) => eval_index_access(indices, input)

    // Array slicing
    Slice(start, end) => eval_slice_access(start, end, input)

    // Optional: suppress errors and return empty on failure
    Optional(inner) => eval_optional(inner, input, env)

    // Array construction
    ArrayConstruct(expr_opt) => eval_array_construct(expr_opt, input, env)

    // Object construction
    ObjectConstruct(pairs) => eval_object_construct(pairs, input, env)

    // Binary operations
    Operation(left, op, right) =>
      eval_operation_expr(left, op, right, input, env)

    // Built-in functions
    Length => eval_length(input)
    Keys => eval_keys(input)
    Values => eval_values(input)
    Type => eval_type(input)
    Empty => eval_empty()
    Not => eval_not(input)

    // Array functions
    Map(inner) => eval_map(inner, input, env)
    Select(condition) => eval_select(condition, input, env)
    Sort => eval_sort(input)
    Reverse => eval_reverse(input)
    Flatten(depth_opt) => eval_flatten(depth_opt, input)
    Unique => eval_unique(input)

    // Numeric functions
    Add => eval_add(input)
    Floor => eval_floor(input)
    Sqrt => eval_sqrt(input)
    Min => eval_min(input)
    Max => eval_max(input)

    // Control flow
    IfThenElse(cond, then_expr, else_expr) =>
      eval_if_then_else(cond, then_expr, else_expr, input, env)
    TryCatch(try_expr, catch_opt) =>
      eval_try_catch(try_expr, catch_opt, input, env)

    // Variables
    Variable(name) => eval_variable(name, env)

    // Recursive descent
    Recurse => recurse_all(input)

    // Alternative operator: return left, or right if left produces empty/null
    Alternative(left, right) => eval_alternative(left, right, input, env)

    // Compound assignment operators: path += value
    AddAssign(path, value_expr) =>
      eval_compound_assign(path, Add, value_expr, input, env)
    SubAssign(path, value_expr) =>
      eval_compound_assign(path, Subtract, value_expr, input, env)
    MulAssign(path, value_expr) =>
      eval_compound_assign(path, Multiply, value_expr, input, env)
    DivAssign(path, value_expr) =>
      eval_compound_assign(path, Divide, value_expr, input, env)
    ModAssign(path, value_expr) =>
      eval_compound_assign(path, Modulo, value_expr, input, env)
    AltAssign(path, value_expr) => eval_alt_assign(path, value_expr, input, env)

    // Format functions: @base64, @uri, etc.
    Format(format_name) => eval_format(format_name, input)

    // String interpolation: "text \(expr) more"
    StringInterpolation(parts) => eval_string_interpolation(parts, input, env)

    // Function definition: this is tricky because we need to update env
    // We handle this specially in the Pipe case when left is FunctionDef
    FunctionDef(_name, _params, _body) =>
      // Should not be evaluated directly, only through Pipe
      Iter::singleton(input)

    // Function call: lookup and execute
    FunctionCall(name, args) => eval_function_call(name, args, input, env)

    // As pattern: bind variable and continue with body
    As(expr, var_name, body) => eval_as(expr, var_name, body, input, env)

    // Reduce: aggregate using accumulator
    Reduce(expr, var_name, init_expr, update_expr) =>
      eval_reduce(expr, var_name, init_expr, update_expr, input, env)

    // SortBy: sort array by expression result
    SortBy(expr) => eval_sort_by(expr, input, env)

    // GroupBy: group array elements by expression result
    GroupBy(expr) => eval_group_by(expr, input, env)

    // Update operator: modify value in place
    Update(path, update_expr) => eval_update(path, update_expr, input, env)

    // Assign operator: set value at path
    Assign(path, value_expr) => eval_assign(path, value_expr, input, env)

    // RecurseWith: custom recursion with function
    RecurseWith(f, cond) => eval_recurse_with(f, cond, input, env)

    // Walk: recursively apply function to all values
    Walk(f) => eval_walk(f, input, env)

    // Path expression: get path to a value
    Path(expr) => eval_path(expr)

    // Additional numeric functions
    Round => eval_round(input)
    Ceil => eval_ceil(input)
    Abs => eval_abs(input)

    // String operations
    Split(sep) => eval_split(sep, input)
    Join(sep) => eval_join(sep, input)
    StartsWith(prefix) => eval_starts_with(prefix, input)
    EndsWith(suffix) => eval_ends_with(suffix, input)
    Contains(expr) => eval_contains(expr, input, env)
    Inside(expr) => eval_inside(expr, input, env)

    // Object/Array operations
    Has(key) => eval_has(key, input)
    In(expr) => eval_in(expr, input, env)
    ToEntries => eval_to_entries(input)
    FromEntries => eval_from_entries(input)
    WithEntries(expr) => eval_with_entries(expr, input, env)

    // Iteration helpers
    Range(n) => eval_range(n)
    First => eval_first(input)
    Last => eval_last(input)
    IndicesOf(expr) => eval_indices_of(expr, input, env)
    IndexOf(expr) => eval_index_of(expr, input, env)

    // Predicates
    Any => eval_any(input)
    All => eval_all(input)

    // String trimming
    LTrimStr(prefix) => eval_ltrim_str(prefix, input)
    RTrimStr(suffix) => eval_rtrim_str(suffix, input)
    AsciiUpcase => eval_ascii_upcase(input)
    AsciiDowncase => eval_ascii_downcase(input)

    // Array functions
    Nth(n) => eval_nth(n, input)
    RIndex(search_expr) => eval_rindex(search_expr, input, env)

    // Path functions
    Paths => eval_paths(input)
    LeafPaths => eval_leaf_paths(input)
    GetPath(path_expr) => eval_get_path(path_expr, input, env)
    SetPath(path_expr, value_expr) =>
      eval_set_path(path_expr, value_expr, input, env)
    DelPaths(paths_expr) => eval_del_paths(paths_expr, input, env)

    // Control flow
    Limit(n, expr) => eval_limit(n, expr, input, env)
    Until(cond_expr, update_expr) =>
      eval_until(cond_expr, update_expr, input, env)
    While(cond_expr, update_expr) =>
      eval_while(cond_expr, update_expr, input, env)

    // Math functions
    Pow(exp_expr) => eval_pow(exp_expr, input, env)
    Log => eval_log(input)
    Exp => eval_exp(input)
    Sin => eval_sin(input)
    Cos => eval_cos(input)
    Tan => eval_tan(input)
    Asin => eval_asin(input)
    Acos => eval_acos(input)
    Atan => eval_atan(input)

    // Regex functions (simple implementations)
    Test(pattern) => eval_test(pattern, input)
    Match(pattern) => eval_match(pattern, input)
    Capture(pattern) => eval_capture(pattern, input)
    Splits(pattern) => eval_splits(pattern, input)
    Sub(pattern, replacement) => eval_sub(pattern, replacement, input)
    GSub(pattern, replacement) => eval_gsub(pattern, replacement, input)

    // Newly added features - corner case implementations
    MapValues(expr) => eval_map_values(expr, input, env)
    RangeFromTo(from_expr, to_expr) =>
      eval_range_from_to(from_expr, to_expr, input, env)
    RangeWithStep(from_expr, to_expr, step_expr) =>
      eval_range_with_step(from_expr, to_expr, step_expr, input, env)
    FirstGen(gen_expr) => eval_first_gen(gen_expr, input, env)
    LastGen(gen_expr) => eval_last_gen(gen_expr, input, env)
    Repeat(expr) => eval_repeat(expr, input, env)
    Explode => eval_explode(input)
    Implode => eval_implode(input)
    ToJsonString => eval_to_json_string(input)
    FromJsonString => eval_from_json_string(input)
    UniqueBy(expr) => eval_unique_by(expr, input, env)
    MinBy(expr) => eval_min_by(expr, input, env)
    MaxBy(expr) => eval_max_by(expr, input, env)
    Combinations => eval_combinations(input)
    Transpose => eval_transpose(input)
    AnyGen(gen_expr, cond_expr) => eval_any_gen(gen_expr, cond_expr, input, env)
    AllGen(gen_expr, cond_expr) => eval_all_gen(gen_expr, cond_expr, input, env)
    Foreach(gen_expr, var_name, init_expr, update_expr, extract_expr) =>
      eval_foreach(
        gen_expr, var_name, init_expr, update_expr, extract_expr, input, env,
      )
    PathsWithFilter(filter_expr) =>
      eval_paths_with_filter(filter_expr, input, env)
    Scan(pattern) => eval_scan(pattern, input)
  }
}
