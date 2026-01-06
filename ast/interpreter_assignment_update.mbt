///|
/// Evaluate Update operator
fn eval_update(
  path : Expr,
  update_expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  fn apply_update(
    obj : Json,
    p : Expr,
    upd : Expr,
  ) -> Json raise InterpreterError {
    match p {
      Identity => {
        let results = eval_with_env(upd, obj, env).collect()
        if results.is_empty() {
          obj
        } else {
          results[0]
        }
      }
      Key(key) =>
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
        match left {
          Identity => apply_update(obj, right, upd)
          Key(key) =>
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
            let navigated = eval_with_env(left, obj, env).collect()
            if navigated.is_empty() {
              return obj
            }
            apply_update(navigated[0], right, upd)
          }
        }
      _ => {
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
