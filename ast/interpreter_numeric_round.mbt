///|
/// Evaluate rounding
fn eval_round(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iterator::singleton(Json::number(n.round()))
    _ => raise TypeMismatch("number", json_type_name(input))
  }
}

///|
/// Evaluate ceiling
fn eval_ceil(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iterator::singleton(Json::number(n.ceil()))
    _ => raise TypeMismatch("number", json_type_name(input))
  }
}

///|
/// Evaluate absolute value
fn eval_abs(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iterator::singleton(Json::number(n.abs()))
    _ => raise TypeMismatch("number", json_type_name(input))
  }
}
