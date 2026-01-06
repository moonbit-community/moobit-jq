///|
/// Evaluate UniqueBy
fn eval_unique_by(
  expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
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
    _ => raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate MinBy
fn eval_min_by(
  expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) =>
      match pick_min_by(expr, env, arr[:]) {
        Some(elem) => Iterator::singleton(elem)
        None => Iterator::singleton(null)
      }
    _ => raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate MaxBy
fn eval_max_by(
  expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) =>
      match pick_max_by(expr, env, arr[:]) {
        Some(elem) => Iterator::singleton(elem)
        None => Iterator::singleton(null)
      }
    _ => raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
}

///|
fn pick_min_by(
  expr : Expr,
  env : Env,
  arr : ArrayView[Json],
) -> Json? raise InterpreterError {
  match arr {
    [] => None
    [head, .. tail] =>
      match eval_with_env(expr, head, env).collect() {
        [] => None
        [head_val, ..] => {
          let (min_elem, _min_val) = reduce_min_by(
            expr, env, head, head_val, tail,
          )
          Some(min_elem)
        }
      }
  }
}

///|
fn reduce_min_by(
  expr : Expr,
  env : Env,
  current_elem : Json,
  current_val : Json,
  rest : ArrayView[Json],
) -> (Json, Json) raise InterpreterError {
  match rest {
    [] => (current_elem, current_val)
    [elem, .. tail] =>
      match eval_with_env(expr, elem, env).collect() {
        [] => reduce_min_by(expr, env, current_elem, current_val, tail)
        [val, ..] =>
          if compare_json(val, current_val) < 0 {
            reduce_min_by(expr, env, elem, val, tail)
          } else {
            reduce_min_by(expr, env, current_elem, current_val, tail)
          }
      }
  }
}

///|
fn pick_max_by(
  expr : Expr,
  env : Env,
  arr : ArrayView[Json],
) -> Json? raise InterpreterError {
  match arr {
    [] => None
    [head, .. tail] =>
      match eval_with_env(expr, head, env).collect() {
        [] => None
        [head_val, ..] => {
          let (max_elem, _max_val) = reduce_max_by(
            expr, env, head, head_val, tail,
          )
          Some(max_elem)
        }
      }
  }
}

///|
fn reduce_max_by(
  expr : Expr,
  env : Env,
  current_elem : Json,
  current_val : Json,
  rest : ArrayView[Json],
) -> (Json, Json) raise InterpreterError {
  match rest {
    [] => (current_elem, current_val)
    [elem, .. tail] =>
      match eval_with_env(expr, elem, env).collect() {
        [] => reduce_max_by(expr, env, current_elem, current_val, tail)
        [val, ..] =>
          if compare_json(val, current_val) > 0 {
            reduce_max_by(expr, env, elem, val, tail)
          } else {
            reduce_max_by(expr, env, current_elem, current_val, tail)
          }
      }
  }
}
