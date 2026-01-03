///|
/// Evaluate Reduce
fn eval_reduce(
  expr : Expr,
  var_name : String,
  init_expr : Expr,
  update_expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let init_results = eval_with_env(init_expr, input, env).collect()
  if init_results.is_empty() {
    return Iterator::singleton(null)
  }
  let mut accumulator = init_results[0]
  for item in eval_with_env(expr, input, env) {
    let new_env = env.set(var_name, item)
    let update_results = eval_with_env(update_expr, accumulator, new_env).collect()
    if not(update_results.is_empty()) {
      accumulator = update_results[0]
    }
  }
  Iterator::singleton(accumulator)
}

///|
/// Evaluate SortBy
fn eval_sort_by(
  expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) => {
      let pairs : Array[(Json, Json)] = []
      for elem in arr {
        let keys = eval_with_env(expr, elem, env).collect()
        let sort_key = if keys.is_empty() { null } else { keys[0] }
        pairs.push((elem, sort_key))
      }
      let sorted_pairs = pairs.copy()
      sorted_pairs.sort_by(fn(a, b) { compare_json(a.1, b.1) })
      let sorted = sorted_pairs.map(fn(p) { p.0 })
      Iterator::singleton(Json::array(sorted))
    }
    _ => raise TypeMismatch("array", json_type_name(input))
  }
}

///|
/// Evaluate GroupBy
fn eval_group_by(
  expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) => {
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
      let result : Array[Json] = []
      for group in groups.values() {
        result.push(Json::array(group))
      }
      Iterator::singleton(Json::array(result))
    }
    _ => raise TypeMismatch("array", json_type_name(input))
  }
}

///|
/// Evaluate Any
fn eval_any(input : Json) -> Iterator[Json] raise InterpreterError {
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
}

///|
/// Evaluate All
fn eval_all(input : Json) -> Iterator[Json] raise InterpreterError {
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
}
