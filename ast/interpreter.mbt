///|
/// Evaluate an expression with input JSON, returns iterator of results
pub fn eval(expr : Expr, input : Json) -> Iterator[Json] raise {
  eval_with_env(expr, input, Env::new())
}

///|
/// Evaluate with environment
fn eval_with_env(
  expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  match expr {
    // Identity returns input as-is
    Identity => Iterator::singleton(input)

    // Literals ignore input and return the literal value
    Literal(lit) => Iterator::singleton(eval_literal(lit))

    // Pipe: feed results of left into right
    Pipe(left, right) => {
      // Special case: if left is a function definition, update env
      match left {
        FunctionDef(name, params, body) => {
          let new_env = env.set_function(name, body, params)
          return eval_with_env(right, input, new_env)
        }
        _ => ()
      }
      let left_results = eval_with_env(left, input, env).collect()
      let right_iters : Array[Iterator[Json]] = []
      for v in left_results {
        right_iters.push(eval_with_env(right, v, env))
      }
      right_iters.iterator().flatten()
    }

    // Comma: produce multiple outputs
    Comma(left, right) =>
      Iterator::concat(
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
    Length => {
      let len = match input {
        Array(arr) => arr.length()
        Object(obj) => obj.length()
        String(s) => s.length()
        Null => 0
        _ => raise TypeMismatch("array/object/string", json_type_name(input))
      }
      Iterator::singleton(Json::number(len.to_double()))
    }
    Keys =>
      match input {
        Object(obj) => {
          let keys : Array[Json] = []
          for k, _v in obj {
            keys.push(Json::string(k))
          }
          Iterator::singleton(Json::array(keys))
        }
        Array(arr) => {
          let indices = arr.mapi((i, _) => Json::number(i.to_double()))
          Iterator::singleton(Json::array(indices))
        }
        _ => raise TypeMismatch("object/array", json_type_name(input))
      }
    Values =>
      match input {
        Object(obj) => {
          let values : Array[Json] = []
          for _k, v in obj {
            values.push(v)
          }
          Iterator::singleton(Json::array(values))
        }
        Array(arr) => Iterator::singleton(Json::array(arr))
        _ => raise TypeMismatch("object/array", json_type_name(input))
      }
    Type => Iterator::singleton(Json::string(json_type_name(input)))
    Empty => Iterator::empty()
    Not => Iterator::singleton(Json::boolean(not(is_truthy(input))))

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
    IfThenElse(cond, then_expr, else_expr) => {
      let cond_results = eval_with_env(cond, input, env).collect()
      if cond_results.is_empty() {
        eval_with_env(else_expr, input, env)
      } else {
        let truthy = is_truthy(cond_results[0])
        if truthy {
          eval_with_env(then_expr, input, env)
        } else {
          eval_with_env(else_expr, input, env)
        }
      }
    }
    TryCatch(try_expr, catch_opt) =>
      eval_with_env(try_expr, input, env) catch {
        _ =>
          match catch_opt {
            Some(catch_expr) => eval_with_env(catch_expr, input, env)
            None => Iterator::empty()
          }
      }

    // Variables
    Variable(name) =>
      match env.get(name) {
        Some(v) => Iterator::singleton(v)
        None => raise InvalidOperation("Undefined variable: $\{name}")
      }

    // Recursive descent
    Recurse => recurse_all(input)

    // Alternative operator: return left, or right if left produces empty/null
    Alternative(left, right) => {
      let left_results = eval_with_env(left, input, env).collect()
      if left_results.is_empty() {
        eval_with_env(right, input, env)
      } else if is_truthy(left_results[0]) {
        left_results.iterator()
      } else {
        eval_with_env(right, input, env)
      }
    }

    // Compound assignment operators: path += value
    AddAssign(path, value_expr) =>
      eval_with_env(
        Update(path, Operation(Identity, Add, value_expr)),
        input,
        env,
      )
    SubAssign(path, value_expr) =>
      eval_with_env(
        Update(path, Operation(Identity, Subtract, value_expr)),
        input,
        env,
      )
    MulAssign(path, value_expr) =>
      eval_with_env(
        Update(path, Operation(Identity, Multiply, value_expr)),
        input,
        env,
      )
    DivAssign(path, value_expr) =>
      eval_with_env(
        Update(path, Operation(Identity, Divide, value_expr)),
        input,
        env,
      )
    ModAssign(path, value_expr) =>
      eval_with_env(
        Update(path, Operation(Identity, Modulo, value_expr)),
        input,
        env,
      )
    AltAssign(path, value_expr) =>
      eval_with_env(Update(path, Alternative(Identity, value_expr)), input, env)

    // Format functions: @base64, @uri, etc.
    Format(format_name) => eval_format(format_name, input)

    // String interpolation: "text \(expr) more"
    StringInterpolation(parts) =>
      eval_string_interpolation(parts, input, env)

    // Function definition: this is tricky because we need to update env
    // We handle this specially in the Pipe case when left is FunctionDef
    FunctionDef(_name, _params, _body) =>
      // Should not be evaluated directly, only through Pipe
      Iterator::singleton(input)

    // Function call: lookup and execute
    FunctionCall(name, args) =>
      match env.get_function(name) {
        Some((body, params)) =>
          if params.is_empty() {
            // Zero-parameter function - just execute with current input
            eval_with_env(body, input, env)
          } else if args.length() != params.length() {
            raise EvalError(
              "Function \{name} expects \{params.length()} arguments, got \{args.length()}",
            )
          } else {
            // Evaluate arguments as expressions against current input
            let arg_values : Array[Json] = []
            for arg in args {
              let results = eval_with_env(arg, input, env).collect()
              arg_values.push(
                if results.is_empty() {
                  null
                } else {
                  results[0]
                },
              )
            }
            // Bind parameters as variables
            let mut new_env = env
            for i = 0; i < params.length(); i = i + 1 {
              new_env = new_env.set(params[i], arg_values[i])
            }
            // Execute function body with original input
            eval_with_env(body, input, new_env)
          }
        None => raise EvalError("Undefined function: \{name}")
      }

    // As pattern: bind variable and continue with body
    As(expr, var_name, body) => {
      // Evaluate expr and bind each result to the variable
      let results = eval_with_env(expr, input, env).collect()
      let all_results : Array[Json] = []
      for result in results {
        let new_env = env.set(var_name, result)
        for val in eval_with_env(body, input, new_env) {
          all_results.push(val)
        }
      }
      all_results.iterator()
    }

    // Reduce: aggregate using accumulator
    Reduce(expr, var_name, init_expr, update_expr) => {
      // Evaluate init expression to get initial accumulator
      let init_results = eval_with_env(init_expr, input, env).collect()
      if init_results.is_empty() {
        return Iterator::singleton(null)
      }
      let mut accumulator = init_results[0]

      // Iterate over expr results and update accumulator
      for item in eval_with_env(expr, input, env) {
        let new_env = env.set(var_name, item)
        let update_results = eval_with_env(update_expr, accumulator, new_env).collect()
        if not(update_results.is_empty()) {
          accumulator = update_results[0]
        }
      }
      Iterator::singleton(accumulator)
    }

    // SortBy: sort array by expression result
    SortBy(expr) =>
      match input {
        Array(arr) => {
          // Create array of (value, sort_key) pairs
          let pairs : Array[(Json, Json)] = []
          for elem in arr {
            let keys = eval_with_env(expr, elem, env).collect()
            let sort_key = if keys.is_empty() { null } else { keys[0] }
            pairs.push((elem, sort_key))
          }
          // Sort by the key
          let sorted_pairs = pairs.copy()
          sorted_pairs.sort_by(fn(a, b) { compare_json(a.1, b.1) })
          // Extract values
          let sorted = sorted_pairs.map(fn(p) { p.0 })
          Iterator::singleton(Json::array(sorted))
        }
        _ => raise TypeMismatch("array", json_type_name(input))
      }

    // GroupBy: group array elements by expression result
    GroupBy(expr) =>
      match input {
        Array(arr) => {
          // Create groups: Map[String, Array[Json]]
          let groups : Map[String, Array[Json]] = {}
          for elem in arr {
            let keys = eval_with_env(expr, elem, env).collect()
            let key_json = if keys.is_empty() { null } else { keys[0] }
            let key_str = key_json.to_string()
            match groups.get(key_str) {
              Some(existing) => {
                existing.push(elem)
                groups[key_str] = existing
              }
              None => groups[key_str] = [elem]
            }
          }
          // Convert groups to array of arrays
          let result : Array[Json] = []
          for group in groups.values() {
            result.push(Json::array(group))
          }
          Iterator::singleton(Json::array(result))
        }
        _ => raise TypeMismatch("array", json_type_name(input))
      }

    // Update operator: modify value in place
    Update(path, update_expr) => {
      // Update value at path: get current value, apply update, set new value
      fn apply_update(
        obj : Json,
        p : Expr,
        upd : Expr,
      ) -> Json raise InterpreterError {
        match p {
          Identity => {
            // Update the whole object
            let results = eval_with_env(upd, obj, env).collect()
            if results.is_empty() {
              obj
            } else {
              results[0]
            }
          }
          Key(key) =>
            // Update at specific key in object
            match obj {
              Object(map) => {
                let current = match map.get(key) {
                  Some(v) => v
                  None => null
                }
                let upd_results = eval_with_env(upd, current, env).collect()
                if upd_results.is_empty() {
                  obj
                } else {
                  let new_map : Map[String, Json] = {}
                  for k, v in map {
                    new_map[k] = v
                  }
                  new_map[key] = upd_results[0]
                  Json::object(new_map)
                }
              }
              _ => obj
            }
          Index(indices) =>
            // Update at specific index in array
            match obj {
              Array(arr) => {
                if indices.is_empty() || indices.length() != 1 {
                  return obj
                }
                let idx = indices[0]
                if idx < 0 || idx >= arr.length() {
                  return obj
                }
                let current = arr[idx]
                let upd_results = eval_with_env(upd, current, env).collect()
                if upd_results.is_empty() {
                  obj
                } else {
                  let new_arr = arr.copy()
                  new_arr[idx] = upd_results[0]
                  Json::array(new_arr)
                }
              }
              _ => obj
            }
          Pipe(left, right) =>
            // Chained path like .a.b: navigate left, update right within result, put back
            match left {
              Identity =>
                // Optimize: . | .b is just .b
                apply_update(obj, right, upd)
              Key(key) =>
                // Navigate to key, update the right path within it
                match obj {
                  Object(map) => {
                    let current = match map.get(key) {
                      Some(v) => v
                      None => null
                    }
                    let updated = apply_update(current, right, upd)
                    let new_map : Map[String, Json] = {}
                    for k, v in map {
                      new_map[k] = v
                    }
                    new_map[key] = updated
                    Json::object(new_map)
                  }
                  _ => obj
                }
              Index(indices) =>
                // Navigate to index, update the right path within it
                match obj {
                  Array(arr) => {
                    if indices.is_empty() || indices.length() != 1 {
                      return obj
                    }
                    let idx = indices[0]
                    if idx < 0 || idx >= arr.length() {
                      return obj
                    }
                    let current = arr[idx]
                    let updated = apply_update(current, right, upd)
                    let new_arr = arr.copy()
                    new_arr[idx] = updated
                    Json::array(new_arr)
                  }
                  _ => obj
                }
              _ => {
                // For complex left paths, navigate and recurse
                let navigated = eval_with_env(left, obj, env).collect()
                if navigated.is_empty() {
                  return obj
                }
                apply_update(navigated[0], right, upd)
              }
            }
          _ => {
            // For other complex paths, fall back to simple replacement
            let current_results = eval_with_env(p, obj, env).collect()
            if current_results.is_empty() {
              return obj
            }
            let current = current_results[0]
            let updated_results = eval_with_env(upd, current, env).collect()
            if updated_results.is_empty() {
              obj
            } else {
              updated_results[0]
            }
          }
        }
      }

      Iterator::singleton(apply_update(input, path, update_expr))
    }

    // Assign operator: set value at path
    Assign(_path, value_expr) => {
      // Evaluate the value expression
      let values = eval_with_env(value_expr, input, env).collect()
      if values.is_empty() {
        Iterator::singleton(input)
      } else {
        Iterator::singleton(values[0])
      }
    }

    // RecurseWith: custom recursion with function
    RecurseWith(f, _cond) => {
      // Simplified: just apply function recursively
      // Full implementation would use condition to stop
      let results : Array[Json] = [input]
      let to_process_ref : Ref[Array[Json]] = Ref::new([input])
      while not(to_process_ref.val.is_empty()) {
        let next_batch : Array[Json] = []
        for item in to_process_ref.val {
          for result in eval_with_env(f, item, env) {
            if result != item { // Avoid infinite loops
              results.push(result)
              next_batch.push(result)
            }
          }
        }
        to_process_ref.val = next_batch
        if to_process_ref.val.length() > 100 { // Safety limit
          break
        }
      }
      results.iterator()
    }

    // Walk: recursively apply function to all values
    Walk(f) => {
      fn walk_value(v : Json) -> Json raise InterpreterError {
        match v {
          Array(arr) => {
            let walked = arr.map(walk_value)
            let wrapped = Json::array(walked)
            let results = eval_with_env(f, wrapped, env).collect()
            if results.is_empty() {
              wrapped
            } else {
              results[0]
            }
          }
          Object(obj) => {
            let walked : Map[String, Json] = {}
            for k, v in obj {
              walked[k] = walk_value(v)
            }
            let wrapped = Json::object(walked)
            let results = eval_with_env(f, wrapped, env).collect()
            if results.is_empty() {
              wrapped
            } else {
              results[0]
            }
          }
          _ => {
            let results = eval_with_env(f, v, env).collect()
            if results.is_empty() {
              v
            } else {
              results[0]
            }
          }
        }
      }

      Iterator::singleton(walk_value(input))
    }

    // Path expression: get path to a value
    Path(_expr) =>
      // Simplified: return empty array for now
      // Full implementation would track paths during evaluation
      Iterator::singleton(Json::array([]))

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
    Any =>
      match input {
        Array(arr) => {
          let mut result = false
          for elem in arr {
            if is_truthy(elem) {
              result = true
              break
            }
          }
          Iterator::singleton(Json::boolean(result))
        }
        _ => raise TypeMismatch("array", json_type_name(input))
      }
    All =>
      match input {
        Array(arr) => {
          let mut result = true
          for elem in arr {
            if not(is_truthy(elem)) {
              result = false
              break
            }
          }
          Iterator::singleton(Json::boolean(result))
        }
        _ => raise TypeMismatch("array", json_type_name(input))
      }

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
    Limit(n, expr) => eval_with_env(expr, input, env).take(n)
    Until(cond_expr, update_expr) => {
      let mut current = input
      while true {
        let cond_results = eval_with_env(cond_expr, current, env).collect()
        if cond_results.is_empty() {
          break
        }
        match cond_results[0] {
          True => break
          _ => {
            let update_results = eval_with_env(update_expr, current, env).collect()
            if update_results.is_empty() {
              break
            }
            current = update_results[0]
          }
        }
      }
      Iterator::singleton(current)
    }
    While(cond_expr, update_expr) => {
      let results : Array[Json] = []
      let mut current = input
      while true {
        let cond_results = eval_with_env(cond_expr, current, env).collect()
        if cond_results.is_empty() {
          break
        }
        if not(is_truthy(cond_results[0])) {
          break
        } else {
          results.push(current)
          let update_results = eval_with_env(update_expr, current, env).collect()
          if update_results.is_empty() {
            break
          }
          current = update_results[0]
        }
      }
      results.iterator()
    }

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
        gen_expr,
        var_name,
        init_expr,
        update_expr,
        extract_expr,
        input,
        env,
      )
    PathsWithFilter(filter_expr) => eval_paths_with_filter(filter_expr, input, env)
    Scan(pattern) => eval_scan(pattern, input)
  }
}
