///|
/// Evaluate rounding
fn eval_round(input : Json) -> Iter[Json] raise InterpreterError {
  guard input is Number(n, ..) else {
    raise TypeMismatch("number", @ast_internal.json_type_name(input))
  }
  Iter::singleton(Json::number(n.round()))
}

///|
/// Evaluate ceiling
fn eval_ceil(input : Json) -> Iter[Json] raise InterpreterError {
  guard input is Number(n, ..) else {
    raise TypeMismatch("number", @ast_internal.json_type_name(input))
  }
  Iter::singleton(Json::number(n.ceil()))
}

///|
/// Evaluate absolute value
fn eval_abs(input : Json) -> Iter[Json] raise InterpreterError {
  guard input is Number(n, ..) else {
    raise TypeMismatch("number", @ast_internal.json_type_name(input))
  }
  Iter::singleton(Json::number(n.abs()))
}
