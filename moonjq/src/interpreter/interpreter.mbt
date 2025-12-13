///|
/// Interpreter error types
pub(all) suberror InterpreterError {
  TypeMismatch(String, String) // (expected, got)
  KeyNotFound(String)
  IndexOutOfBounds(Int)
  InvalidOperation(String)
  DivisionByZero
} derive(Eq, Show)

///|
/// Environment for variable bindings
struct Env {
  bindings : Map[String, Json]
}

///|
fn Env::new() -> Env {
  { bindings: {} }
}

///|
fn Env::get(self : Env, name : String) -> Json? {
  self.bindings.get(name)
}

///|
fn Env::set(self : Env, name : String, value : Json) -> Env {
  let new_bindings = self.bindings
  new_bindings[name] = value
  { bindings: new_bindings }
}

///|
/// Evaluate an expression with input JSON, returns iterator of results
pub fn eval(expr : @ast.Expr, input : Json) -> Iter[Json] raise {
  eval_with_env(expr, input, Env::new())
}

///|
/// Evaluate with environment
fn eval_with_env(
  expr : @ast.Expr,
  input : Json,
  env : Env,
) -> Iter[Json] raise InterpreterError {
  match expr {
    // Identity returns input as-is
    @ast.Expr::Identity => Iter::singleton(input)

    // Literals ignore input and return the literal value
    @ast.Expr::Literal(lit) => Iter::singleton(eval_literal(lit))

    // Pipe: feed results of left into right
    @ast.Expr::Pipe(left, right) => {
      let left_results = eval_with_env(left, input, env).collect()
      let mut all_results : Array[Json] = []
      for val in left_results {
        let right_results = eval_with_env(right, val, env).collect()
        all_results = all_results + right_results
      }
      Iter::new(fn(emit) {
        for x in all_results {
          if emit(x) == IterEnd {
            break
          }
        }
        IterContinue
      })
    }

    // Comma: produce multiple outputs
    @ast.Expr::Comma(left, right) =>
      Iter::concat(
        eval_with_env(left, input, env),
        eval_with_env(right, input, env),
      )

    // Field access
    @ast.Expr::Key(key) =>
      match input {
        Object(obj) =>
          match obj.get(key) {
            Some(v) => Iter::singleton(v)
            None => Iter::singleton(Json::null())
          }
        _ => Iter::singleton(Json::null())
      }

    // Array indexing and iteration
    @ast.Expr::Index(indices) =>
      if indices.is_empty() {
        // Empty index means iterate over array/object values
        match input {
          Array(arr) =>
            Iter::new(fn(emit) {
              for x in arr {
                if emit(x) == IterEnd {
                  break
                }
              }
              IterContinue
            })
          Object(obj) => {
            let mut values : Array[Json] = []
            for _k, v in obj {
              values = values + [v]
            }
            Iter::new(fn(emit) {
              for x in values {
                if emit(x) == IterEnd {
                  break
                }
              }
              IterContinue
            })
          }
          _ => Iter::empty()
        }
      } else {
        // Multiple indices produce multiple results
        Iter::new(fn(emit) {
          for x in indices {
            if emit(x) == IterEnd {
              break
            }
          }
          IterContinue
        }).map(fn(idx) {
          match input {
            Array(arr) => {
              let i = if idx < 0 { arr.length() + idx } else { idx }
              if i >= 0 && i < arr.length() {
                arr[i]
              } else {
                Json::null()
              }
            }
            _ => Json::null()
          }
        })
      }

    // Array slicing
    @ast.Expr::Slice(start, end) =>
      match input {
        Array(arr) => {
          let len = arr.length()
          let s = match start {
            Some(n) => if n < 0 { len + n } else { n }
            None => 0
          }
          let e = match end {
            Some(n) => if n < 0 { len + n } else { n }
            None => len
          }
          let mut result : Array[Json] = []
          for i = s; i < e && i < len; i = i + 1 {
            if i >= 0 {
              result = result + [arr[i]]
            }
          }
          Iter::singleton(Json::array(result))
        }
        _ => Iter::singleton(Json::null())
      }

    // Optional: suppress errors and return empty on failure
    @ast.Expr::Optional(inner) =>
      eval_with_env(inner, input, env) catch {
        _ => Iter::empty()
      }

    // Array construction
    @ast.Expr::ArrayConstruct(expr_opt) =>
      match expr_opt {
        None => Iter::singleton(Json::array([]))
        Some(e) => {
          let results = eval_with_env(e, input, env).collect()
          Iter::singleton(Json::array(results))
        }
      }

    // Object construction
    @ast.Expr::ObjectConstruct(pairs) => {
      let obj : Map[String, Json] = {}
      for pair in pairs {
        let (key_expr, value_expr_opt) = pair
        // Evaluate key to get string
        let key_results = eval_with_env(key_expr, input, env).collect()
        if key_results.is_empty() {
          continue
        }
        let key_str = match key_results[0] {
          String(s) => s
          _ =>
            raise InterpreterError::TypeMismatch(
              "string",
              @json.type_name(key_results[0]),
            )
        }

        // Evaluate value or use key from input
        let value = match value_expr_opt {
          Some(value_expr) => {
            let value_results = eval_with_env(value_expr, input, env).collect()
            if value_results.is_empty() {
              Json::null()
            } else {
              value_results[0]
            }
          }
          None =>
            // Shorthand: {foo} means {foo: .foo}
            match input {
              Object(input_obj) =>
                match input_obj.get(key_str) {
                  Some(v) => v
                  None => Json::null()
                }
              _ => Json::null()
            }
        }
        obj[key_str] = value
      }
      Iter::singleton(Json::object(obj))
    }

    // Binary operations
    @ast.Expr::Operation(left, op, right) => {
      let left_results = eval_with_env(left, input, env).collect()
      let right_results = eval_with_env(right, input, env).collect()
      let mut all_results : Array[Json] = []
      for left_val in left_results {
        for right_val in right_results {
          all_results = all_results + [eval_binary_op(op, left_val, right_val)]
        }
      }
      Iter::new(fn(emit) {
        for x in all_results {
          if emit(x) == IterEnd {
            break
          }
        }
        IterContinue
      })
    }

    // Built-in functions
    @ast.Expr::Length => {
      let len = match input {
        Array(arr) => arr.length()
        Object(obj) => obj.length()
        String(s) => s.length()
        Null => 0
        _ =>
          raise InterpreterError::TypeMismatch(
            "array/object/string",
            @json.type_name(input),
          )
      }
      Iter::singleton(Json::number(len.to_double()))
    }
    @ast.Expr::Keys =>
      match input {
        Object(obj) => {
          let mut keys : Array[Json] = []
          for k, _v in obj {
            keys = keys + [Json::string(k)]
          }
          Iter::singleton(Json::array(keys))
        }
        Array(arr) => {
          let mut indices : Array[Json] = []
          for i = 0; i < arr.length(); i = i + 1 {
            indices = indices + [Json::number(i.to_double())]
          }
          Iter::singleton(Json::array(indices))
        }
        _ =>
          raise InterpreterError::TypeMismatch(
            "object/array",
            @json.type_name(input),
          )
      }
    @ast.Expr::Values =>
      match input {
        Object(obj) => {
          let mut values : Array[Json] = []
          for _k, v in obj {
            values = values + [v]
          }
          Iter::singleton(Json::array(values))
        }
        Array(arr) => Iter::singleton(Json::array(arr))
        _ =>
          raise InterpreterError::TypeMismatch(
            "object/array",
            @json.type_name(input),
          )
      }
    @ast.Expr::Type => Iter::singleton(Json::string(@json.type_name(input)))
    @ast.Expr::Empty => Iter::empty()
    @ast.Expr::Not => {
      let is_false = match input {
        False | Null => true
        _ => false
      }
      Iter::singleton(Json::boolean(is_false))
    }

    // Array functions
    @ast.Expr::Map(inner) =>
      match input {
        Array(arr) => {
          let mut results : Array[Json] = []
          for elem in arr {
            let mapped = eval_with_env(inner, elem, env).collect()
            results = results + mapped
          }
          Iter::singleton(Json::array(results))
        }
        _ =>
          raise InterpreterError::TypeMismatch("array", @json.type_name(input))
      }
    @ast.Expr::Select(condition) => {
      let cond_results = eval_with_env(condition, input, env).collect()
      if cond_results.is_empty() {
        Iter::empty()
      } else {
        let is_truthy = match cond_results[0] {
          False | Null => false
          _ => true
        }
        if is_truthy {
          Iter::singleton(input)
        } else {
          Iter::empty()
        }
      }
    }
    @ast.Expr::Sort =>
      match input {
        Array(arr) => {
          let sorted = arr.copy()
          sorted.sort_by(compare_json)
          Iter::singleton(Json::array(sorted))
        }
        _ =>
          raise InterpreterError::TypeMismatch("array", @json.type_name(input))
      }
    @ast.Expr::Reverse =>
      match input {
        Array(arr) => {
          let mut reversed : Array[Json] = []
          for i = arr.length() - 1; i >= 0; i = i - 1 {
            reversed = reversed + [arr[i]]
          }
          Iter::singleton(Json::array(reversed))
        }
        _ =>
          raise InterpreterError::TypeMismatch("array", @json.type_name(input))
      }
    @ast.Expr::Flatten(depth_opt) =>
      match input {
        Array(arr) => {
          let depth = match depth_opt {
            Some(d) => d
            None => 999999 // Flatten all levels
          }
          Iter::singleton(Json::array(flatten_array(arr, depth)))
        }
        _ =>
          raise InterpreterError::TypeMismatch("array", @json.type_name(input))
      }
    @ast.Expr::Unique =>
      match input {
        Array(arr) => {
          let sorted = arr.copy()
          sorted.sort_by(compare_json)
          let mut unique : Array[Json] = []
          let mut prev : Json? = None
          for elem in sorted {
            match prev {
              None => {
                unique = unique + [elem]
                prev = Some(elem)
              }
              Some(p) =>
                if compare_json(p, elem) != 0 {
                  unique = unique + [elem]
                  prev = Some(elem)
                }
            }
          }
          Iter::singleton(Json::array(unique))
        }
        _ =>
          raise InterpreterError::TypeMismatch("array", @json.type_name(input))
      }

    // Numeric functions
    @ast.Expr::Add =>
      match input {
        Array(arr) => {
          let mut sum = 0.0
          for elem in arr {
            match elem {
              Number(n, ..) => sum = sum + n
              _ => ()
            }
          }
          Iter::singleton(Json::number(sum))
        }
        _ =>
          raise InterpreterError::TypeMismatch("array", @json.type_name(input))
      }
    @ast.Expr::Floor =>
      match input {
        Number(n, ..) => Iter::singleton(Json::number(n.floor()))
        _ =>
          raise InterpreterError::TypeMismatch("number", @json.type_name(input))
      }
    @ast.Expr::Sqrt =>
      match input {
        Number(n, ..) => Iter::singleton(Json::number(n.sqrt()))
        _ =>
          raise InterpreterError::TypeMismatch("number", @json.type_name(input))
      }
    @ast.Expr::Min =>
      match input {
        Array(arr) =>
          if arr.is_empty() {
            Iter::singleton(Json::null())
          } else {
            let mut min_val = arr[0]
            for elem in arr {
              if compare_json(elem, min_val) < 0 {
                min_val = elem
              }
            }
            Iter::singleton(min_val)
          }
        _ =>
          raise InterpreterError::TypeMismatch("array", @json.type_name(input))
      }
    @ast.Expr::Max =>
      match input {
        Array(arr) =>
          if arr.is_empty() {
            Iter::singleton(Json::null())
          } else {
            let mut max_val = arr[0]
            for elem in arr {
              if compare_json(elem, max_val) > 0 {
                max_val = elem
              }
            }
            Iter::singleton(max_val)
          }
        _ =>
          raise InterpreterError::TypeMismatch("array", @json.type_name(input))
      }

    // Control flow
    @ast.Expr::IfThenElse(cond, then_expr, else_expr) => {
      let cond_results = eval_with_env(cond, input, env).collect()
      if cond_results.is_empty() {
        eval_with_env(else_expr, input, env)
      } else {
        let is_truthy = match cond_results[0] {
          False | Null => false
          _ => true
        }
        if is_truthy {
          eval_with_env(then_expr, input, env)
        } else {
          eval_with_env(else_expr, input, env)
        }
      }
    }
    @ast.Expr::TryCatch(try_expr, catch_opt) =>
      eval_with_env(try_expr, input, env) catch {
        _ =>
          match catch_opt {
            Some(catch_expr) => eval_with_env(catch_expr, input, env)
            None => Iter::empty()
          }
      }

    // Variables
    @ast.Expr::Variable(name) =>
      match env.get(name) {
        Some(v) => Iter::singleton(v)
        None =>
          raise InterpreterError::InvalidOperation(
            "Undefined variable: $\{name}",
          )
      }

    // Recursive descent
    @ast.Expr::Recurse => recurse_all(input)

    // Alternative operator: return left, or right if left produces empty/null
    @ast.Expr::Alternative(left, right) => {
      let left_results = eval_with_env(left, input, env).collect()
      if left_results.is_empty() {
        eval_with_env(right, input, env)
      } else {
        match left_results[0] {
          Null | False => eval_with_env(right, input, env)
          _ =>
            Iter::new(fn(emit) {
              for x in left_results {
                if emit(x) == IterEnd {
                  break
                }
              }
              IterContinue
            })
        }
      }
    }

    // As pattern: bind variable and continue with body
    @ast.Expr::As(expr, var_name, body) => {
      // Evaluate expr and bind each result to the variable
      let results = eval_with_env(expr, input, env).collect()
      let all_results : Array[Json] = []
      for result in results {
        let new_env = env.set(var_name, result)
        for val in eval_with_env(body, input, new_env) {
          all_results.push(val)
        }
      }
      Iter::new(fn(emit) {
        for x in all_results {
          if emit(x) == IterEnd {
            break
          }
        }
        IterContinue
      })
    }

    // Reduce: aggregate using accumulator
    @ast.Expr::Reduce(expr, var_name, init_expr, update_expr) => {
      // Evaluate init expression to get initial accumulator
      let init_results = eval_with_env(init_expr, input, env).collect()
      if init_results.is_empty() {
        return Iter::singleton(Json::null())
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
      Iter::singleton(accumulator)
    }

    // SortBy: sort array by expression result
    @ast.Expr::SortBy(expr) =>
      match input {
        Array(arr) => {
          // Create array of (value, sort_key) pairs
          let pairs : Array[(Json, Json)] = []
          for elem in arr {
            let keys = eval_with_env(expr, elem, env).collect()
            let sort_key = if keys.is_empty() { Json::null() } else { keys[0] }
            pairs.push((elem, sort_key))
          }
          // Sort by the key
          let sorted_pairs = pairs.copy()
          sorted_pairs.sort_by(fn(a, b) { compare_json(a.1, b.1) })
          // Extract values
          let sorted = sorted_pairs.map(fn(p) { p.0 })
          Iter::singleton(Json::array(sorted))
        }
        _ =>
          raise InterpreterError::TypeMismatch("array", @json.type_name(input))
      }

    // GroupBy: group array elements by expression result
    @ast.Expr::GroupBy(expr) =>
      match input {
        Array(arr) => {
          // Create groups: Map[String, Array[Json]]
          let groups : Map[String, Array[Json]] = {}
          for elem in arr {
            let keys = eval_with_env(expr, elem, env).collect()
            let key_json = if keys.is_empty() { Json::null() } else { keys[0] }
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
          Iter::singleton(Json::array(result))
        }
        _ =>
          raise InterpreterError::TypeMismatch("array", @json.type_name(input))
      }

    // Update operator: modify value in place
    @ast.Expr::Update(path, update_expr) => {
      // For now, simplified implementation
      // Evaluate the path to get current value, apply update, return modified input
      let current_results = eval_with_env(path, input, env).collect()
      if current_results.is_empty() {
        return Iter::singleton(input)
      }
      let current = current_results[0]
      let updated_results = eval_with_env(update_expr, current, env).collect()
      if updated_results.is_empty() {
        Iter::singleton(input)
      } else {
        Iter::singleton(updated_results[0])
      }
    }

    // Assign operator: set value at path
    @ast.Expr::Assign(_path, value_expr) => {
      // Evaluate the value expression
      let values = eval_with_env(value_expr, input, env).collect()
      if values.is_empty() {
        Iter::singleton(input)
      } else {
        Iter::singleton(values[0])
      }
    }

    // RecurseWith: custom recursion with function
    @ast.Expr::RecurseWith(f, _cond) => {
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
      Iter::new(fn(emit) {
        for x in results {
          if emit(x) == IterEnd {
            break
          }
        }
        IterContinue
      })
    }

    // Walk: recursively apply function to all values
    @ast.Expr::Walk(f) => {
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

      Iter::singleton(walk_value(input))
    }

    // Path expression: get path to a value
    @ast.Expr::Path(_expr) =>
      // Simplified: return empty array for now
      // Full implementation would track paths during evaluation
      Iter::singleton(Json::array([]))

    // Additional numeric functions
    @ast.Expr::Round =>
      match input {
        Number(n, ..) => Iter::singleton(Json::number(n.round()))
        _ =>
          raise InterpreterError::TypeMismatch("number", @json.type_name(input))
      }
    @ast.Expr::Ceil =>
      match input {
        Number(n, ..) => Iter::singleton(Json::number(n.ceil()))
        _ =>
          raise InterpreterError::TypeMismatch("number", @json.type_name(input))
      }
    @ast.Expr::Abs =>
      match input {
        Number(n, ..) => Iter::singleton(Json::number(n.abs()))
        _ =>
          raise InterpreterError::TypeMismatch("number", @json.type_name(input))
      }

    // String operations
    @ast.Expr::Split(sep) =>
      match input {
        String(s) => {
          let parts = s.split(sep)
          let json_parts : Array[Json] = []
          for part in parts {
            json_parts.push(Json::string(part.to_string()))
          }
          Iter::singleton(Json::array(json_parts))
        }
        _ =>
          raise InterpreterError::TypeMismatch("string", @json.type_name(input))
      }
    @ast.Expr::Join(sep) =>
      match input {
        Array(arr) => {
          let parts : Array[String] = []
          for elem in arr {
            match elem {
              String(s) => parts.push(s)
              _ => parts.push(elem.to_string())
            }
          }
          Iter::singleton(Json::string(parts.join(sep)))
        }
        _ =>
          raise InterpreterError::TypeMismatch("array", @json.type_name(input))
      }
    @ast.Expr::StartsWith(prefix) =>
      match input {
        String(s) => Iter::singleton(Json::boolean(s.has_prefix(prefix)))
        _ =>
          raise InterpreterError::TypeMismatch("string", @json.type_name(input))
      }
    @ast.Expr::EndsWith(suffix) =>
      match input {
        String(s) => Iter::singleton(Json::boolean(s.has_suffix(suffix)))
        _ =>
          raise InterpreterError::TypeMismatch("string", @json.type_name(input))
      }
    @ast.Expr::Contains(expr) => {
      let needle_results = eval_with_env(expr, input, env).collect()
      if needle_results.is_empty() {
        return Iter::singleton(Json::boolean(false))
      }
      let needle = needle_results[0]
      match (input, needle) {
        (String(haystack), String(n)) =>
          Iter::singleton(Json::boolean(haystack.contains(n)))
        (Array(haystack), _) => {
          let mut found = false
          for elem in haystack {
            if elem == needle {
              found = true
              break
            }
          }
          Iter::singleton(Json::boolean(found))
        }
        (Object(haystack), String(key)) =>
          Iter::singleton(Json::boolean(haystack.contains(key)))
        _ => Iter::singleton(Json::boolean(false))
      }
    }
    @ast.Expr::Inside(expr) => {
      // inside is the reverse of contains
      let container_results = eval_with_env(expr, input, env).collect()
      if container_results.is_empty() {
        return Iter::singleton(Json::boolean(false))
      }
      let container = container_results[0]
      match (input, container) {
        (String(needle), String(haystack)) =>
          Iter::singleton(Json::boolean(haystack.contains(needle)))
        (_, Array(haystack)) => {
          let mut found = false
          for elem in haystack {
            if elem == input {
              found = true
              break
            }
          }
          Iter::singleton(Json::boolean(found))
        }
        (String(key), Object(haystack)) =>
          Iter::singleton(Json::boolean(haystack.contains(key)))
        _ => Iter::singleton(Json::boolean(false))
      }
    }

    // Object/Array operations
    @ast.Expr::Has(key) =>
      match input {
        Object(obj) => Iter::singleton(Json::boolean(obj.contains(key)))
        Array(arr) => {
          // For arrays, treat key as index
          let idx_result = @strconv.parse_int(key) catch {
            _ => return Iter::singleton(Json::boolean(false))
          }
          let len = arr.length()
          let actual_idx = if idx_result < 0 {
            len + idx_result
          } else {
            idx_result
          }
          Iter::singleton(Json::boolean(actual_idx >= 0 && actual_idx < len))
        }
        _ => Iter::singleton(Json::boolean(false))
      }
    @ast.Expr::In(expr) => {
      let container_results = eval_with_env(expr, input, env).collect()
      if container_results.is_empty() {
        return Iter::singleton(Json::boolean(false))
      }
      match container_results[0] {
        Object(obj) =>
          match input {
            String(key) => Iter::singleton(Json::boolean(obj.contains(key)))
            _ => Iter::singleton(Json::boolean(false))
          }
        Array(arr) =>
          match input {
            Number(n, ..) => {
              let idx = n.to_int()
              let len = arr.length()
              let actual_idx = if idx < 0 { len + idx } else { idx }
              Iter::singleton(
                Json::boolean(actual_idx >= 0 && actual_idx < len),
              )
            }
            _ => Iter::singleton(Json::boolean(false))
          }
        _ => Iter::singleton(Json::boolean(false))
      }
    }
    @ast.Expr::ToEntries =>
      match input {
        Object(obj) => {
          let entries : Array[Json] = []
          for k, v in obj {
            let entry : Map[String, Json] = {}
            entry["key"] = Json::string(k)
            entry["value"] = v
            entries.push(Json::object(entry))
          }
          Iter::singleton(Json::array(entries))
        }
        Array(arr) => {
          let entries : Array[Json] = []
          for i = 0; i < arr.length(); i = i + 1 {
            let entry : Map[String, Json] = {}
            entry["key"] = Json::number(i.to_double())
            entry["value"] = arr[i]
            entries.push(Json::object(entry))
          }
          Iter::singleton(Json::array(entries))
        }
        _ =>
          raise InterpreterError::TypeMismatch(
            "object/array",
            @json.type_name(input),
          )
      }
    @ast.Expr::FromEntries =>
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
          Iter::singleton(Json::object(result))
        }
        _ =>
          raise InterpreterError::TypeMismatch("array", @json.type_name(input))
      }
    @ast.Expr::WithEntries(expr) =>
      // Convert to entries, apply expr, convert back
      match input {
        Object(_) | Array(_) => {
          // to_entries
          let entries_results = eval_with_env(@ast.Expr::ToEntries, input, env).collect()
          if entries_results.is_empty() {
            return Iter::singleton(input)
          }
          // Apply expression to entries array
          let transformed_results = eval_with_env(expr, entries_results[0], env).collect()
          if transformed_results.is_empty() {
            return Iter::singleton(input)
          }
          // from_entries
          eval_with_env(@ast.Expr::FromEntries, transformed_results[0], env)
        }
        _ =>
          raise InterpreterError::TypeMismatch(
            "object/array",
            @json.type_name(input),
          )
      }

    // Iteration helpers
    @ast.Expr::Range(n) => {
      let results : Array[Json] = []
      for i = 0; i < n; i = i + 1 {
        results.push(Json::number(i.to_double()))
      }
      Iter::new(fn(emit) {
        for x in results {
          if emit(x) == IterEnd {
            break
          }
        }
        IterContinue
      })
    }
    @ast.Expr::First =>
      match input {
        Array(arr) =>
          if arr.is_empty() {
            Iter::empty()
          } else {
            Iter::singleton(arr[0])
          }
        _ =>
          raise InterpreterError::TypeMismatch("array", @json.type_name(input))
      }
    @ast.Expr::Last =>
      match input {
        Array(arr) =>
          if arr.is_empty() {
            Iter::empty()
          } else {
            Iter::singleton(arr[arr.length() - 1])
          }
        _ =>
          raise InterpreterError::TypeMismatch("array", @json.type_name(input))
      }
    @ast.Expr::IndicesOf(expr) => {
      let needle_results = eval_with_env(expr, input, env).collect()
      if needle_results.is_empty() {
        return Iter::singleton(Json::array([]))
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
          Iter::singleton(Json::array(indices))
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
              Iter::singleton(Json::array(indices))
            }
            _ => Iter::singleton(Json::array([]))
          }
        _ =>
          raise InterpreterError::TypeMismatch(
            "array/string",
            @json.type_name(input),
          )
      }
    }
    @ast.Expr::IndexOf(expr) => {
      let needle_results = eval_with_env(expr, input, env).collect()
      if needle_results.is_empty() {
        return Iter::singleton(Json::null())
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
            Some(idx) => Iter::singleton(Json::number(idx.to_double()))
            None => Iter::singleton(Json::null())
          }
        }
        String(s) =>
          match needle {
            String(substr) =>
              // Finding index in string requires searching
              // For now, check if contains and return 0 or null
              if s.contains(substr) {
                Iter::singleton(Json::number(0.0))
              } else {
                Iter::singleton(Json::null())
              }
            _ => Iter::singleton(Json::null())
          }
        _ =>
          raise InterpreterError::TypeMismatch(
            "array/string",
            @json.type_name(input),
          )
      }
    }

    // Predicates
    @ast.Expr::Any =>
      match input {
        Array(arr) => {
          let mut result = false
          for elem in arr {
            match elem {
              False | Null => ()
              _ => {
                result = true
                break
              }
            }
          }
          Iter::singleton(Json::boolean(result))
        }
        _ =>
          raise InterpreterError::TypeMismatch("array", @json.type_name(input))
      }
    @ast.Expr::All =>
      match input {
        Array(arr) => {
          let mut result = true
          for elem in arr {
            match elem {
              False | Null => {
                result = false
                break
              }
              _ => ()
            }
          }
          Iter::singleton(Json::boolean(result))
        }
        _ =>
          raise InterpreterError::TypeMismatch("array", @json.type_name(input))
      }

    // String trimming
    @ast.Expr::LTrimStr(prefix) =>
      match input {
        String(s) =>
          if s.has_prefix(prefix) {
            Iter::singleton(Json::string(s.substring(start=prefix.length())))
          } else {
            Iter::singleton(input)
          }
        _ =>
          raise InterpreterError::TypeMismatch("string", @json.type_name(input))
      }
    @ast.Expr::RTrimStr(suffix) =>
      match input {
        String(s) =>
          if s.has_suffix(suffix) {
            Iter::singleton(
              Json::string(s.substring(end=s.length() - suffix.length())),
            )
          } else {
            Iter::singleton(input)
          }
        _ =>
          raise InterpreterError::TypeMismatch("string", @json.type_name(input))
      }
    @ast.Expr::AsciiUpcase =>
      match input {
        String(s) => {
          let result = @buffer.new()
          for ch in s {
            if ch >= 'a' && ch <= 'z' {
              result.write_char(Char::from_int(ch.to_int() - 32))
            } else {
              result.write_char(ch)
            }
          }
          Iter::singleton(Json::string(result.to_string()))
        }
        _ =>
          raise InterpreterError::TypeMismatch("string", @json.type_name(input))
      }
    @ast.Expr::AsciiDowncase =>
      match input {
        String(s) => {
          let result = @buffer.new()
          for ch in s {
            if ch >= 'A' && ch <= 'Z' {
              result.write_char(Char::from_int(ch.to_int() + 32))
            } else {
              result.write_char(ch)
            }
          }
          Iter::singleton(Json::string(result.to_string()))
        }
        _ =>
          raise InterpreterError::TypeMismatch("string", @json.type_name(input))
      }

    // Array functions
    @ast.Expr::Nth(n) =>
      match input {
        Array(arr) =>
          if n >= 0 && n < arr.length() {
            Iter::singleton(arr[n])
          } else if n < 0 && -n <= arr.length() {
            Iter::singleton(arr[arr.length() + n])
          } else {
            Iter::empty()
          }
        _ =>
          raise InterpreterError::TypeMismatch("array", @json.type_name(input))
      }
    @ast.Expr::RIndex(search_expr) => {
      let needle_results = eval_with_env(search_expr, input, env).collect()
      if needle_results.is_empty() {
        return Iter::singleton(Json::null())
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
            Some(idx) => Iter::singleton(Json::number(idx.to_double()))
            None => Iter::singleton(Json::null())
          }
        }
        String(s) =>
          match needle {
            String(substr) => {
              let mut last_pos : Int? = None
              let slen = s.length()
              let sublen = substr.length()
              for i = 0; i <= slen - sublen; i = i + 1 {
                if s.substring(start=i, end=i + sublen) == substr {
                  last_pos = Some(i)
                }
              }
              match last_pos {
                Some(pos) => Iter::singleton(Json::number(pos.to_double()))
                None => Iter::singleton(Json::null())
              }
            }
            _ => Iter::singleton(Json::null())
          }
        _ =>
          raise InterpreterError::TypeMismatch(
            "array or string",
            @json.type_name(input),
          )
      }
    }

    // Path functions
    @ast.Expr::Paths => {
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
      Iter::new(fn(emit) {
        for p in paths_list {
          if emit(p) == IterEnd {
            break
          }
        }
        IterContinue
      })
    }
    @ast.Expr::LeafPaths => {
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
      Iter::new(fn(emit) {
        for p in paths_list {
          if emit(p) == IterEnd {
            break
          }
        }
        IterContinue
      })
    }
    @ast.Expr::GetPath(path_expr) => {
      let path_results = eval_with_env(path_expr, input, env).collect()
      if path_results.is_empty() {
        return Iter::singleton(Json::null())
      }
      match path_results[0] {
        Array(path_arr) => {
          let mut current = input
          for segment in path_arr {
            match (current, segment) {
              (Object(obj), String(key)) =>
                match obj.get(key) {
                  Some(v) => current = v
                  None => return Iter::singleton(Json::null())
                }
              (Array(arr), Number(idx, ..)) => {
                let i = idx.to_int()
                if i >= 0 && i < arr.length() {
                  current = arr[i]
                } else {
                  return Iter::singleton(Json::null())
                }
              }
              _ => return Iter::singleton(Json::null())
            }
          }
          Iter::singleton(current)
        }
        _ => Iter::singleton(Json::null())
      }
    }
    @ast.Expr::SetPath(path_expr, value_expr) => {
      let path_results = eval_with_env(path_expr, input, env).collect()
      let value_results = eval_with_env(value_expr, input, env).collect()
      if path_results.is_empty() || value_results.is_empty() {
        return Iter::singleton(input)
      }
      match path_results[0] {
        Array(path_arr) =>
          if path_arr.is_empty() {
            Iter::singleton(value_results[0])
          } else {
            Iter::singleton(set_at_path(input, path_arr, value_results[0]))
          }
        _ => Iter::singleton(input)
      }
    }
    @ast.Expr::DelPaths(paths_expr) => {
      let paths_results = eval_with_env(paths_expr, input, env).collect()
      if paths_results.is_empty() {
        return Iter::singleton(input)
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
          Iter::singleton(result)
        }
        _ => Iter::singleton(input)
      }
    }

    // Control flow
    @ast.Expr::Limit(n, expr) => {
      let results = eval_with_env(expr, input, env)
      let count = Ref::new(0)
      Iter::new(fn(emit) {
        for val in results {
          if count.val >= n {
            break
          }
          count.val = count.val + 1
          if emit(val) == IterEnd {
            break
          }
        }
        IterContinue
      })
    }
    @ast.Expr::Until(cond_expr, update_expr) => {
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
      Iter::singleton(current)
    }
    @ast.Expr::While(cond_expr, update_expr) => {
      let results : Array[Json] = []
      let mut current = input
      while true {
        let cond_results = eval_with_env(cond_expr, current, env).collect()
        if cond_results.is_empty() {
          break
        }
        match cond_results[0] {
          False | Null => break
          _ => {
            results.push(current)
            let update_results = eval_with_env(update_expr, current, env).collect()
            if update_results.is_empty() {
              break
            }
            current = update_results[0]
          }
        }
      }
      Iter::new(fn(emit) {
        for val in results {
          if emit(val) == IterEnd {
            break
          }
        }
        IterContinue
      })
    }

    // Math functions
    @ast.Expr::Pow(exp_expr) => {
      let exp_results = eval_with_env(exp_expr, input, env).collect()
      if exp_results.is_empty() {
        return Iter::singleton(Json::null())
      }
      match (input, exp_results[0]) {
        (Number(base, ..), Number(exp, ..)) =>
          Iter::singleton(Json::number(base.pow(exp)))
        _ =>
          raise InterpreterError::TypeMismatch("number", @json.type_name(input))
      }
    }
    @ast.Expr::Log =>
      match input {
        Number(n, ..) => Iter::singleton(Json::number(@math.ln(n)))
        _ =>
          raise InterpreterError::TypeMismatch("number", @json.type_name(input))
      }
    @ast.Expr::Exp =>
      match input {
        Number(n, ..) => Iter::singleton(Json::number(@math.exp(n)))
        _ =>
          raise InterpreterError::TypeMismatch("number", @json.type_name(input))
      }
    @ast.Expr::Sin =>
      match input {
        Number(n, ..) => Iter::singleton(Json::number(@math.sin(n)))
        _ =>
          raise InterpreterError::TypeMismatch("number", @json.type_name(input))
      }
    @ast.Expr::Cos =>
      match input {
        Number(n, ..) => Iter::singleton(Json::number(@math.cos(n)))
        _ =>
          raise InterpreterError::TypeMismatch("number", @json.type_name(input))
      }
    @ast.Expr::Tan =>
      match input {
        Number(n, ..) => Iter::singleton(Json::number(@math.tan(n)))
        _ =>
          raise InterpreterError::TypeMismatch("number", @json.type_name(input))
      }
    @ast.Expr::Asin =>
      match input {
        Number(n, ..) => Iter::singleton(Json::number(@math.asin(n)))
        _ =>
          raise InterpreterError::TypeMismatch("number", @json.type_name(input))
      }
    @ast.Expr::Acos =>
      match input {
        Number(n, ..) => Iter::singleton(Json::number(@math.acos(n)))
        _ =>
          raise InterpreterError::TypeMismatch("number", @json.type_name(input))
      }
    @ast.Expr::Atan =>
      match input {
        Number(n, ..) => Iter::singleton(Json::number(@math.atan(n)))
        _ =>
          raise InterpreterError::TypeMismatch("number", @json.type_name(input))
      }

    // Regex functions (simple implementations)
    @ast.Expr::Test(pattern) =>
      match input {
        String(s) => Iter::singleton(Json::boolean(s.contains(pattern)))
        _ =>
          raise InterpreterError::TypeMismatch("string", @json.type_name(input))
      }
    @ast.Expr::Match(pattern) =>
      match input {
        String(s) =>
          if s.contains(pattern) {
            Iter::singleton(
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
            Iter::empty()
          }
        _ =>
          raise InterpreterError::TypeMismatch("string", @json.type_name(input))
      }
    @ast.Expr::Capture(_pattern) =>
      match input {
        String(_s) => Iter::singleton(Json::object(Map::from_array([])))
        _ =>
          raise InterpreterError::TypeMismatch("string", @json.type_name(input))
      }
    @ast.Expr::Splits(pattern) =>
      match input {
        String(s) => {
          let parts = s.split(pattern)
          Iter::new(fn(emit) {
            for part in parts {
              if emit(Json::string(part.to_string())) == IterEnd {
                break
              }
            }
            IterContinue
          })
        }
        _ =>
          raise InterpreterError::TypeMismatch("string", @json.type_name(input))
      }
    @ast.Expr::Sub(pattern, replacement) =>
      match input {
        String(s) => {
          let mut found_idx : Int? = None
          let slen = s.length()
          let plen = pattern.length()
          for i = 0; i <= slen - plen; i = i + 1 {
            if s.substring(start=i, end=i + plen) == pattern {
              found_idx = Some(i)
              break
            }
          }
          match found_idx {
            Some(i) =>
              Iter::singleton(
                Json::string(
                  s.substring(end=i) +
                  replacement +
                  s.substring(start=i + pattern.length()),
                ),
              )
            None => Iter::singleton(input)
          }
        }
        _ =>
          raise InterpreterError::TypeMismatch("string", @json.type_name(input))
      }
    @ast.Expr::GSub(pattern, replacement) =>
      match input {
        String(s) => {
          let mut result = s
          while true {
            let mut found_idx : Int? = None
            let rlen = result.length()
            let plen = pattern.length()
            for i = 0; i <= rlen - plen; i = i + 1 {
              if result.substring(start=i, end=i + plen) == pattern {
                found_idx = Some(i)
                break
              }
            }
            match found_idx {
              Some(i) =>
                result = result.substring(end=i) +
                  replacement +
                  result.substring(start=i + pattern.length())
              None => break
            }
          }
          Iter::singleton(Json::string(result))
        }
        _ =>
          raise InterpreterError::TypeMismatch("string", @json.type_name(input))
      }

    // Not yet implemented features
    _ =>
      raise InterpreterError::InvalidOperation(
        "Feature not yet implemented: \{expr}",
      )
  }
}

