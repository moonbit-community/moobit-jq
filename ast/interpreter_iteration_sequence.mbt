///|
/// Evaluate range
fn eval_range(n : Int) -> Iter[Json] {
  if n <= 0 {
    Iter::empty()
  } else {
    Array::makei(n, i => Json::number(i.to_double())).iter()
  }
}

///|
/// Evaluate first element
fn eval_first(input : Json) -> Iter[Json] raise InterpreterError {
  guard input is Array(arr) else {
    raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
  match arr[:] {
    [first, ..] => Iter::singleton(first)
    [] => Iter::empty()
  }
}

///|
/// Evaluate last element
fn eval_last(input : Json) -> Iter[Json] raise InterpreterError {
  guard input is Array(arr) else {
    raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
  match arr.last() {
    Some(value) => Iter::singleton(value)
    None => Iter::empty()
  }
}
