///|
/// Evaluate range
fn eval_range(n : Int) -> Iterator[Json] {
  if n <= 0 {
    [].iterator()
  } else {
    Array::makei(n, i => Json::number(i.to_double())).iterator()
  }
}

///|
/// Evaluate first element
fn eval_first(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) =>
      match arr[:] {
        [] => Iterator::empty()
        [head, ..] => Iterator::singleton(head)
      }
    _ => raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate last element
fn eval_last(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) =>
      match last_in_view(arr[:]) {
        Some(value) => Iterator::singleton(value)
        None => Iterator::empty()
      }
    _ => raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
}

///|
fn last_in_view(arr : ArrayView[Json]) -> Json? {
  match arr {
    [] => None
    [head] => Some(head)
    [_head, .. tail] => last_in_view(tail)
  }
}