///|
/// Evaluate a literal to JSON
fn eval_literal(lit : @ast.Literal) -> Json {
  match lit {
    @ast.Literal::Null => Json::null()
    @ast.Literal::Bool(b) => Json::boolean(b)
    @ast.Literal::Number(n) => Json::number(n)
    @ast.Literal::String(s) => Json::string(s)
  }
}

///|
/// Evaluate binary operation
fn eval_binary_op(
  op : @ast.BinaryOp,
  left : Json,
  right : Json,
) -> Json raise InterpreterError {
  match op {
    @ast.BinaryOp::Add => json_add(left, right)
    @ast.BinaryOp::Subtract => json_subtract(left, right)
    @ast.BinaryOp::Multiply => json_multiply(left, right)
    @ast.BinaryOp::Divide => json_divide(left, right)
    @ast.BinaryOp::Modulo => json_modulo(left, right)
    @ast.BinaryOp::Equal => Json::boolean(compare_json(left, right) == 0)
    @ast.BinaryOp::NotEqual => Json::boolean(compare_json(left, right) != 0)
    @ast.BinaryOp::LessThan => Json::boolean(compare_json(left, right) < 0)
    @ast.BinaryOp::LessEq => Json::boolean(compare_json(left, right) <= 0)
    @ast.BinaryOp::GreaterThan => Json::boolean(compare_json(left, right) > 0)
    @ast.BinaryOp::GreaterEq => Json::boolean(compare_json(left, right) >= 0)
    @ast.BinaryOp::And => {
      let left_truthy = match left {
        False | Null => false
        _ => true
      }
      if left_truthy {
        right
      } else {
        Json::boolean(false)
      }
    }
    @ast.BinaryOp::Or => {
      let left_truthy = match left {
        False | Null => false
        _ => true
      }
      if left_truthy {
        left
      } else {
        right
      }
    }
  }
}

