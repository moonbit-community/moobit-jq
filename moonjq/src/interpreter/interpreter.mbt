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
