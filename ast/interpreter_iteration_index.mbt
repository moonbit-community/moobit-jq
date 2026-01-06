///|
/// Evaluate indices_of
fn eval_indices_of(
  expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  match eval_with_env(expr, input, env).collect() {
    [] => Iterator::singleton(Json::array([]))
    [needle, ..] =>
      match input {
        Array(arr) =>
          Iterator::singleton(Json::array(indices_of_array(arr[:], needle, 0)))
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
        _ =>
          raise TypeMismatch(
            "array/string",
            @ast_internal.json_type_name(input),
          )
      }
  }
}

///|
/// Evaluate index_of
fn eval_index_of(
  expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  match eval_with_env(expr, input, env).collect() {
    [] => Iterator::singleton(null)
    [needle, ..] =>
      match input {
        Array(arr) =>
          match find_first_index(arr[:], needle, 0) {
            Some(idx) => Iterator::singleton(Json::number(idx.to_double()))
            None => Iterator::singleton(null)
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
        _ =>
          raise TypeMismatch(
            "array/string",
            @ast_internal.json_type_name(input),
          )
      }
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
    _ => raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate rindex
fn eval_rindex(
  search_expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  match eval_with_env(search_expr, input, env).collect() {
    [] => Iterator::singleton(null)
    [needle, ..] =>
      match input {
        Array(arr) =>
          match find_last_index(arr[:], needle, 0) {
            Some(idx) => Iterator::singleton(Json::number(idx.to_double()))
            None => Iterator::singleton(null)
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
        _ =>
          raise TypeMismatch(
            "array or string",
            @ast_internal.json_type_name(input),
          )
      }
  }
}

///|
fn indices_of_array(
  arr : ArrayView[Json],
  needle : Json,
  offset : Int,
) -> Array[Json] {
  match arr {
    [] => []
    [head, .. tail] =>
      if head == needle {
        [Json::number(offset.to_double())] +
        indices_of_array(tail, needle, offset + 1)
      } else {
        indices_of_array(tail, needle, offset + 1)
      }
  }
}

///|
fn find_first_index(arr : ArrayView[Json], needle : Json, offset : Int) -> Int? {
  match arr {
    [] => None
    [head, .. tail] =>
      if head == needle {
        Some(offset)
      } else {
        find_first_index(tail, needle, offset + 1)
      }
  }
}

///|
fn find_last_index(arr : ArrayView[Json], needle : Json, offset : Int) -> Int? {
  match arr {
    [] => None
    [head, .. tail] => {
      let tail_idx = find_last_index(tail, needle, offset + 1)
      match tail_idx {
        Some(_) => tail_idx
        None => if head == needle { Some(offset) } else { None }
      }
    }
  }
}
