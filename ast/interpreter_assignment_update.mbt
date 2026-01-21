///|
/// Evaluate Update operator
fn eval_update(
  path : Expr,
  update_expr : Expr,
  input : Json,
  env : Env,
) -> Iter[Json] raise InterpreterError {
  fn apply_update(
    obj : Json,
    p : Expr,
    upd : Expr,
  ) -> Json raise InterpreterError {
    match p {
      Identity =>
        match eval_with_env(upd, obj, env).collect() {
          [first, ..] => first
          [] => obj
        }
      Key(key) =>
        match obj {
          Object(map) => {
            let current = map.get(key).unwrap_or(null)
            match eval_with_env(upd, current, env).collect() {
              [updated, ..] => {
                let new_map = map.copy()
                new_map[key] = updated
                Json::object(new_map)
              }
              [] => obj
            }
          }
          _ => obj
        }
      Index(indices) =>
        match (obj, indices) {
          (Array(arr), [idx]) =>
            if idx < 0 || idx >= arr.length() {
              obj
            } else {
              match eval_with_env(upd, arr[idx], env).collect() {
                [updated, ..] => {
                  let new_arr = arr.copy()
                  new_arr[idx] = updated
                  Json::array(new_arr)
                }
                [] => obj
              }
            }
          _ => obj
        }
      Pipe(left, right) =>
        match left {
          Identity => apply_update(obj, right, upd)
          Key(key) =>
            match obj {
              Object(map) => {
                let current = map.get(key).unwrap_or(null)
                let updated = apply_update(current, right, upd)
                let new_map = map.copy()
                new_map[key] = updated
                Json::object(new_map)
              }
              _ => obj
            }
          Index(indices) =>
            match (obj, indices) {
              (Array(arr), [idx]) =>
                if idx < 0 || idx >= arr.length() {
                  obj
                } else {
                  let updated = apply_update(arr[idx], right, upd)
                  let new_arr = arr.copy()
                  new_arr[idx] = updated
                  Json::array(new_arr)
                }
              _ => obj
            }
          _ =>
            match eval_with_env(left, obj, env).collect() {
              [navigated, ..] => apply_update(navigated, right, upd)
              [] => obj
            }
        }
      _ =>
        match eval_with_env(p, obj, env).collect() {
          [current, ..] =>
            match eval_with_env(upd, current, env).collect() {
              [updated, ..] => updated
              [] => obj
            }
          [] => obj
        }
    }
  }

  Iter::singleton(apply_update(input, path, update_expr))
}