///|
/// Arithmetic operations
fn json_add(left : Json, right : Json) -> Json raise InterpreterError {
  match (left, right) {
    (Number(a, ..), Number(b, ..)) => Json::number(a + b)
    (String(a), String(b)) => Json::string(a + b)
    (Array(a), Array(b)) => Json::array(a + b)
    (Object(a), Object(b)) => {
      let result = a
      for k, v in b {
        result[k] = v
      }
      Json::object(result)
    }
    _ =>
      raise InterpreterError::InvalidOperation(
        "Cannot add \{@json.type_name(left)} and \{@json.type_name(right)}",
      )
  }
}

///|
fn json_subtract(left : Json, right : Json) -> Json raise InterpreterError {
  match (left, right) {
    (Number(a, ..), Number(b, ..)) => Json::number(a - b)
    (Array(a), Array(b)) => {
      let mut result : Array[Json] = []
      for elem in a {
        let mut found = false
        for r in b {
          if compare_json(elem, r) == 0 {
            found = true
            break
          }
        }
        if not(found) {
          result = result + [elem]
        }
      }
      Json::array(result)
    }
    _ =>
      raise InterpreterError::InvalidOperation(
        "Cannot subtract \{@json.type_name(right)} from \{@json.type_name(left)}",
      )
  }
}

