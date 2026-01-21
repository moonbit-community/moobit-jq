///|
/// Evaluate GetPath
fn eval_get_path(
  path_expr : Expr,
  input : Json,
  env : Env,
) -> Iter[Json] raise InterpreterError {
  match eval_with_env(path_expr, input, env).collect() {
    [Array(path_arr), ..] =>
      match get_at_path(input, path_arr[:]) {
        Some(value) => Iter::singleton(value)
        None => Iter::singleton(null)
      }
    _ => Iter::singleton(null)
  }
}

///|
fn get_at_path(current : Json, path : ArrayView[Json]) -> Json? {
  match path {
    [] => Some(current)
    [segment, .. rest] =>
      match (current, segment) {
        (Object(obj), String(key)) =>
          match obj.get(key) {
            Some(v) => get_at_path(v, rest)
            None => None
          }
        (Array(arr), Number(idx, ..)) => {
          let i = idx.to_int()
          if i >= 0 && i < arr.length() {
            get_at_path(arr[i], rest)
          } else {
            None
          }
        }
        _ => None
      }
  }
}

///|
/// Evaluate Path (placeholder)
fn eval_path(_expr : Expr) -> Iter[Json] {
  Iter::singleton(Json::array([]))
}
