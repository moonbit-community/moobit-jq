///|
fn collect_paths_with_filter(
  value : Json,
  path : Array[String],
  filter_expr : Expr,
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
        let current = obj.get(key).unwrap_or(null)
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
    return null
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
/// Evaluate Paths
fn eval_paths(input : Json) -> Iterator[Json] {
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

///|
/// Evaluate LeafPaths
fn eval_leaf_paths(input : Json) -> Iterator[Json] {
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

///|
/// Evaluate GetPath
fn eval_get_path(
  path_expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let path_results = eval_with_env(path_expr, input, env).collect()
  if path_results.is_empty() {
    return Iterator::singleton(null)
  }
  match path_results[0] {
    Array(path_arr) => {
      let mut current = input
      for segment in path_arr {
        match (current, segment) {
          (Object(obj), String(key)) =>
            match obj.get(key) {
              Some(v) => current = v
              None => return Iterator::singleton(null)
            }
          (Array(arr), Number(idx, ..)) => {
            let i = idx.to_int()
            if i >= 0 && i < arr.length() {
              current = arr[i]
            } else {
              return Iterator::singleton(null)
            }
          }
          _ => return Iterator::singleton(null)
        }
      }
      Iterator::singleton(current)
    }
    _ => Iterator::singleton(null)
  }
}

///|
/// Evaluate SetPath
fn eval_set_path(
  path_expr : Expr,
  value_expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
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

///|
/// Evaluate DelPaths
fn eval_del_paths(
  paths_expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
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