///|
fn json_multiply(left : Json, right : Json) -> Json raise InterpreterError {
  match (left, right) {
    (Number(a, ..), Number(b, ..)) => Json::number(a * b)
    (String(s), Number(n, ..)) | (Number(n, ..), String(s)) => {
      let count = n.to_int()
      let mut result = ""
      for _i = 0; _i < count; _i = _i + 1 {
        result = result + s
      }
      Json::string(result)
    }
    _ =>
      raise InterpreterError::InvalidOperation(
        "Cannot multiply \{@json.type_name(left)} and \{@json.type_name(right)}",
      )
  }
}

///|
fn json_divide(left : Json, right : Json) -> Json raise InterpreterError {
  match (left, right) {
    (Number(a, ..), Number(b, ..)) => {
      if b == 0.0 {
        raise InterpreterError::DivisionByZero
      }
      Json::number(a / b)
    }
    _ =>
      raise InterpreterError::InvalidOperation(
        "Cannot divide \{@json.type_name(left)} by \{@json.type_name(right)}",
      )
  }
}

///|
fn json_modulo(left : Json, right : Json) -> Json raise InterpreterError {
  match (left, right) {
    (Number(a, ..), Number(b, ..)) => {
      if b == 0.0 {
        raise InterpreterError::DivisionByZero
      }
      Json::number(a % b)
    }
    _ =>
      raise InterpreterError::InvalidOperation(
        "Cannot modulo \{@json.type_name(left)} by \{@json.type_name(right)}",
      )
  }
}

