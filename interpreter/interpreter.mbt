///|
/// Interpreter error types
pub(all) suberror InterpreterError {
  TypeMismatch(String, String) // (expected, got)
  KeyNotFound(String)
  IndexOutOfBounds(Int)
  InvalidOperation(String)
  DivisionByZero
  TypeError(String)
  EvalError(String)
} derive(Eq, Show)

///|
/// Environment for variable and function bindings
priv struct Env {
  bindings : Map[String, Json]
  functions : Map[String, (@ast.Expr, Array[String])] // (body, params)
}

///|
fn Env::new() -> Env {
  { bindings: {}, functions: {} }
}

///|
fn Env::get(self : Env, name : String) -> Json? {
  self.bindings.get(name)
}

///|
fn Env::set(self : Env, name : String, value : Json) -> Env {
  let new_bindings : Map[String, Json] = {}
  for k, v in self.bindings {
    new_bindings[k] = v
  }
  new_bindings[name] = value
  { bindings: new_bindings, functions: self.functions }
}

///|
fn Env::set_function(
  self : Env,
  name : String,
  body : @ast.Expr,
  params : Array[String],
) -> Env {
  let new_bindings : Map[String, Json] = {}
  for k, v in self.bindings {
    new_bindings[k] = v
  }
  let new_funcs : Map[String, (@ast.Expr, Array[String])] = {}
  for k, v in self.functions {
    new_funcs[k] = v
  }
  new_funcs[name] = (body, params)
  { bindings: new_bindings, functions: new_funcs }
}

///|
fn Env::get_function(self : Env, name : String) -> (@ast.Expr, Array[String])? {
  self.functions.get(name)
}

///|
/// Evaluate an expression with input JSON, returns iterator of results
pub fn eval(expr : @ast.Expr, input : Json) -> Iterator[Json] raise {
  eval_with_env(expr, input, Env::new())
}

