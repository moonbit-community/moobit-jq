///|
/// Evaluate indices_of
fn eval_indices_of(
  expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let needle_results = eval_with_env(expr, input, env).collect()
  if needle_results.is_empty() {
    return Iterator::singleton(Json::array([]))
  }
  let needle = needle_results[0]
  match input {
    Array(arr) => {
      let indices : Array[Json] = []
      for i = 0; i < arr.length(); i = i + 1 {
        if arr[i] == needle {
          indices.push(Json::number(i.to_double()))
        }
      }
      Iterator::singleton(Json::array(indices))
    }
    String(s) =>
      match needle {
        String(substr) => {
          let indices : Array[Json] = []
          if s.contains(substr) {
            ()
          }
          Iterator::singleton(Json::array(indices))
        }
        _ => Iterator::singleton(Json::array([]))
      }
    _ => raise TypeMismatch("array/string", json_type_name(input))
  }
}

///|
/// Evaluate index_of
fn eval_index_of(
  expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let needle_results = eval_with_env(expr, input, env).collect()
  if needle_results.is_empty() {
    return Iterator::singleton(null)
  }
  let needle = needle_results[0]
  match input {
    Array(arr) => {
      let mut found_idx : Int? = None
      for i = 0; i < arr.length(); i = i + 1 {
        if arr[i] == needle {
          found_idx = Some(i)
          break
        }
      }
      match found_idx {
        Some(idx) => Iterator::singleton(Json::number(idx.to_double()))
        None => Iterator::singleton(null)
      }
    }
    String(s) =>
      match needle {
        String(substr) =>
          if s.contains(substr) {
            Iterator::singleton(Json::number(0.0))
          } else {
            Iterator::singleton(null)
          }
        _ => Iterator::singleton(null)
      }
    _ => raise TypeMismatch("array/string", json_type_name(input))
  }
}

///|
/// Evaluate nth
fn eval_nth(n : Int, input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) =>
      if n >= 0 && n < arr.length() {
        Iterator::singleton(arr[n])
      } else if n < 0 && -n <= arr.length() {
        Iterator::singleton(arr[arr.length() + n])
      } else {
        Iterator::empty()
      }
    _ => raise TypeMismatch("array", json_type_name(input))
  }
}

///|
/// Evaluate rindex
fn eval_rindex(
  search_expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let needle_results = eval_with_env(search_expr, input, env).collect()
  if needle_results.is_empty() {
    return Iterator::singleton(null)
  }
  let needle = needle_results[0]
  match input {
    Array(arr) => {
      let mut last_index : Int? = None
      for i = 0; i < arr.length(); i = i + 1 {
        if arr[i] == needle {
          last_index = Some(i)
        }
      }
      match last_index {
        Some(idx) => Iterator::singleton(Json::number(idx.to_double()))
        None => Iterator::singleton(null)
      }
    }
    String(s) =>
      match needle {
        String(substr) =>
          match s.rev_find(substr[:]) {
            Some(pos) => Iterator::singleton(Json::number(pos.to_double()))
            None => Iterator::singleton(null)
          }
        _ => Iterator::singleton(null)
      }
    _ => raise TypeMismatch("array or string", json_type_name(input))
  }
}
