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
    Map(inner) =>
      match input {
        Array(arr) => {
          let results : Array[Json] = []
          for elem in arr {
            let mapped = eval_with_env(inner, elem, env).collect()
            for v in mapped {
              results.push(v)
            }
          }
          Iterator::singleton(Json::array(results))
        }
        _ => raise TypeMismatch("array", json_type_name(input))
      }
    Select(condition) => {
      let cond_results = eval_with_env(condition, input, env).collect()
      if cond_results.is_empty() {
        Iterator::empty()
      } else {
        let truthy = is_truthy(cond_results[0])
        if truthy {
          Iterator::singleton(input)
        } else {
          Iterator::empty()
        }
      }
    }
    Sort =>
      match input {
        Array(arr) => {
          let sorted = arr.copy()
          sorted.sort_by(compare_json)
          Iterator::singleton(Json::array(sorted))
        }
        _ => raise TypeMismatch("array", json_type_name(input))
      }
    Reverse =>
      match input {
        Array(arr) => {
          let reversed : Array[Json] = []
          for i = arr.length() - 1; i >= 0; i = i - 1 {
            reversed.push(arr[i])
          }
          Iterator::singleton(Json::array(reversed))
        }
        _ => raise TypeMismatch("array", json_type_name(input))
      }
    Flatten(depth_opt) =>
      match input {
        Array(arr) => {
          let depth = match depth_opt {
            Some(d) => d
            None => 999999 // Flatten all levels
          }
          Iterator::singleton(Json::array(flatten_array(arr, depth)))
        }
        _ => raise TypeMismatch("array", json_type_name(input))
      }
    Unique =>
      match input {
        Array(arr) => {
          let sorted = arr.copy()
          sorted.sort_by(compare_json)
          let unique : Array[Json] = []
          let mut prev : Json? = None
          for elem in sorted {
            match prev {
              None => {
                unique.push(elem)
                prev = Some(elem)
              }
              Some(p) =>
                if compare_json(p, elem) != 0 {
                  unique.push(elem)
                  prev = Some(elem)
                }
            }
          }
          Iterator::singleton(Json::array(unique))
        }
        _ => raise TypeMismatch("array", json_type_name(input))
      }

    // Numeric functions
    Add =>
      match input {
        Array(arr) => {
          let mut sum = 0.0
          for elem in arr {
            match elem {
              Number(n, ..) => sum = sum + n
              _ => ()
            }
          }
          Iterator::singleton(Json::number(sum))
        }
        _ => raise TypeMismatch("array", json_type_name(input))
      }
    Floor =>
      match input {
        Number(n, ..) => Iterator::singleton(Json::number(n.floor()))
        _ => raise TypeMismatch("number", json_type_name(input))
      }
    Sqrt =>
      match input {
        Number(n, ..) => Iterator::singleton(Json::number(n.sqrt()))
        _ => raise TypeMismatch("number", json_type_name(input))
      }
    Min =>
      match input {
        Array(arr) =>
          if arr.is_empty() {
            Iterator::singleton(null)
          } else {
            let mut min_val = arr[0]
            for elem in arr {
              if compare_json(elem, min_val) < 0 {
                min_val = elem
              }
            }
            Iterator::singleton(min_val)
          }
        _ => raise TypeMismatch("array", json_type_name(input))
      }
    Max =>
      match input {
        Array(arr) =>
          if arr.is_empty() {
            Iterator::singleton(null)
          } else {
            let mut max_val = arr[0]
            for elem in arr {
              if compare_json(elem, max_val) > 0 {
                max_val = elem
              }
            }
            Iterator::singleton(max_val)
          }
        _ => raise TypeMismatch("array", json_type_name(input))
      }

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
    Round =>
      match input {
        Number(n, ..) => Iterator::singleton(Json::number(n.round()))
        _ => raise TypeMismatch("number", json_type_name(input))
      }
    Ceil =>
      match input {
        Number(n, ..) => Iterator::singleton(Json::number(n.ceil()))
        _ => raise TypeMismatch("number", json_type_name(input))
      }
    Abs =>
      match input {
        Number(n, ..) => Iterator::singleton(Json::number(n.abs()))
        _ => raise TypeMismatch("number", json_type_name(input))
      }

    // String operations
    Split(sep) =>
      match input {
        String(s) => {
          let parts = s.split(sep)
          let json_parts : Array[Json] = []
          for part in parts {
            json_parts.push(Json::string(part.to_string()))
          }
          Iterator::singleton(Json::array(json_parts))
        }
        _ => raise TypeMismatch("string", json_type_name(input))
      }
    Join(sep) =>
      match input {
        Array(arr) => {
          let parts : Array[String] = []
          for elem in arr {
            match elem {
              String(s) => parts.push(s)
              _ => parts.push(elem.to_string())
            }
          }
          Iterator::singleton(Json::string(parts.join(sep)))
        }
        _ => raise TypeMismatch("array", json_type_name(input))
      }
    StartsWith(prefix) =>
      match input {
        String(s) => Iterator::singleton(Json::boolean(s.has_prefix(prefix)))
        _ => raise TypeMismatch("string", json_type_name(input))
      }
    EndsWith(suffix) =>
      match input {
        String(s) => Iterator::singleton(Json::boolean(s.has_suffix(suffix)))
        _ => raise TypeMismatch("string", json_type_name(input))
      }
    Contains(expr) => {
      let needle_results = eval_with_env(expr, input, env).collect()
      if needle_results.is_empty() {
        return Iterator::singleton(Json::boolean(false))
      }
      let needle = needle_results[0]
      match (input, needle) {
        (String(haystack), String(n)) =>
          Iterator::singleton(Json::boolean(haystack.contains(n)))
        (Array(haystack), _) => {
          let mut found = false
          for elem in haystack {
            if elem == needle {
              found = true
              break
            }
          }
          Iterator::singleton(Json::boolean(found))
        }
        (Object(haystack), String(key)) =>
          Iterator::singleton(Json::boolean(haystack.contains(key)))
        _ => Iterator::singleton(Json::boolean(false))
      }
    }
    Inside(expr) => {
      // inside checks if input is a subset of container
      let container_results = eval_with_env(expr, input, env).collect()
      if container_results.is_empty() {
        return Iterator::singleton(Json::boolean(false))
      }
      let container = container_results[0]
      match (input, container) {
        (String(needle), String(haystack)) =>
          Iterator::singleton(Json::boolean(haystack.contains(needle)))
        (Array(needle_arr), Array(haystack)) => {
          // Check if all elements of needle_arr exist in haystack
          let mut all_found = true
          for needle_elem in needle_arr {
            let mut found = false
            for haystack_elem in haystack {
              if haystack_elem == needle_elem {
                found = true
                break
              }
            }
            if not(found) {
              all_found = false
              break
            }
          }
          Iterator::singleton(Json::boolean(all_found))
        }
        (String(key), Object(haystack)) =>
          Iterator::singleton(Json::boolean(haystack.contains(key)))
        _ => Iterator::singleton(Json::boolean(false))
      }
    }

    // Object/Array operations
    Has(key) =>
      match input {
        Object(obj) => Iterator::singleton(Json::boolean(obj.contains(key)))
        Array(arr) => {
          // For arrays, treat key as index
          let idx_result = @strconv.parse_int(key) catch {
            _ => return Iterator::singleton(Json::boolean(false))
          }
          let len = arr.length()
          let actual_idx = if idx_result < 0 {
            len + idx_result
          } else {
            idx_result
          }
          Iterator::singleton(
            Json::boolean(actual_idx >= 0 && actual_idx < len),
          )
        }
        _ => Iterator::singleton(Json::boolean(false))
      }
    In(expr) => {
      let container_results = eval_with_env(expr, input, env).collect()
      if container_results.is_empty() {
        return Iterator::singleton(Json::boolean(false))
      }
      match container_results[0] {
        Object(obj) =>
          match input {
            String(key) => Iterator::singleton(Json::boolean(obj.contains(key)))
            _ => Iterator::singleton(Json::boolean(false))
          }
        Array(arr) =>
          match input {
            Number(n, ..) => {
              let idx = n.to_int()
              let len = arr.length()
              let actual_idx = if idx < 0 { len + idx } else { idx }
              Iterator::singleton(
                Json::boolean(actual_idx >= 0 && actual_idx < len),
              )
            }
            _ => Iterator::singleton(Json::boolean(false))
          }
        _ => Iterator::singleton(Json::boolean(false))
      }
    }
    ToEntries =>
      match input {
        Object(obj) => {
          let entries : Array[Json] = []
          for k, v in obj {
            let entry : Map[String, Json] = {}
            entry["key"] = Json::string(k)
            entry["value"] = v
            entries.push(Json::object(entry))
          }
          Iterator::singleton(Json::array(entries))
        }
        Array(arr) => {
          let entries : Array[Json] = []
          for i = 0; i < arr.length(); i = i + 1 {
            let entry : Map[String, Json] = {}
            entry["key"] = Json::number(i.to_double())
            entry["value"] = arr[i]
            entries.push(Json::object(entry))
          }
          Iterator::singleton(Json::array(entries))
        }
        _ => raise TypeMismatch("object/array", json_type_name(input))
      }
    FromEntries =>
      match input {
        Array(arr) => {
          let result : Map[String, Json] = {}
          for entry in arr {
            match entry {
              Object(obj) => {
                let key_opt = match obj.get("key") {
                  Some(k) => Some(k)
                  None => obj.get("name")
                }
                let value_opt = obj.get("value")
                match key_opt {
                  Some(k) =>
                    match k {
                      String(key_str) =>
                        match value_opt {
                          Some(v) => result[key_str] = v
                          None => ()
                        }
                      Number(n, ..) =>
                        match value_opt {
                          Some(v) => result[n.to_int().to_string()] = v
                          None => ()
                        }
                      _ => ()
                    }
                  _ => ()
                }
              }
              _ => ()
            }
          }
          Iterator::singleton(Json::object(result))
        }
        _ => raise TypeMismatch("array", json_type_name(input))
      }
    WithEntries(expr) =>
      // Convert to entries, apply expr to each entry, convert back
      match input {
        Object(_) | Array(_) => {
          // to_entries
          let entries_results = eval_with_env(ToEntries, input, env).collect()
          // Apply expression to each entry (like map)
          let entries_array = entries_results[0]
          let mapped_results = eval_with_env(Map(expr), entries_array, env).collect()
          // from_entries
          eval_with_env(FromEntries, mapped_results[0], env)
        }
        _ => raise TypeMismatch("object/array", json_type_name(input))
      }

    // Iteration helpers
    Range(n) => {
      let results : Array[Json] = []
      for i = 0; i < n; i = i + 1 {
        results.push(Json::number(i.to_double()))
      }
      results.iterator()
    }
    First =>
      match input {
        Array(arr) =>
          if arr.is_empty() {
            Iterator::empty()
          } else {
            Iterator::singleton(arr[0])
          }
        _ => raise TypeMismatch("array", json_type_name(input))
      }
    Last =>
      match input {
        Array(arr) =>
          if arr.is_empty() {
            Iterator::empty()
          } else {
            Iterator::singleton(arr[arr.length() - 1])
          }
        _ => raise TypeMismatch("array", json_type_name(input))
      }
    IndicesOf(expr) => {
      let needle_results = eval_with_env(expr, input, env).collect()
      if needle_results.is_empty() {
        return Iterator::singleton(Json::array([]))
      }
      let needle = needle_results[0]
      match input {
        Array(arr) => {
          let indices : Array[Json] = []
          for i = 0; i < arr.length(); i = i + 1 {
            if arr[i] == needle {
              indices.push(Json::number(i.to_double()))
            }
          }
          Iterator::singleton(Json::array(indices))
        }
        String(s) =>
          match needle {
            String(substr) => {
              let indices : Array[Json] = []
              // Simplified: just check if substring exists
              if s.contains(substr) {
                // Finding all occurrences in a string view is complex
                // For now, return empty array
                ()
              }
              Iterator::singleton(Json::array(indices))
            }
            _ => Iterator::singleton(Json::array([]))
          }
        _ => raise TypeMismatch("array/string", json_type_name(input))
      }
    }
    IndexOf(expr) => {
      let needle_results = eval_with_env(expr, input, env).collect()
      if needle_results.is_empty() {
        return Iterator::singleton(null)
      }
      let needle = needle_results[0]
      match input {
        Array(arr) => {
          let mut found_idx : Int? = None
          for i = 0; i < arr.length(); i = i + 1 {
            if arr[i] == needle {
              found_idx = Some(i)
              break
            }
          }
          match found_idx {
            Some(idx) => Iterator::singleton(Json::number(idx.to_double()))
            None => Iterator::singleton(null)
          }
        }
        String(s) =>
          match needle {
            String(substr) =>
              // Finding index in string requires searching
              // For now, check if contains and return 0 or null
              if s.contains(substr) {
                Iterator::singleton(Json::number(0.0))
              } else {
                Iterator::singleton(null)
              }
            _ => Iterator::singleton(null)
          }
        _ => raise TypeMismatch("array/string", json_type_name(input))
      }
    }

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
    LTrimStr(prefix) =>
      match input {
        String(s) =>
          match s.strip_prefix(prefix[:]) {
            Some(rest) => Iterator::singleton(Json::string(rest.to_string()))
            None => Iterator::singleton(input)
          }
        _ => raise TypeMismatch("string", json_type_name(input))
      }
    RTrimStr(suffix) =>
      match input {
        String(s) =>
          match s.strip_suffix(suffix[:]) {
            Some(rest) => Iterator::singleton(Json::string(rest.to_string()))
            None => Iterator::singleton(input)
          }
        _ => raise TypeMismatch("string", json_type_name(input))
      }
    AsciiUpcase =>
      match input {
        String(s) => {
          let result = @buffer.new()
          for ch in s {
            if ch >= 'a' && ch <= 'z' {
              result.write_char(Int::unsafe_to_char(ch.to_int() - 32))
            } else {
              result.write_char(ch)
            }
          }
          Iterator::singleton(Json::string(result.to_string()))
        }
        _ => raise TypeMismatch("string", json_type_name(input))
      }
    AsciiDowncase =>
      match input {
        String(s) => {
          let result = @buffer.new()
          for ch in s {
            if ch >= 'A' && ch <= 'Z' {
              result.write_char(Int::unsafe_to_char(ch.to_int() + 32))
            } else {
              result.write_char(ch)
            }
          }
          Iterator::singleton(Json::string(result.to_string()))
        }
        _ => raise TypeMismatch("string", json_type_name(input))
      }

    // Array functions
    Nth(n) =>
      match input {
        Array(arr) =>
          if n >= 0 && n < arr.length() {
            Iterator::singleton(arr[n])
          } else if n < 0 && -n <= arr.length() {
            Iterator::singleton(arr[arr.length() + n])
          } else {
            Iterator::empty()
          }
        _ => raise TypeMismatch("array", json_type_name(input))
      }
    RIndex(search_expr) => {
      let needle_results = eval_with_env(search_expr, input, env).collect()
      if needle_results.is_empty() {
        return Iterator::singleton(null)
      }
      let needle = needle_results[0]
      match input {
        Array(arr) => {
          let mut last_index : Int? = None
          for i = 0; i < arr.length(); i = i + 1 {
            if arr[i] == needle {
              last_index = Some(i)
            }
          }
          match last_index {
            Some(idx) => Iterator::singleton(Json::number(idx.to_double()))
            None => Iterator::singleton(null)
          }
        }
        String(s) =>
          match needle {
            String(substr) =>
              match s.rev_find(substr[:]) {
                Some(pos) => Iterator::singleton(Json::number(pos.to_double()))
                None => Iterator::singleton(null)
              }
            _ => Iterator::singleton(null)
          }
        _ => raise TypeMismatch("array or string", json_type_name(input))
      }
    }

    // Path functions
    Paths => {
      let paths_list : Array[Json] = []
      fn collect_paths(value : Json, path : Array[Json]) {
        match value {
          Object(obj) =>
            for key, val in obj {
              let new_path = path + [Json::string(key)]
              paths_list.push(Json::array(new_path))
              collect_paths(val, new_path)
            }
          Array(arr) =>
            for i = 0; i < arr.length(); i = i + 1 {
              let new_path = path + [Json::number(i.to_double())]
              paths_list.push(Json::array(new_path))
              collect_paths(arr[i], new_path)
            }
          _ => ()
        }
      }

      collect_paths(input, [])
      paths_list.iterator()
    }
    LeafPaths => {
      let paths_list : Array[Json] = []
      fn collect_leaf_paths(value : Json, path : Array[Json]) {
        match value {
          Object(obj) =>
            if obj.is_empty() {
              paths_list.push(Json::array(path))
            } else {
              for key, val in obj {
                collect_leaf_paths(val, path + [Json::string(key)])
              }
            }
          Array(arr) =>
            if arr.is_empty() {
              paths_list.push(Json::array(path))
            } else {
              for i = 0; i < arr.length(); i = i + 1 {
                collect_leaf_paths(arr[i], path + [Json::number(i.to_double())])
              }
            }
          _ => paths_list.push(Json::array(path))
        }
      }

      collect_leaf_paths(input, [])
      paths_list.iterator()
    }
    GetPath(path_expr) => {
      let path_results = eval_with_env(path_expr, input, env).collect()
      if path_results.is_empty() {
        return Iterator::singleton(null)
      }
      match path_results[0] {
        Array(path_arr) => {
          let mut current = input
          for segment in path_arr {
            match (current, segment) {
              (Object(obj), String(key)) =>
                match obj.get(key) {
                  Some(v) => current = v
                  None => return Iterator::singleton(null)
                }
              (Array(arr), Number(idx, ..)) => {
                let i = idx.to_int()
                if i >= 0 && i < arr.length() {
                  current = arr[i]
                } else {
                  return Iterator::singleton(null)
                }
              }
              _ => return Iterator::singleton(null)
            }
          }
          Iterator::singleton(current)
        }
        _ => Iterator::singleton(null)
      }
    }
    SetPath(path_expr, value_expr) => {
      let path_results = eval_with_env(path_expr, input, env).collect()
      let value_results = eval_with_env(value_expr, input, env).collect()
      if path_results.is_empty() || value_results.is_empty() {
        return Iterator::singleton(input)
      }
      match path_results[0] {
        Array(path_arr) =>
          if path_arr.is_empty() {
            Iterator::singleton(value_results[0])
          } else {
            Iterator::singleton(set_at_path(input, path_arr, value_results[0]))
          }
        _ => Iterator::singleton(input)
      }
    }
    DelPaths(paths_expr) => {
      let paths_results = eval_with_env(paths_expr, input, env).collect()
      if paths_results.is_empty() {
        return Iterator::singleton(input)
      }
      match paths_results[0] {
        Array(paths_arr) => {
          let mut result = input
          for path_json in paths_arr {
            match path_json {
              Array(path) => result = delete_at_path(result, path)
              _ => ()
            }
          }
          Iterator::singleton(result)
        }
        _ => Iterator::singleton(input)
      }
    }

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
    Pow(exp_expr) => {
      let exp_results = eval_with_env(exp_expr, input, env).collect()
      if exp_results.is_empty() {
        return Iterator::singleton(null)
      }
      match (input, exp_results[0]) {
        (Number(base, ..), Number(exp, ..)) =>
          Iterator::singleton(Json::number(@math.pow(base, exp)))
        _ => raise TypeMismatch("number", json_type_name(input))
      }
    }
    Log =>
      match input {
        Number(n, ..) => Iterator::singleton(Json::number(@math.ln(n)))
        _ => raise TypeMismatch("number", json_type_name(input))
      }
    Exp =>
      match input {
        Number(n, ..) => Iterator::singleton(Json::number(@math.exp(n)))
        _ => raise TypeMismatch("number", json_type_name(input))
      }
    Sin =>
      match input {
        Number(n, ..) => Iterator::singleton(Json::number(@math.sin(n)))
        _ => raise TypeMismatch("number", json_type_name(input))
      }
    Cos =>
      match input {
        Number(n, ..) => Iterator::singleton(Json::number(@math.cos(n)))
        _ => raise TypeMismatch("number", json_type_name(input))
      }
    Tan =>
      match input {
        Number(n, ..) => Iterator::singleton(Json::number(@math.tan(n)))
        _ => raise TypeMismatch("number", json_type_name(input))
      }
    Asin =>
      match input {
        Number(n, ..) => Iterator::singleton(Json::number(@math.asin(n)))
        _ => raise TypeMismatch("number", json_type_name(input))
      }
    Acos =>
      match input {
        Number(n, ..) => Iterator::singleton(Json::number(@math.acos(n)))
        _ => raise TypeMismatch("number", json_type_name(input))
      }
    Atan =>
      match input {
        Number(n, ..) => Iterator::singleton(Json::number(@math.atan(n)))
        _ => raise TypeMismatch("number", json_type_name(input))
      }

    // Regex functions (simple implementations)
    Test(pattern) =>
      match input {
        String(s) => Iterator::singleton(Json::boolean(s.contains(pattern)))
        _ => raise TypeMismatch("string", json_type_name(input))
      }
    Match(pattern) =>
      match input {
        String(s) =>
          if s.contains(pattern) {
            Iterator::singleton(
              Json::object(
                Map::from_array([
                  ("match", Json::string(pattern)),
                  ("offset", Json::number(0.0)),
                  ("length", Json::number(pattern.length().to_double())),
                  ("string", Json::string(s)),
                  ("captures", Json::array([])),
                ]),
              ),
            )
          } else {
            Iterator::empty()
          }
        _ => raise TypeMismatch("string", json_type_name(input))
      }
    Capture(_pattern) =>
      match input {
        String(_s) => Iterator::singleton(Json::object(Map::from_array([])))
        _ => raise TypeMismatch("string", json_type_name(input))
      }
    Splits(pattern) =>
      match input {
        String(s) => {
          let parts = s.split(pattern).collect()
          parts.iterator().map(part => Json::string(part.to_string()))
        }
        _ => raise TypeMismatch("string", json_type_name(input))
      }
    Sub(pattern, replacement) =>
      match input {
        String(s) =>
          Iterator::singleton(
            Json::string(s.replace(old=pattern[:], new=replacement[:])),
          )
        _ => raise TypeMismatch("string", json_type_name(input))
      }
    GSub(pattern, replacement) =>
      match input {
        String(s) =>
          Iterator::singleton(
            Json::string(s.replace_all(old=pattern[:], new=replacement[:])),
          )
        _ => raise TypeMismatch("string", json_type_name(input))
      }

    // Newly added features - corner case implementations
    MapValues(expr) =>
      match input {
        Object(obj) => {
          let result : Map[String, Json] = {}
          for key, value in obj {
            let transformed_results = eval_with_env(expr, value, env).collect()
            if not(transformed_results.is_empty()) {
              result[key] = transformed_results[0]
            }
          }
          Iterator::singleton(Json::object(result))
        }
        _ => raise TypeMismatch("object", json_type_name(input))
      }
    RangeFromTo(from_expr, to_expr) => {
      let from_results = eval_with_env(from_expr, input, env).collect()
      let to_results = eval_with_env(to_expr, input, env).collect()
      if from_results.is_empty() || to_results.is_empty() {
        return Iterator::empty()
      }
      match (from_results[0], to_results[0]) {
        (Number(from_num, ..), Number(to_num, ..)) => {
          let from_int = from_num.to_int()
          let to_int = to_num.to_int()
          let results : Array[Json] = []
          for i = from_int; i < to_int; i = i + 1 {
            results.push(Json::number(i.to_double()))
          }
          results.iterator()
        }
        _ => raise TypeMismatch("numbers", "non-numbers")
      }
    }
    RangeWithStep(from_expr, to_expr, step_expr) => {
      let from_results = eval_with_env(from_expr, input, env).collect()
      let to_results = eval_with_env(to_expr, input, env).collect()
      let step_results = eval_with_env(step_expr, input, env).collect()
      if from_results.is_empty() ||
        to_results.is_empty() ||
        step_results.is_empty() {
        return Iterator::empty()
      }
      match (from_results[0], to_results[0], step_results[0]) {
        (Number(from_num, ..), Number(to_num, ..), Number(step_num, ..)) => {
          let from_int = from_num.to_int()
          let to_int = to_num.to_int()
          let step_int = step_num.to_int()
          let results : Array[Json] = []
          if step_int > 0 {
            let mut i = from_int
            while i < to_int {
              results.push(Json::number(i.to_double()))
              i = i + step_int
            }
          } else if step_int < 0 {
            let mut i = from_int
            while i > to_int {
              results.push(Json::number(i.to_double()))
              i = i + step_int
            }
          }
          results.iterator()
        }
        _ => raise TypeMismatch("numbers", "non-numbers")
      }
    }
    FirstGen(gen_expr) => {
      let gen_results = eval_with_env(gen_expr, input, env).collect()
      if gen_results.is_empty() {
        Iterator::empty()
      } else {
        Iterator::singleton(gen_results[0])
      }
    }
    LastGen(gen_expr) => {
      let gen_results = eval_with_env(gen_expr, input, env).collect()
      if gen_results.is_empty() {
        Iterator::empty()
      } else {
        Iterator::singleton(gen_results[gen_results.length() - 1])
      }
    }
    Repeat(expr) => {
      // Repeat yields values infinitely - should be used with limit()
      let values = eval_with_env(expr, input, env).collect()
      if values.is_empty() {
        return Iterator::empty()
      }
      let mut i = 0
      Iterator::new(fn() {
        let result = Some(values[i])
        i += 1
        if i >= values.length() {
          i = 0
        }
        result
      })
    }
    Explode =>
      match input {
        String(s) => {
          let results : Array[Json] = []
          for char in s {
            results.push(Json::number(char.to_int().to_double()))
          }
          Iterator::singleton(Json::array(results))
        }
        _ => raise TypeMismatch("string", json_type_name(input))
      }
    Implode =>
      match input {
        Array(arr) => {
          let buffer = @buffer.new()
          for elem in arr {
            match elem {
              Number(n, ..) => {
                let code = n.to_int()
                match Int::to_char(code) {
                  Some(c) => buffer.write_char(c)
                  None => ()
                }
              }
              _ => ()
            }
          }
          Iterator::singleton(Json::string(buffer.to_string()))
        }
        _ => raise TypeMismatch("array", json_type_name(input))
      }
    ToJsonString => Iterator::singleton(Json::string(input.to_string()))
    FromJsonString =>
      match input {
        String(s) => {
          let parsed = @json.parse(s) catch {
            e => raise InvalidOperation("JSON parse error: \{e}")
          }
          Iterator::singleton(parsed)
        }
        _ => raise TypeMismatch("string", json_type_name(input))
      }
    UniqueBy(expr) =>
      match input {
        Array(arr) => {
          let seen : Map[String, Bool] = {}
          let results : Array[Json] = []
          for elem in arr {
            let key_results = eval_with_env(expr, elem, env).collect()
            if not(key_results.is_empty()) {
              let key = key_results[0].to_string()
              if not(seen.contains(key)) {
                seen[key] = true
                results.push(elem)
              }
            }
          }
          Iterator::singleton(Json::array(results))
        }
        _ => raise TypeMismatch("array", json_type_name(input))
      }
    MinBy(expr) =>
      match input {
        Array(arr) =>
          if arr.is_empty() {
            Iterator::singleton(null)
          } else {
            let mut min_elem : Json = arr[0]
            let min_val_results = eval_with_env(expr, min_elem, env).collect()
            if min_val_results.is_empty() {
              return Iterator::singleton(null)
            }
            let mut min_val = min_val_results[0]
            for i = 1; i < arr.length(); i = i + 1 {
              let elem = arr[i]
              let val_results = eval_with_env(expr, elem, env).collect()
              if not(val_results.is_empty()) {
                let val = val_results[0]
                if compare_json(val, min_val) < 0 {
                  min_val = val
                  min_elem = elem
                }
              }
            }
            Iterator::singleton(min_elem)
          }
        _ => raise TypeMismatch("array", json_type_name(input))
      }
    MaxBy(expr) =>
      match input {
        Array(arr) =>
          if arr.is_empty() {
            Iterator::singleton(null)
          } else {
            let mut max_elem : Json = arr[0]
            let max_val_results = eval_with_env(expr, max_elem, env).collect()
            if max_val_results.is_empty() {
              return Iterator::singleton(null)
            }
            let mut max_val = max_val_results[0]
            for i = 1; i < arr.length(); i = i + 1 {
              let elem = arr[i]
              let val_results = eval_with_env(expr, elem, env).collect()
              if not(val_results.is_empty()) {
                let val = val_results[0]
                if compare_json(val, max_val) > 0 {
                  max_val = val
                  max_elem = elem
                }
              }
            }
            Iterator::singleton(max_elem)
          }
        _ => raise TypeMismatch("array", json_type_name(input))
      }
    Combinations =>
      match input {
        Array(arr) => {
          let arrays : Array[Array[Json]] = []
          for elem in arr {
            match elem {
              Array(inner) => arrays.push(inner)
              _ => return Iterator::empty()
            }
          }
          if arrays.is_empty() {
            return Iterator::empty()
          }
          // Generate cartesian product
          let mut results : Array[Array[Json]] = [[]]
          for arr_item in arrays {
            let new_results : Array[Array[Json]] = []
            for res in results {
              for item in arr_item {
                let new_res = res.copy()
                new_res.push(item)
                new_results.push(new_res)
              }
            }
            results = new_results
          }
          results.iterator().map(Json::array)
        }
        _ => raise TypeMismatch("array", json_type_name(input))
      }
    Transpose =>
      match input {
        Array(arr) => {
          let mut max_len = 0
          for elem in arr {
            match elem {
              Array(inner) =>
                if inner.length() > max_len {
                  max_len = inner.length()
                }
              _ => ()
            }
          }
          let results : Array[Array[Json]] = []
          for col = 0; col < max_len; col = col + 1 {
            let row : Array[Json] = []
            for elem in arr {
              match elem {
                Array(inner) => if col < inner.length() { row.push(inner[col]) }
                _ => ()
              }
            }
            results.push(row)
          }
          Iterator::singleton(Json::array(results.map(Json::array)))
        }
        _ => raise TypeMismatch("array", json_type_name(input))
      }
    AnyGen(gen_expr, cond_expr) => {
      let gen_results = eval_with_env(gen_expr, input, env).collect()
      let mut found = false
      for gen_result in gen_results {
        let cond_results = eval_with_env(cond_expr, gen_result, env).collect()
        if not(cond_results.is_empty()) {
          match cond_results[0] {
            True => {
              found = true
              break
            }
            _ => ()
          }
        }
      }
      Iterator::singleton(Json::boolean(found))
    }
    AllGen(gen_expr, cond_expr) => {
      let gen_results = eval_with_env(gen_expr, input, env).collect()
      let mut all_true = true
      for gen_result in gen_results {
        let cond_results = eval_with_env(cond_expr, gen_result, env).collect()
        if not(cond_results.is_empty()) {
          match cond_results[0] {
            True => ()
            _ => {
              all_true = false
              break
            }
          }
        } else {
          all_true = false
          break
        }
      }
      Iterator::singleton(Json::boolean(all_true))
    }
    Foreach(gen_expr, var_name, init_expr, update_expr, extract_expr) => {
      let gen_results = eval_with_env(gen_expr, input, env).collect()
      let init_results = eval_with_env(init_expr, input, env).collect()
      if init_results.is_empty() {
        return Iterator::empty()
      }
      let mut accumulator = init_results[0]
      let results : Array[Json] = []
      for gen_result in gen_results {
        let mut new_env = Env::new()
        for key, value in env.bindings {
          new_env = new_env.set(key, value)
        }
        for key, value in env.functions {
          new_env = new_env.set_function(key, value.0, value.1)
        }
        new_env = new_env.set(var_name, gen_result)
        let update_results = eval_with_env(update_expr, accumulator, new_env).collect()
        if not(update_results.is_empty()) {
          accumulator = update_results[0]
          let output = match extract_expr {
            Some(extract) => {
              let extract_results = eval_with_env(extract, accumulator, new_env).collect()
              if extract_results.is_empty() {
                accumulator
              } else {
                extract_results[0]
              }
            }
            None => accumulator
          }
          results.push(output)
        }
      }
      results.iterator()
    }
    PathsWithFilter(filter_expr) => {
      let results : Array[Array[String]] = []
      collect_paths_with_filter(input, [], filter_expr, env, results)
      results.iterator().map(path => Json::array(path.map(Json::string)))
    }
    Scan(pattern) =>
      match input {
        String(s) => {
          let results : Array[Json] = []
          let slen = s.length()
          let plen = pattern.length()
          let mut i = 0
          while i <= slen - plen {
            let slice_result = s[i:i + plen] catch {
              _ => {
                i = i + 1
                continue
              }
            }
            if slice_result.to_string() == pattern {
              results.push(Json::string(pattern))
              i = i + plen
            } else {
              i = i + 1
            }
          }
          results.iterator()
        }
        _ => raise TypeMismatch("string", json_type_name(input))
      }
  }
}
