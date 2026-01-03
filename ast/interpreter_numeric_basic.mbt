///|
/// Evaluate array sum
fn eval_add(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) => {
      let mut sum = 0.0
      for elem in arr {
        match elem {
          Number(n, ..) => sum = sum + n
          _ => ()
        }
      }
      Iterator::singleton(Json::number(sum))
    }
    _ => raise TypeMismatch("array", json_type_name(input))
  }
}

///|
/// Evaluate floor
fn eval_floor(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iterator::singleton(Json::number(n.floor()))
    _ => raise TypeMismatch("number", json_type_name(input))
  }
}

///|
/// Evaluate square root
fn eval_sqrt(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iterator::singleton(Json::number(n.sqrt()))
    _ => raise TypeMismatch("number", json_type_name(input))
  }
}

///|
/// Evaluate minimum over array
fn eval_min(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) =>
      if arr.is_empty() {
        Iterator::singleton(null)
      } else {
        let mut min_val = arr[0]
        for elem in arr {
          if compare_json(elem, min_val) < 0 {
            min_val = elem
          }
        }
        Iterator::singleton(min_val)
      }
    _ => raise TypeMismatch("array", json_type_name(input))
  }
}

///|
/// Evaluate maximum over array
fn eval_max(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) =>
      if arr.is_empty() {
        Iterator::singleton(null)
      } else {
        let mut max_val = arr[0]
        for elem in arr {
          if compare_json(elem, max_val) > 0 {
            max_val = elem
          }
        }
        Iterator::singleton(max_val)
      }
    _ => raise TypeMismatch("array", json_type_name(input))
  }
}