///|
/// Compare JSON values for sorting
fn compare_json(a : Json, b : Json) -> Int {
  match (a, b) {
    (Null, Null) => 0
    (Null, _) => -1
    (_, Null) => 1
    (False, False) => 0
    (False, True) => -1
    (True, False) => 1
    (True, True) => 0
    (Number(x, ..), Number(y, ..)) => x.compare(y)
    (String(x), String(y)) => x.compare(y)
    (Array(x), Array(y)) => {
      let min_len = if x.length() < y.length() {
        x.length()
      } else {
        y.length()
      }
      for i = 0; i < min_len; i = i + 1 {
        let cmp = compare_json(x[i], y[i])
        if cmp != 0 {
          return cmp
        }
      }
      x.length().compare(y.length())
    }
    // Type ordering: null < bool < number < string < array < object
    (False | True, Number(_)) => -1
    (Number(_), False | True) => 1
    (Number(_), String(_)) => -1
    (String(_), Number(_)) => 1
    (String(_), Array(_)) => -1
    (Array(_), String(_)) => 1
    (Array(_), Object(_)) => -1
    (Object(_), Array(_)) => 1
    (Object(_), Object(_)) => 0 // Objects compare equal
    _ => 0
  }
}

///|
/// Flatten array to specified depth
fn flatten_array(arr : Array[Json], depth : Int) -> Array[Json] {
  if depth <= 0 {
    return arr
  }
  let mut result : Array[Json] = []
  for elem in arr {
    match elem {
      Array(inner) => result = result + flatten_array(inner, depth - 1)
      _ => result = result + [elem]
    }
  }
  result
}

