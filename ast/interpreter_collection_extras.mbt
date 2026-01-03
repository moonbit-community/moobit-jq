///|
/// Evaluate MapValues
fn eval_map_values(
  expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  match input {
    Object(obj) => {
      let result : Map[String, Json] = {}
      for key, value in obj {
        let transformed_results = eval_with_env(expr, value, env).collect()
        if not(transformed_results.is_empty()) {
          result[key] = transformed_results[0]
        }
      }
      Iterator::singleton(Json::object(result))
    }
    _ => raise TypeMismatch("object", json_type_name(input))
  }
}

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
    _ => raise TypeMismatch("array", json_type_name(input))
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
      if arr.is_empty() {
        Iterator::singleton(null)
      } else {
        let mut min_elem : Json = arr[0]
        let min_val_results = eval_with_env(expr, min_elem, env).collect()
        if min_val_results.is_empty() {
          return Iterator::singleton(null)
        }
        let mut min_val = min_val_results[0]
        for i = 1; i < arr.length(); i = i + 1 {
          let elem = arr[i]
          let val_results = eval_with_env(expr, elem, env).collect()
          if not(val_results.is_empty()) {
            let val = val_results[0]
            if compare_json(val, min_val) < 0 {
              min_val = val
              min_elem = elem
            }
          }
        }
        Iterator::singleton(min_elem)
      }
    _ => raise TypeMismatch("array", json_type_name(input))
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
      if arr.is_empty() {
        Iterator::singleton(null)
      } else {
        let mut max_elem : Json = arr[0]
        let max_val_results = eval_with_env(expr, max_elem, env).collect()
        if max_val_results.is_empty() {
          return Iterator::singleton(null)
        }
        let mut max_val = max_val_results[0]
        for i = 1; i < arr.length(); i = i + 1 {
          let elem = arr[i]
          let val_results = eval_with_env(expr, elem, env).collect()
          if not(val_results.is_empty()) {
            let val = val_results[0]
            if compare_json(val, max_val) > 0 {
              max_val = val
              max_elem = elem
            }
          }
        }
        Iterator::singleton(max_elem)
      }
    _ => raise TypeMismatch("array", json_type_name(input))
  }
}

///|
/// Evaluate Combinations
fn eval_combinations(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) => {
      let arrays : Array[Array[Json]] = []
      for elem in arr {
        match elem {
          Array(inner) => arrays.push(inner)
          _ => return Iterator::empty()
        }
      }
      if arrays.is_empty() {
        return Iterator::empty()
      }
      let mut results : Array[Array[Json]] = [[]]
      for arr_item in arrays {
        let new_results : Array[Array[Json]] = []
        for res in results {
          for item in arr_item {
            let new_res = res.copy()
            new_res.push(item)
            new_results.push(new_res)
          }
        }
        results = new_results
      }
      results.iterator().map(Json::array)
    }
    _ => raise TypeMismatch("array", json_type_name(input))
  }
}

///|
/// Evaluate Transpose
fn eval_transpose(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) => {
      let mut max_len = 0
      for elem in arr {
        match elem {
          Array(inner) =>
            if inner.length() > max_len {
              max_len = inner.length()
            }
          _ => ()
        }
      }
      let results : Array[Array[Json]] = []
      for col = 0; col < max_len; col = col + 1 {
        let row : Array[Json] = []
        for elem in arr {
          match elem {
            Array(inner) => if col < inner.length() { row.push(inner[col]) }
            _ => ()
          }
        }
        results.push(row)
      }
      Iterator::singleton(Json::array(results.map(Json::array)))
    }
    _ => raise TypeMismatch("array", json_type_name(input))
  }
}
