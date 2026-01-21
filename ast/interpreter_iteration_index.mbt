///|
/// Evaluate indices_of
fn eval_indices_of(
  expr : Expr,
  input : Json,
  env : Env,
) -> Iter[Json] raise InterpreterError {
  match eval_with_env(expr, input, env).collect() {
    [] => Iter::singleton(Json::array([]))
    [needle, ..] =>
      match input {
        Array(arr) =>
          Iter::singleton(Json::array(indices_of_array(arr[:], needle)))
        String(s) =>
          match needle {
            String(substr) => {
              let indices : Array[Json] = []
              if s.contains(substr) {
                ()
              }
              Iter::singleton(Json::array(indices))
            }
            _ => Iter::singleton(Json::array([]))
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
) -> Iter[Json] raise InterpreterError {
  match eval_with_env(expr, input, env).collect() {
    [] => Iter::singleton(null)
    [needle, ..] =>
      match input {
        Array(arr) =>
          match find_first_index(arr[:], needle) {
            Some(idx) => Iter::singleton(Json::number(idx.to_double()))
            None => Iter::singleton(null)
          }
        String(s) =>
          match needle {
            String(substr) =>
              if s.contains(substr) {
                Iter::singleton(Json::number(0.0))
              } else {
                Iter::singleton(null)
              }
            _ => Iter::singleton(null)
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
fn eval_nth(n : Int, input : Json) -> Iter[Json] raise InterpreterError {
  match input {
    Array(arr) =>
      if n >= 0 && n < arr.length() {
        Iter::singleton(arr[n])
      } else if n < 0 && -n <= arr.length() {
        Iter::singleton(arr[arr.length() + n])
      } else {
        Iter::empty()
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
) -> Iter[Json] raise InterpreterError {
  match eval_with_env(search_expr, input, env).collect() {
    [] => Iter::singleton(null)
    [needle, ..] =>
      match input {
        Array(arr) =>
          match find_last_index(arr[:], needle) {
            Some(idx) => Iter::singleton(Json::number(idx.to_double()))
            None => Iter::singleton(null)
          }
        String(s) =>
          match needle {
            String(substr) =>
              match s.rev_find(substr[:]) {
                Some(pos) => Iter::singleton(Json::number(pos.to_double()))
                None => Iter::singleton(null)
              }
            _ => Iter::singleton(null)
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
fn indices_of_array(arr : ArrayView[Json], needle : Json) -> Array[Json] {
  let result : Array[Json] = []
  for i in 0..<arr.length() {
    if arr[i] == needle {
      result.push(Json::number(i.to_double()))
    }
  }
  result
}

///|
fn find_first_index(arr : ArrayView[Json], needle : Json) -> Int? {
  for i in 0..<arr.length() {
    if arr[i] == needle {
      return Some(i)
    }
  }
  None
}

///|
fn find_last_index(arr : ArrayView[Json], needle : Json) -> Int? {
  let mut found : Int? = None
  for i in 0..<arr.length() {
    if arr[i] == needle {
      found = Some(i)
    }
  }
  found
}