///|
/// Recursive descent: yield input and all nested values
fn recurse_all(input : Json) -> Iter[Json] {
  Iter::concat(
    Iter::singleton(input),
    match input {
      Array(arr) =>
        Iter::new(fn(emit) {
          for x in arr {
            if emit(x) == IterEnd {
              break
            }
          }
          IterContinue
        }).flat_map(recurse_all)
      Object(obj) => {
        let mut values : Array[Json] = []
        for _k, v in obj {
          values = values + [v]
        }
        Iter::new(fn(emit) {
          for x in values {
            if emit(x) == IterEnd {
              break
            }
          }
          IterContinue
        }).flat_map(recurse_all)
      }
      _ => Iter::empty()
    },
  )
}

///|
/// Helper to set value at a path in JSON structure
fn set_at_path(root : Json, path : Array[Json], value : Json) -> Json {
  if path.is_empty() {
    return value
  }
  let segment = path[0]
  let remaining = path[1:]
  match (root, segment) {
    (Object(obj), String(key)) => {
      let new_obj = Map::from_array(obj.iter().collect())
      if remaining.length() == 0 {
        new_obj[key] = value
      } else {
        let current = obj.get(key).unwrap_or(Json::null())
        new_obj[key] = set_at_path(current, remaining.to_array(), value)
      }
      Json::object(new_obj)
    }
    (Array(arr), Number(idx, ..)) => {
      let i = idx.to_int()
      if i >= 0 && i < arr.length() {
        let new_arr = arr.copy()
        if remaining.length() == 0 {
          new_arr[i] = value
        } else {
          new_arr[i] = set_at_path(arr[i], remaining.to_array(), value)
        }
        Json::array(new_arr)
      } else {
        root
      }
    }
    _ => root
  }
}

