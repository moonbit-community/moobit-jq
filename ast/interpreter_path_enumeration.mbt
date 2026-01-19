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
        path.push(key)
        collect_paths_with_filter(val, path, filter_expr, env, results)
        ignore(path.pop())
      }
    Array(arr) => {
      let len = arr.length()
      for i in 0..<len {
        path.push(i.to_string())
        collect_paths_with_filter(arr[i], path, filter_expr, env, results)
        ignore(path.pop())
      }
    }
    _ => ()
  }
}

///|
/// Evaluate Paths
fn eval_paths(input : Json) -> Iter[Json] {
  let paths_list : Array[Json] = []
  fn collect_paths(value : Json, path : Array[Json]) {
    match value {
      Object(obj) =>
        for key, val in obj {
          path.push(Json::string(key))
          paths_list.push(Json::array(path.copy()))
          collect_paths(val, path)
          ignore(path.pop())
        }
      Array(arr) => {
        let len = arr.length()
        for i in 0..<len {
          path.push(Json::number(i.to_double()))
          paths_list.push(Json::array(path.copy()))
          collect_paths(arr[i], path)
          ignore(path.pop())
        }
      }
      _ => ()
    }
  }

  collect_paths(input, [])
  paths_list.iter()
}

///|
/// Evaluate LeafPaths
fn eval_leaf_paths(input : Json) -> Iter[Json] {
  let paths_list : Array[Json] = []
  fn collect_leaf_paths(value : Json, path : Array[Json]) {
    match value {
      Object(obj) =>
        if obj.is_empty() {
          paths_list.push(Json::array(path.copy()))
        } else {
          for key, val in obj {
            path.push(Json::string(key))
            collect_leaf_paths(val, path)
            ignore(path.pop())
          }
        }
      Array(arr) =>
        if arr.is_empty() {
          paths_list.push(Json::array(path.copy()))
        } else {
          let len = arr.length()
          for i in 0..<len {
            path.push(Json::number(i.to_double()))
            collect_leaf_paths(arr[i], path)
            ignore(path.pop())
          }
        }
      _ => paths_list.push(Json::array(path.copy()))
    }
  }

  collect_leaf_paths(input, [])
  paths_list.iter()
}

///|
/// Evaluate PathsWithFilter
fn eval_paths_with_filter(
  filter_expr : Expr,
  input : Json,
  env : Env,
) -> Iter[Json] raise InterpreterError {
  let results : Array[Array[String]] = []
  collect_paths_with_filter(input, [], filter_expr, env, results)
  results.iter().map(path => Json::array(path.map(Json::string)))
}
