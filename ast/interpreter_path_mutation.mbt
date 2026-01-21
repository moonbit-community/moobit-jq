///|
/// Helper to set value at a path in JSON structure
fn set_at_path(root : Json, path : ArrayView[Json], value : Json) -> Json {
  match path {
    [] => value
    [segment, .. rest] =>
      match (root, segment) {
        (Object(obj), String(key)) => {
          let new_obj = obj.copy()
          let next_value = match rest {
            [] => value
            _ => {
              let current = obj.get(key).unwrap_or(null)
              set_at_path(current, rest, value)
            }
          }
          new_obj[key] = next_value
          Json::object(new_obj)
        }
        (Array(arr), Number(idx, ..)) => {
          let i = idx.to_int()
          if i >= 0 && i < arr.length() {
            let new_arr = arr.copy()
            let next_value = match rest {
              [] => value
              _ => set_at_path(arr[i], rest, value)
            }
            new_arr[i] = next_value
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
/// Helper to delete value at a path in JSON structure
fn delete_at_path(root : Json, path : ArrayView[Json]) -> Json {
  match path {
    [] => null
    [segment] =>
      match (root, segment) {
        (Object(obj), String(key)) => {
          let new_obj = obj.copy()
          new_obj.remove(key)
          Json::object(new_obj)
        }
        (Array(arr), Number(idx, ..)) => {
          let i = idx.to_int()
          if i >= 0 && i < arr.length() {
            let filtered = arr.mapi(fn(j, v) {
              if j == i {
                None
              } else {
                Some(v)
              }
            })
            Json::array(filtered.filter_map(fn(v) { v }))
          } else {
            root
          }
        }
        _ => root
      }
    [segment, .. rest] =>
      match (root, segment) {
        (Object(obj), String(key)) => {
          let new_obj = obj.copy()
          match obj.get(key) {
            Some(current) => new_obj[key] = delete_at_path(current, rest)
            None => ()
          }
          Json::object(new_obj)
        }
        (Array(arr), Number(idx, ..)) => {
          let i = idx.to_int()
          if i >= 0 && i < arr.length() {
            let new_arr = arr.copy()
            new_arr[i] = delete_at_path(arr[i], rest)
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
/// Evaluate SetPath
fn eval_set_path(
  path_expr : Expr,
  value_expr : Expr,
  input : Json,
  env : Env,
) -> Iter[Json] raise InterpreterError {
  let path_results = eval_with_env(path_expr, input, env).collect()
  let value_results = eval_with_env(value_expr, input, env).collect()
  match (path_results, value_results) {
    ([Array(path_arr), ..], [value, ..]) =>
      match path_arr[:] {
        [] => Iter::singleton(value)
        path => Iter::singleton(set_at_path(input, path, value))
      }
    _ => Iter::singleton(input)
  }
}

///|
/// Evaluate DelPaths
fn eval_del_paths(
  paths_expr : Expr,
  input : Json,
  env : Env,
) -> Iter[Json] raise InterpreterError {
  match eval_with_env(paths_expr, input, env).collect() {
    [Array(paths_arr), ..] =>
      Iter::singleton(
        paths_arr.fold(init=input, fn(acc, path_json) {
          match path_json {
            Array(path) => delete_at_path(acc, path[:])
            _ => acc
          }
        }),
      )
    _ => Iter::singleton(input)
  }
}