///|
/// Helper to delete value at a path in JSON structure
fn delete_at_path(root : Json, path : Array[Json]) -> Json {
  if path.is_empty() {
    return Json::null()
  }
  if path.length() == 1 {
    let segment = path[0]
    match (root, segment) {
      (Object(obj), String(key)) => {
        let new_obj = Map::from_array(obj.iter().collect())
        new_obj.remove(key)
        Json::object(new_obj)
      }
      (Array(arr), Number(idx, ..)) => {
        let i = idx.to_int()
        if i >= 0 && i < arr.length() {
          let new_arr : Array[Json] = []
          for j = 0; j < arr.length(); j = j + 1 {
            if j != i {
              new_arr.push(arr[j])
            }
          }
          Json::array(new_arr)
        } else {
          root
        }
      }
      _ => root
    }
  } else {
    let segment = path[0]
    let remaining = path[1:]
    match (root, segment) {
      (Object(obj), String(key)) => {
        let new_obj = Map::from_array(obj.iter().collect())
        match obj.get(key) {
          Some(current) =>
            new_obj[key] = delete_at_path(current, remaining.to_array())
          None => ()
        }
        Json::object(new_obj)
      }
      (Array(arr), Number(idx, ..)) => {
        let i = idx.to_int()
        if i >= 0 && i < arr.length() {
          let new_arr = arr.copy()
          new_arr[i] = delete_at_path(arr[i], remaining.to_array())
          Json::array(new_arr)
        } else {
          root
        }
      }
      _ => root
    }
  }
}
