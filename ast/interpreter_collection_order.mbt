///|
/// Evaluate UniqueBy
fn eval_unique_by(
  expr : Expr,
  input : Json,
  env : Env,
) -> Iter[Json] raise InterpreterError {
  match input {
    Array(arr) => {
      let seen : Map[String, Bool] = {}
      let results : Array[Json] = []
      for elem in arr {
        match eval_with_env(expr, elem, env).collect() {
          [first, ..] => {
            let key = first.to_string()
            if not(seen.contains(key)) {
              seen[key] = true
              results.push(elem)
            }
          }
          [] => ()
        }
      }
      Iter::singleton(Json::array(results))
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
) -> Iter[Json] raise InterpreterError {
  match input {
    Array(arr) =>
      match pick_min_by(expr, env, arr[:]) {
        Some(elem) => Iter::singleton(elem)
        None => Iter::singleton(null)
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
) -> Iter[Json] raise InterpreterError {
  match input {
    Array(arr) =>
      match pick_max_by(expr, env, arr[:]) {
        Some(elem) => Iter::singleton(elem)
        None => Iter::singleton(null)
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
  let mut min_elem = current_elem
  let mut min_val = current_val
  for elem in rest {
    match eval_with_env(expr, elem, env).collect() {
      [] => ()
      [val, ..] =>
        if compare_json(val, min_val) < 0 {
          min_elem = elem
          min_val = val
        }
    }
  }
  (min_elem, min_val)
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
  let mut max_elem = current_elem
  let mut max_val = current_val
  for elem in rest {
    match eval_with_env(expr, elem, env).collect() {
      [] => ()
      [val, ..] =>
        if compare_json(val, max_val) > 0 {
          max_elem = elem
          max_val = val
        }
    }
  }
  (max_elem, max_val)
}
