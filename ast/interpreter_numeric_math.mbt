///|
/// Evaluate power
fn eval_pow(
  exp_expr : Expr,
  input : Json,
  env : Env,
) -> Iter[Json] raise InterpreterError {
  match (input, eval_with_env(exp_expr, input, env).collect()) {
    (Number(base, ..), [Number(exp, ..), ..]) =>
      Iter::singleton(Json::number(@math.pow(base, exp)))
    (_, []) => Iter::singleton(null)
    _ => raise TypeMismatch("number", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate natural log
fn eval_log(input : Json) -> Iter[Json] raise InterpreterError {
  guard input is Number(n, ..) else {
    raise TypeMismatch("number", @ast_internal.json_type_name(input))
  }
  Iter::singleton(Json::number(@math.ln(n)))
}

///|
/// Evaluate exponent
fn eval_exp(input : Json) -> Iter[Json] raise InterpreterError {
  guard input is Number(n, ..) else {
    raise TypeMismatch("number", @ast_internal.json_type_name(input))
  }
  Iter::singleton(Json::number(@math.exp(n)))
}

///|
/// Evaluate sine
fn eval_sin(input : Json) -> Iter[Json] raise InterpreterError {
  guard input is Number(n, ..) else {
    raise TypeMismatch("number", @ast_internal.json_type_name(input))
  }
  Iter::singleton(Json::number(@math.sin(n)))
}

///|
/// Evaluate cosine
fn eval_cos(input : Json) -> Iter[Json] raise InterpreterError {
  guard input is Number(n, ..) else {
    raise TypeMismatch("number", @ast_internal.json_type_name(input))
  }
  Iter::singleton(Json::number(@math.cos(n)))
}

///|
/// Evaluate tangent
fn eval_tan(input : Json) -> Iter[Json] raise InterpreterError {
  guard input is Number(n, ..) else {
    raise TypeMismatch("number", @ast_internal.json_type_name(input))
  }
  Iter::singleton(Json::number(@math.tan(n)))
}

///|
/// Evaluate arcsine
fn eval_asin(input : Json) -> Iter[Json] raise InterpreterError {
  guard input is Number(n, ..) else {
    raise TypeMismatch("number", @ast_internal.json_type_name(input))
  }
  Iter::singleton(Json::number(@math.asin(n)))
}

///|
/// Evaluate arccosine
fn eval_acos(input : Json) -> Iter[Json] raise InterpreterError {
  guard input is Number(n, ..) else {
    raise TypeMismatch("number", @ast_internal.json_type_name(input))
  }
  Iter::singleton(Json::number(@math.acos(n)))
}

///|
/// Evaluate arctangent
fn eval_atan(input : Json) -> Iter[Json] raise InterpreterError {
  guard input is Number(n, ..) else {
    raise TypeMismatch("number", @ast_internal.json_type_name(input))
  }
  Iter::singleton(Json::number(@math.atan(n)))
}