///|
/// Evaluate with environment
fn eval_with_env(
  expr : @ast.Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  match expr {
    // Identity returns input as-is
    @ast.Expr::Identity => Iterator::singleton(input)

    // Literals ignore input and return the literal value
    @ast.Expr::Literal(lit) => Iterator::singleton(eval_literal(lit))

    // Pipe: feed results of left into right
    @ast.Expr::Pipe(left, right) => {
      // Special case: if left is a function definition, update env
      match left {
        @ast.Expr::FunctionDef(name, params, body) => {
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
    @ast.Expr::Comma(left, right) =>
      Iterator::concat(
        eval_with_env(left, input, env),
        eval_with_env(right, input, env),
      )

    // Field access
    @ast.Expr::Key(key) =>
      match input {
        Object(obj) =>
          match obj.get(key) {
            Some(v) => Iterator::singleton(v)
            None => Iterator::singleton(Json::null())
          }
        _ => Iterator::singleton(Json::null())
      }

    // Array indexing and iteration
    @ast.Expr::Index(indices) =>
      if indices.is_empty() {
        // Empty index means iterate over array/object values
        match input {
          Array(arr) => arr.iterator()
          Object(obj) => {
            let mut values : Array[Json] = []
            for _k, v in obj {
              values = values + [v]
            }
            values.iterator()
          }
          _ => Iterator::empty()
        }
      } else {
        // Multiple indices produce multiple results
        indices
        .iterator()
        .map(fn(idx) {
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
          Iterator::singleton(Json::array(result))
        }
        _ => Iterator::singleton(Json::null())
      }

    // Optional: suppress errors and return empty on failure
    @ast.Expr::Optional(inner) =>
      eval_with_env(inner, input, env) catch {
        _ => Iterator::empty()
      }

    // Array construction
    @ast.Expr::ArrayConstruct(expr_opt) =>
      match expr_opt {
        None => Iterator::singleton(Json::array([]))
        Some(e) => {
          let results = eval_with_env(e, input, env).collect()
          Iterator::singleton(Json::array(results))
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
      Iterator::singleton(Json::object(obj))
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
      all_results.iterator()
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
      Iterator::singleton(Json::number(len.to_double()))
    }
    @ast.Expr::Keys =>
      match input {
        Object(obj) => {
          let mut keys : Array[Json] = []
          for k, _v in obj {
            keys = keys + [Json::string(k)]
          }
          Iterator::singleton(Json::array(keys))
        }
        Array(arr) => {
          let mut indices : Array[Json] = []
          for i = 0; i < arr.length(); i = i + 1 {
            indices = indices + [Json::number(i.to_double())]
          }
          Iterator::singleton(Json::array(indices))
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
          Iterator::singleton(Json::array(values))
        }
        Array(arr) => Iterator::singleton(Json::array(arr))
        _ =>
          raise InterpreterError::TypeMismatch(
            "object/array",
            @json.type_name(input),
          )
      }
    @ast.Expr::Type => Iterator::singleton(Json::string(@json.type_name(input)))
    @ast.Expr::Empty => Iterator::empty()
    @ast.Expr::Not => {
      let is_false = match input {
        False | Null => true
        _ => false
      }
      Iterator::singleton(Json::boolean(is_false))
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
          Iterator::singleton(Json::array(results))
        }
        _ =>
          raise InterpreterError::TypeMismatch("array", @json.type_name(input))
      }
    @ast.Expr::Select(condition) => {
      let cond_results = eval_with_env(condition, input, env).collect()
      if cond_results.is_empty() {
        Iterator::empty()
      } else {
        let is_truthy = match cond_results[0] {
          False | Null => false
          _ => true
        }
        if is_truthy {
          Iterator::singleton(input)
        } else {
          Iterator::empty()
        }
      }
    }
    @ast.Expr::Sort =>
      match input {
        Array(arr) => {
          let sorted = arr.copy()
          sorted.sort_by(compare_json)
          Iterator::singleton(Json::array(sorted))
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
          Iterator::singleton(Json::array(reversed))
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
          Iterator::singleton(Json::array(flatten_array(arr, depth)))
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
          Iterator::singleton(Json::array(unique))
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
          Iterator::singleton(Json::number(sum))
        }
        _ =>
          raise InterpreterError::TypeMismatch("array", @json.type_name(input))
      }
    @ast.Expr::Floor =>
      match input {
        Number(n, ..) => Iterator::singleton(Json::number(n.floor()))
        _ =>
          raise InterpreterError::TypeMismatch("number", @json.type_name(input))
      }
    @ast.Expr::Sqrt =>
      match input {
        Number(n, ..) => Iterator::singleton(Json::number(n.sqrt()))
        _ =>
          raise InterpreterError::TypeMismatch("number", @json.type_name(input))
      }
    @ast.Expr::Min =>
      match input {
        Array(arr) =>
          if arr.is_empty() {
            Iterator::singleton(Json::null())
          } else {
            let mut min_val = arr[0]
            for elem in arr {
              if compare_json(elem, min_val) < 0 {
                min_val = elem
              }
            }
            Iterator::singleton(min_val)
          }
        _ =>
          raise InterpreterError::TypeMismatch("array", @json.type_name(input))
      }
    @ast.Expr::Max =>
      match input {
        Array(arr) =>
          if arr.is_empty() {
            Iterator::singleton(Json::null())
          } else {
            let mut max_val = arr[0]
            for elem in arr {
              if compare_json(elem, max_val) > 0 {
                max_val = elem
              }
            }
            Iterator::singleton(max_val)
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
            None => Iterator::empty()
          }
      }

    // Variables
    @ast.Expr::Variable(name) =>
      match env.get(name) {
        Some(v) => Iterator::singleton(v)
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
          _ => left_results.iterator()
        }
      }
    }

    // Compound assignment operators: path += value
    @ast.Expr::AddAssign(path, value_expr) =>
      eval_with_env(
        @ast.Expr::Update(
          path,
          @ast.Expr::Operation(
            @ast.Expr::Identity,
            @ast.BinaryOp::Add,
            value_expr,
          ),
        ),
        input,
        env,
      )
    @ast.Expr::SubAssign(path, value_expr) =>
      eval_with_env(
        @ast.Expr::Update(
          path,
          @ast.Expr::Operation(
            @ast.Expr::Identity,
            @ast.BinaryOp::Subtract,
            value_expr,
          ),
        ),
        input,
        env,
      )
    @ast.Expr::MulAssign(path, value_expr) =>
      eval_with_env(
        @ast.Expr::Update(
          path,
          @ast.Expr::Operation(
            @ast.Expr::Identity,
            @ast.BinaryOp::Multiply,
            value_expr,
          ),
        ),
        input,
        env,
      )
    @ast.Expr::DivAssign(path, value_expr) =>
      eval_with_env(
        @ast.Expr::Update(
          path,
          @ast.Expr::Operation(
            @ast.Expr::Identity,
            @ast.BinaryOp::Divide,
            value_expr,
          ),
        ),
        input,
        env,
      )
    @ast.Expr::ModAssign(path, value_expr) =>
      eval_with_env(
        @ast.Expr::Update(
          path,
          @ast.Expr::Operation(
            @ast.Expr::Identity,
            @ast.BinaryOp::Modulo,
            value_expr,
          ),
        ),
        input,
        env,
      )
    @ast.Expr::AltAssign(path, value_expr) =>
      eval_with_env(
        @ast.Expr::Update(
          path,
          @ast.Expr::Alternative(@ast.Expr::Identity, value_expr),
        ),
        input,
        env,
      )

    // Format functions: @base64, @uri, etc.
    @ast.Expr::Format(format_name) =>
      match format_name {
        "base64" =>
          match input {
            String(s) => {
              // Simple base64 encoding implementation
              let bytes = @encoding/utf8.encode(s)
              let encoded = base64_encode(bytes)
              Iterator::singleton(Json::string(encoded))
            }
            _ => raise InterpreterError::TypeError("@base64 requires string")
          }
        "base64d" =>
          match input {
            String(s) => {
              // Simple base64 decoding implementation
              let decoded_bytes = base64_decode(s) catch {
                _ => raise InterpreterError::EvalError("Invalid base64")
              }
              let decoded_str = @encoding/utf8.decode(decoded_bytes) catch {
                _ => raise InterpreterError::EvalError("Invalid UTF-8")
              }
              Iterator::singleton(Json::string(decoded_str))
            }
            _ => raise InterpreterError::TypeError("@base64d requires string")
          }
        "uri" =>
          match input {
            String(s) => {
              let encoded = uri_encode(s)
              Iterator::singleton(Json::string(encoded))
            }
            _ => raise InterpreterError::TypeError("@uri requires string")
          }
        "csv" | "tsv" =>
          // Simple CSV/TSV formatting for arrays
          match input {
            Array(arr) => {
              let sep = if format_name == "csv" { "," } else { "\t" }
              let parts : Array[String] = []
              for item in arr {
                match item {
                  String(s) =>
                    // Quote if contains separator or quotes
                    if s.contains(sep) || s.contains("\"") {
                      let escaped = s.replace(old="\"", new="\"\"")
                      parts.push("\"\{escaped}\"")
                    } else {
                      parts.push(s)
                    }
                  Number(n, ..) => parts.push(n.to_string())
                  True => parts.push("true")
                  False => parts.push("false")
                  Null => parts.push("")
                  _ => parts.push(item.to_string())
                }
              }
              Iterator::singleton(Json::string(parts.join(sep)))
            }
            _ => raise InterpreterError::TypeError("@csv/@tsv requires array")
          }
        "json" => Iterator::singleton(Json::string(input.to_string()))
        "text" => Iterator::singleton(Json::string(input.to_string()))
        "html" =>
          match input {
            String(s) => {
              let escaped = html_escape(s)
              Iterator::singleton(Json::string(escaped))
            }
            _ => raise InterpreterError::TypeError("@html requires string")
          }
        _ =>
          raise InterpreterError::EvalError("Unknown format: @\{format_name}")
      }

    // String interpolation: "text \(expr) more"
    @ast.Expr::StringInterpolation(parts) => {
      let buf = @buffer.new()
      for pair in parts {
        let (text, expr_opt) = pair
        buf.write_string(text)
        match expr_opt {
          Some(expr) => {
            let results = eval_with_env(expr, input, env).collect()
            if not(results.is_empty()) {
              match results[0] {
                String(s) => buf.write_string(s)
                _ => buf.write_string(results[0].to_string())
              }
            }
          }
          None => ()
        }
      }
      Iterator::singleton(Json::string(buf.to_string()))
    }

    // Function definition: this is tricky because we need to update env
    // We handle this specially in the Pipe case when left is FunctionDef
    @ast.Expr::FunctionDef(_name, _params, _body) =>
      // Should not be evaluated directly, only through Pipe
      Iterator::singleton(input)

    // Function call: lookup and execute
    @ast.Expr::FunctionCall(name, args) =>
      match env.get_function(name) {
        Some((body, params)) =>
          if params.is_empty() {
            // Zero-parameter function - just execute with current input
            eval_with_env(body, input, env)
          } else if args.length() != params.length() {
            raise InterpreterError::EvalError(
              "Function \{name} expects \{params.length()} arguments, got \{args.length()}",
            )
          } else {
            // Evaluate arguments as expressions against current input
            let arg_values : Array[Json] = []
            for arg in args {
              let results = eval_with_env(arg, input, env).collect()
              arg_values.push(
                if results.is_empty() {
                  Json::null()
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
        None => raise InterpreterError::EvalError("Undefined function: \{name}")
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
      all_results.iterator()
    }

    // Reduce: aggregate using accumulator
    @ast.Expr::Reduce(expr, var_name, init_expr, update_expr) => {
      // Evaluate init expression to get initial accumulator
      let init_results = eval_with_env(init_expr, input, env).collect()
      if init_results.is_empty() {
        return Iterator::singleton(Json::null())
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
          Iterator::singleton(Json::array(sorted))
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
          Iterator::singleton(Json::array(result))
        }
        _ =>
          raise InterpreterError::TypeMismatch("array", @json.type_name(input))
      }

    // Update operator: modify value in place
    @ast.Expr::Update(path, update_expr) => {
      // Update value at path: get current value, apply update, set new value
      fn apply_update(
        obj : Json,
        p : @ast.Expr,
        upd : @ast.Expr,
      ) -> Json raise InterpreterError {
        match p {
          @ast.Expr::Identity => {
            // Update the whole object
            let results = eval_with_env(upd, obj, env).collect()
            if results.is_empty() {
              obj
            } else {
              results[0]
            }
          }
          @ast.Expr::Key(key) =>
            // Update at specific key in object
            match obj {
              Object(map) => {
                let current = match map.get(key) {
                  Some(v) => v
                  None => Json::null()
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
          @ast.Expr::Index(indices) =>
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
          @ast.Expr::Pipe(left, right) =>
            // Chained path like .a.b: navigate left, update right within result, put back
            match left {
              @ast.Expr::Identity =>
                // Optimize: . | .b is just .b
                apply_update(obj, right, upd)
              @ast.Expr::Key(key) =>
                // Navigate to key, update the right path within it
                match obj {
                  Object(map) => {
                    let current = match map.get(key) {
                      Some(v) => v
                      None => Json::null()
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
              @ast.Expr::Index(indices) =>
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
    @ast.Expr::Assign(_path, value_expr) => {
      // Evaluate the value expression
      let values = eval_with_env(value_expr, input, env).collect()
      if values.is_empty() {
        Iterator::singleton(input)
      } else {
        Iterator::singleton(values[0])
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
      results.iterator()
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

      Iterator::singleton(walk_value(input))
    }

    // Path expression: get path to a value
    @ast.Expr::Path(_expr) =>
      // Simplified: return empty array for now
      // Full implementation would track paths during evaluation
      Iterator::singleton(Json::array([]))

    // Additional numeric functions
    @ast.Expr::Round =>
      match input {
        Number(n, ..) => Iterator::singleton(Json::number(n.round()))
        _ =>
          raise InterpreterError::TypeMismatch("number", @json.type_name(input))
      }
    @ast.Expr::Ceil =>
      match input {
        Number(n, ..) => Iterator::singleton(Json::number(n.ceil()))
        _ =>
          raise InterpreterError::TypeMismatch("number", @json.type_name(input))
      }
    @ast.Expr::Abs =>
      match input {
        Number(n, ..) => Iterator::singleton(Json::number(n.abs()))
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
          Iterator::singleton(Json::array(json_parts))
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
          Iterator::singleton(Json::string(parts.join(sep)))
        }
        _ =>
          raise InterpreterError::TypeMismatch("array", @json.type_name(input))
      }
    @ast.Expr::StartsWith(prefix) =>
      match input {
        String(s) => Iterator::singleton(Json::boolean(s.has_prefix(prefix)))
        _ =>
          raise InterpreterError::TypeMismatch("string", @json.type_name(input))
      }
    @ast.Expr::EndsWith(suffix) =>
      match input {
        String(s) => Iterator::singleton(Json::boolean(s.has_suffix(suffix)))
        _ =>
          raise InterpreterError::TypeMismatch("string", @json.type_name(input))
      }
    @ast.Expr::Contains(expr) => {
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
    @ast.Expr::Inside(expr) => {
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
    @ast.Expr::Has(key) =>
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
    @ast.Expr::In(expr) => {
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
          Iterator::singleton(Json::object(result))
        }
        _ =>
          raise InterpreterError::TypeMismatch("array", @json.type_name(input))
      }
    @ast.Expr::WithEntries(expr) =>
      // Convert to entries, apply expr to each entry, convert back
      match input {
        Object(_) | Array(_) => {
          // to_entries
          let entries_results = eval_with_env(@ast.Expr::ToEntries, input, env).collect()
          if entries_results.is_empty() {
            return Iterator::singleton(input)
          }
          // Apply expression to each entry (like map)
          let entries_array = entries_results[0]
          let mapped_results = eval_with_env(
            @ast.Expr::Map(expr),
            entries_array,
            env,
          ).collect()
          if mapped_results.is_empty() {
            return Iterator::singleton(input)
          }
          // from_entries
          eval_with_env(@ast.Expr::FromEntries, mapped_results[0], env)
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
      results.iterator()
    }
    @ast.Expr::First =>
      match input {
        Array(arr) =>
          if arr.is_empty() {
            Iterator::empty()
          } else {
            Iterator::singleton(arr[0])
          }
        _ =>
          raise InterpreterError::TypeMismatch("array", @json.type_name(input))
      }
    @ast.Expr::Last =>
      match input {
        Array(arr) =>
          if arr.is_empty() {
            Iterator::empty()
          } else {
            Iterator::singleton(arr[arr.length() - 1])
          }
        _ =>
          raise InterpreterError::TypeMismatch("array", @json.type_name(input))
      }
    @ast.Expr::IndicesOf(expr) => {
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
        return Iterator::singleton(Json::null())
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
            None => Iterator::singleton(Json::null())
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
                Iterator::singleton(Json::null())
              }
            _ => Iterator::singleton(Json::null())
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
          Iterator::singleton(Json::boolean(result))
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
          Iterator::singleton(Json::boolean(result))
        }
        _ =>
          raise InterpreterError::TypeMismatch("array", @json.type_name(input))
      }

    // String trimming
    @ast.Expr::LTrimStr(prefix) =>
      match input {
        String(s) =>
          match s.strip_prefix(prefix[:]) {
            Some(rest) => Iterator::singleton(Json::string(rest.to_string()))
            None => Iterator::singleton(input)
          }
        _ =>
          raise InterpreterError::TypeMismatch("string", @json.type_name(input))
      }
    @ast.Expr::RTrimStr(suffix) =>
      match input {
        String(s) =>
          match s.strip_suffix(suffix[:]) {
            Some(rest) => Iterator::singleton(Json::string(rest.to_string()))
            None => Iterator::singleton(input)
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
              result.write_char(Int::unsafe_to_char(ch.to_int() - 32))
            } else {
              result.write_char(ch)
            }
          }
          Iterator::singleton(Json::string(result.to_string()))
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
              result.write_char(Int::unsafe_to_char(ch.to_int() + 32))
            } else {
              result.write_char(ch)
            }
          }
          Iterator::singleton(Json::string(result.to_string()))
        }
        _ =>
          raise InterpreterError::TypeMismatch("string", @json.type_name(input))
      }

    // Array functions
    @ast.Expr::Nth(n) =>
      match input {
        Array(arr) =>
          if n >= 0 && n < arr.length() {
            Iterator::singleton(arr[n])
          } else if n < 0 && -n <= arr.length() {
            Iterator::singleton(arr[arr.length() + n])
          } else {
            Iterator::empty()
          }
        _ =>
          raise InterpreterError::TypeMismatch("array", @json.type_name(input))
      }
    @ast.Expr::RIndex(search_expr) => {
      let needle_results = eval_with_env(search_expr, input, env).collect()
      if needle_results.is_empty() {
        return Iterator::singleton(Json::null())
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
            None => Iterator::singleton(Json::null())
          }
        }
        String(s) =>
          match needle {
            String(substr) => {
              match s.rev_find(substr[:]) {
                Some(pos) => Iterator::singleton(Json::number(pos.to_double()))
                None => Iterator::singleton(Json::null())
              }
            }
            _ => Iterator::singleton(Json::null())
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
      paths_list.iterator()
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
      paths_list.iterator()
    }
    @ast.Expr::GetPath(path_expr) => {
      let path_results = eval_with_env(path_expr, input, env).collect()
      if path_results.is_empty() {
        return Iterator::singleton(Json::null())
      }
      match path_results[0] {
        Array(path_arr) => {
          let mut current = input
          for segment in path_arr {
            match (current, segment) {
              (Object(obj), String(key)) =>
                match obj.get(key) {
                  Some(v) => current = v
                  None => return Iterator::singleton(Json::null())
                }
              (Array(arr), Number(idx, ..)) => {
                let i = idx.to_int()
                if i >= 0 && i < arr.length() {
                  current = arr[i]
                } else {
                  return Iterator::singleton(Json::null())
                }
              }
              _ => return Iterator::singleton(Json::null())
            }
          }
          Iterator::singleton(current)
        }
        _ => Iterator::singleton(Json::null())
      }
    }
    @ast.Expr::SetPath(path_expr, value_expr) => {
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
    @ast.Expr::DelPaths(paths_expr) => {
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
    @ast.Expr::Limit(n, expr) => eval_with_env(expr, input, env).take(n)
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
      Iterator::singleton(current)
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
      results.iterator()
    }

    // Math functions
    @ast.Expr::Pow(exp_expr) => {
      let exp_results = eval_with_env(exp_expr, input, env).collect()
      if exp_results.is_empty() {
        return Iterator::singleton(Json::null())
      }
      match (input, exp_results[0]) {
        (Number(base, ..), Number(exp, ..)) =>
          Iterator::singleton(Json::number(base.pow(exp)))
        _ =>
          raise InterpreterError::TypeMismatch("number", @json.type_name(input))
      }
    }
    @ast.Expr::Log =>
      match input {
        Number(n, ..) => Iterator::singleton(Json::number(@math.ln(n)))
        _ =>
          raise InterpreterError::TypeMismatch("number", @json.type_name(input))
      }
    @ast.Expr::Exp =>
      match input {
        Number(n, ..) => Iterator::singleton(Json::number(@math.exp(n)))
        _ =>
          raise InterpreterError::TypeMismatch("number", @json.type_name(input))
      }
    @ast.Expr::Sin =>
      match input {
        Number(n, ..) => Iterator::singleton(Json::number(@math.sin(n)))
        _ =>
          raise InterpreterError::TypeMismatch("number", @json.type_name(input))
      }
    @ast.Expr::Cos =>
      match input {
        Number(n, ..) => Iterator::singleton(Json::number(@math.cos(n)))
        _ =>
          raise InterpreterError::TypeMismatch("number", @json.type_name(input))
      }
    @ast.Expr::Tan =>
      match input {
        Number(n, ..) => Iterator::singleton(Json::number(@math.tan(n)))
        _ =>
          raise InterpreterError::TypeMismatch("number", @json.type_name(input))
      }
    @ast.Expr::Asin =>
      match input {
        Number(n, ..) => Iterator::singleton(Json::number(@math.asin(n)))
        _ =>
          raise InterpreterError::TypeMismatch("number", @json.type_name(input))
      }
    @ast.Expr::Acos =>
      match input {
        Number(n, ..) => Iterator::singleton(Json::number(@math.acos(n)))
        _ =>
          raise InterpreterError::TypeMismatch("number", @json.type_name(input))
      }
    @ast.Expr::Atan =>
      match input {
        Number(n, ..) => Iterator::singleton(Json::number(@math.atan(n)))
        _ =>
          raise InterpreterError::TypeMismatch("number", @json.type_name(input))
      }

    // Regex functions (simple implementations)
    @ast.Expr::Test(pattern) =>
      match input {
        String(s) => Iterator::singleton(Json::boolean(s.contains(pattern)))
        _ =>
          raise InterpreterError::TypeMismatch("string", @json.type_name(input))
      }
    @ast.Expr::Match(pattern) =>
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
        _ =>
          raise InterpreterError::TypeMismatch("string", @json.type_name(input))
      }
    @ast.Expr::Capture(_pattern) =>
      match input {
        String(_s) => Iterator::singleton(Json::object(Map::from_array([])))
        _ =>
          raise InterpreterError::TypeMismatch("string", @json.type_name(input))
      }
    @ast.Expr::Splits(pattern) =>
      match input {
        String(s) => {
          let parts = s.split(pattern).collect()
          parts.iterator().map(part => Json::string(part.to_string()))
        }
        _ =>
          raise InterpreterError::TypeMismatch("string", @json.type_name(input))
      }
    @ast.Expr::Sub(pattern, replacement) =>
      match input {
        String(s) =>
          Iterator::singleton(
            Json::string(s.replace(old=pattern[:], new=replacement[:])),
          )
        _ =>
          raise InterpreterError::TypeMismatch("string", @json.type_name(input))
      }
    @ast.Expr::GSub(pattern, replacement) =>
      match input {
        String(s) =>
          Iterator::singleton(
            Json::string(s.replace_all(old=pattern[:], new=replacement[:])),
          )
        _ =>
          raise InterpreterError::TypeMismatch("string", @json.type_name(input))
      }

    // Newly added features - corner case implementations
    @ast.Expr::MapValues(expr) =>
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
        _ =>
          raise InterpreterError::TypeMismatch("object", @json.type_name(input))
      }
    @ast.Expr::RangeFromTo(from_expr, to_expr) => {
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
        _ => raise InterpreterError::TypeMismatch("numbers", "non-numbers")
      }
    }
    @ast.Expr::RangeWithStep(from_expr, to_expr, step_expr) => {
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
        _ => raise InterpreterError::TypeMismatch("numbers", "non-numbers")
      }
    }
    @ast.Expr::FirstGen(gen_expr) => {
      let gen_results = eval_with_env(gen_expr, input, env).collect()
      if gen_results.is_empty() {
        Iterator::empty()
      } else {
        Iterator::singleton(gen_results[0])
      }
    }
    @ast.Expr::LastGen(gen_expr) => {
      let gen_results = eval_with_env(gen_expr, input, env).collect()
      if gen_results.is_empty() {
        Iterator::empty()
      } else {
        Iterator::singleton(gen_results[gen_results.length() - 1])
      }
    }
    @ast.Expr::Repeat(expr) => {
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
    @ast.Expr::Explode =>
      match input {
        String(s) => {
          let results : Array[Json] = []
          for char in s {
            results.push(Json::number(char.to_int().to_double()))
          }
          Iterator::singleton(Json::array(results))
        }
        _ =>
          raise InterpreterError::TypeMismatch("string", @json.type_name(input))
      }
    @ast.Expr::Implode =>
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
        _ =>
          raise InterpreterError::TypeMismatch("array", @json.type_name(input))
      }
    @ast.Expr::ToJsonString =>
      Iterator::singleton(Json::string(input.to_string()))
    @ast.Expr::FromJsonString =>
      match input {
        String(s) => {
          let parsed = @json.parse(s) catch {
            e =>
              raise InterpreterError::InvalidOperation("JSON parse error: \{e}")
          }
          Iterator::singleton(parsed)
        }
        _ =>
          raise InterpreterError::TypeMismatch("string", @json.type_name(input))
      }
    @ast.Expr::UniqueBy(expr) =>
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
        _ =>
          raise InterpreterError::TypeMismatch("array", @json.type_name(input))
      }
    @ast.Expr::MinBy(expr) =>
      match input {
        Array(arr) =>
          if arr.is_empty() {
            Iterator::singleton(Json::null())
          } else {
            let mut min_elem : Json = arr[0]
            let min_val_results = eval_with_env(expr, min_elem, env).collect()
            if min_val_results.is_empty() {
              return Iterator::singleton(Json::null())
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
        _ =>
          raise InterpreterError::TypeMismatch("array", @json.type_name(input))
      }
    @ast.Expr::MaxBy(expr) =>
      match input {
        Array(arr) =>
          if arr.is_empty() {
            Iterator::singleton(Json::null())
          } else {
            let mut max_elem : Json = arr[0]
            let max_val_results = eval_with_env(expr, max_elem, env).collect()
            if max_val_results.is_empty() {
              return Iterator::singleton(Json::null())
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
        _ =>
          raise InterpreterError::TypeMismatch("array", @json.type_name(input))
      }
    @ast.Expr::Combinations =>
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
        _ =>
          raise InterpreterError::TypeMismatch("array", @json.type_name(input))
      }
    @ast.Expr::Transpose =>
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
        _ =>
          raise InterpreterError::TypeMismatch("array", @json.type_name(input))
      }
    @ast.Expr::AnyGen(gen_expr, cond_expr) => {
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
    @ast.Expr::AllGen(gen_expr, cond_expr) => {
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
    @ast.Expr::Foreach(gen_expr, var_name, init_expr, update_expr, extract_expr) => {
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
    @ast.Expr::PathsWithFilter(filter_expr) => {
      let results : Array[Array[String]] = []
      collect_paths_with_filter(input, [], filter_expr, env, results)
      results.iterator().map(path => Json::array(path.map(Json::string)))
    }
    @ast.Expr::Scan(pattern) =>
      match input {
        String(s) => {
          let results : Array[Json] = []
          let slen = s.length()
          let plen = pattern.length()
          let mut i = 0
          while i <= slen - plen {
            let slice_result = s[i:i + plen] catch { _ => continue }
            if slice_result.to_string() == pattern {
              results.push(Json::string(pattern))
              i = i + plen
            } else {
              i = i + 1
            }
          }
          results.iterator()
        }
        _ =>
          raise InterpreterError::TypeMismatch("string", @json.type_name(input))
      }
  }
}

///|
fn collect_paths_with_filter(
  value : Json,
  path : Array[String],
  filter_expr : @ast.Expr,
  env : Env,
  results : Array[Array[String]],
) -> Unit raise InterpreterError {
  let filter_results = eval_with_env(filter_expr, value, env) catch {
    _ => return
  }
  let filter_results_arr = filter_results.collect()
  if not(filter_results_arr.is_empty()) {
    match filter_results_arr[0] {
      True => if not(path.is_empty()) { results.push(path.copy()) }
      _ => ()
    }
  }
  match value {
    Object(obj) =>
      for key, val in obj {
        let new_path = path.copy()
        new_path.push(key)
        collect_paths_with_filter(val, new_path, filter_expr, env, results)
      }
    Array(arr) =>
      for i = 0; i < arr.length(); i = i + 1 {
        let new_path = path.copy()
        new_path.push(i.to_string())
        collect_paths_with_filter(arr[i], new_path, filter_expr, env, results)
      }
    _ => ()
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
fn recurse_all(input : Json) -> Iterator[Json] {
  match input {
    Array(arr) =>
      Iterator::singleton(input).concat(arr.iterator().flat_map(recurse_all))
    Object(obj) => {
      let mut values : Array[Json] = []
      for _k, v in obj {
        values = values + [v]
      }
      Iterator::singleton(input).concat(values.iterator().flat_map(recurse_all))
    }
    _ => Iterator::singleton(input)
  }
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
      let new_obj = Map::from_array(obj.iterator().collect())
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
        let new_obj = Map::from_array(obj.iterator().collect())
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
        let new_obj = Map::from_array(obj.iterator().collect())
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

///|
/// URI encode a string
fn uri_encode(s : String) -> String {
  let buf = @buffer.new()
  for char in s {
    match char {
      'A'..='Z' | 'a'..='z' | '0'..='9' | '-' | '_' | '.' | '~' =>
        buf.write_char(char)
      ' ' => buf.write_char('+')
      _ => {
        // Percent encode
        let code = char.to_int()
        buf.write_string("%")
        buf.write_string(code.to_string()) // Simplified
      }
    }
  }
  buf.to_string()
}

///|
/// HTML escape a string
fn html_escape(s : String) -> String {
  let buf = @buffer.new()
  for char in s {
    match char {
      '<' => buf.write_string("&lt;")
      '>' => buf.write_string("&gt;")
      '&' => buf.write_string("&amp;")
      '"' => buf.write_string("&quot;")
      '\'' => buf.write_string("&#39;")
      _ => buf.write_char(char)
    }
  }
  buf.to_string()
}

///|
/// Simple base64 encoding
fn base64_encode(bytes : Bytes) -> String {
  let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
  let buf = @buffer.new()
  let len = bytes.length()
  let mut i = 0
  while i < len {
    let b1 : UInt = bytes[i].to_uint()
    let b2 : UInt = if i + 1 < len { bytes[i + 1].to_uint() } else { 0 }
    let b3 : UInt = if i + 2 < len { bytes[i + 2].to_uint() } else { 0 }
    let c1 = (b1 >> 2).reinterpret_as_int()
    let c2 = (((b1 & 0x03) << 4) | (b2 >> 4)).reinterpret_as_int()
    let c3 = (((b2 & 0x0f) << 2) | (b3 >> 6)).reinterpret_as_int()
    let c4 = (b3 & 0x3f).reinterpret_as_int()
    buf.write_char(chars.get_char(c1).unwrap())
    buf.write_char(chars.get_char(c2).unwrap())
    if i + 1 < len {
      buf.write_char(chars.get_char(c3).unwrap())
    } else {
      buf.write_char('=')
    }
    if i + 2 < len {
      buf.write_char(chars.get_char(c4).unwrap())
    } else {
      buf.write_char('=')
    }
    i = i + 3
  }
  buf.to_string()
}

///|
/// Simple base64 decoding
fn base64_decode(s : String) -> Bytes raise InterpreterError {
  let len = s.length()
  if len % 4 != 0 {
    raise InterpreterError::EvalError("Invalid base64")
  }

  fn base64_value(ch : Char) -> Int? {
    match ch {
      'A'..='Z' => Some(ch.to_int() - 'A'.to_int())
      'a'..='z' => Some(26 + ch.to_int() - 'a'.to_int())
      '0'..='9' => Some(52 + ch.to_int() - '0'.to_int())
      '+' => Some(62)
      '/' => Some(63)
      _ => None
    }
  }

  let buf : Array[Byte] = []
  let mut i = 0
  while i < len {
    let c1 = s.get_char(i).unwrap()
    let c2 = s.get_char(i + 1).unwrap()
    let c3 = s.get_char(i + 2).unwrap()
    let c4 = s.get_char(i + 3).unwrap()

    let v1 = match base64_value(c1) {
      Some(v) => v
      None => raise InterpreterError::EvalError("Invalid base64")
    }
    let v2 = match base64_value(c2) {
      Some(v) => v
      None => raise InterpreterError::EvalError("Invalid base64")
    }

    // Padding can only appear in the final 4-character quantum.
    if (c3 == '=' || c4 == '=') && i + 4 != len {
      raise InterpreterError::EvalError("Invalid base64")
    }

    let v1u : UInt = v1.reinterpret_as_uint()
    let v2u : UInt = v2.reinterpret_as_uint()
    let b1 : UInt = (v1u << 2) | (v2u >> 4)
    buf.push(b1.to_byte())

    if c3 != '=' {
      let v3 = match base64_value(c3) {
        Some(v) => v
        None => raise InterpreterError::EvalError("Invalid base64")
      }
      let v3u : UInt = v3.reinterpret_as_uint()
      let b2 : UInt = ((v2u & 0x0f) << 4) | (v3u >> 2)
      buf.push(b2.to_byte())

      if c4 != '=' {
        let v4 = match base64_value(c4) {
          Some(v) => v
          None => raise InterpreterError::EvalError("Invalid base64")
        }
        let v4u : UInt = v4.reinterpret_as_uint()
        let b3 : UInt = ((v3u & 0x03) << 6) | v4u
        buf.push(b3.to_byte())
      }
    } else if c4 != '=' {
      raise InterpreterError::EvalError("Invalid base64")
    }

    i = i + 4
  }

  Bytes::from_array(buf)
}
