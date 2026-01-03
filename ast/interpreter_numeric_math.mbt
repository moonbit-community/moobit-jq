///|
/// Evaluate power
fn eval_pow(
  exp_expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let exp_results = eval_with_env(exp_expr, input, env).collect()
  if exp_results.is_empty() {
    return Iterator::singleton(null)
  }
  match (input, exp_results[0]) {
    (Number(base, ..), Number(exp, ..)) =>
      Iterator::singleton(Json::number(@math.pow(base, exp)))
    _ => raise TypeMismatch("number", json_type_name(input))
  }
}

///|
/// Evaluate natural log
fn eval_log(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iterator::singleton(Json::number(@math.ln(n)))
    _ => raise TypeMismatch("number", json_type_name(input))
  }
}

///|
/// Evaluate exponent
fn eval_exp(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iterator::singleton(Json::number(@math.exp(n)))
    _ => raise TypeMismatch("number", json_type_name(input))
  }
}

///|
/// Evaluate sine
fn eval_sin(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iterator::singleton(Json::number(@math.sin(n)))
    _ => raise TypeMismatch("number", json_type_name(input))
  }
}

///|
/// Evaluate cosine
fn eval_cos(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iterator::singleton(Json::number(@math.cos(n)))
    _ => raise TypeMismatch("number", json_type_name(input))
  }
}

///|
/// Evaluate tangent
fn eval_tan(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iterator::singleton(Json::number(@math.tan(n)))
    _ => raise TypeMismatch("number", json_type_name(input))
  }
}

///|
/// Evaluate arcsine
fn eval_asin(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iterator::singleton(Json::number(@math.asin(n)))
    _ => raise TypeMismatch("number", json_type_name(input))
  }
}

///|
/// Evaluate arccosine
fn eval_acos(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iterator::singleton(Json::number(@math.acos(n)))
    _ => raise TypeMismatch("number", json_type_name(input))
  }
}

///|
/// Evaluate arctangent
fn eval_atan(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iterator::singleton(Json::number(@math.atan(n)))
    _ => raise TypeMismatch("number", json_type_name(input))
  }
}
