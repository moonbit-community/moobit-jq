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
  match input {
    Number(n, ..) => Iter::singleton(Json::number(@math.ln(n)))
    _ => raise TypeMismatch("number", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate exponent
fn eval_exp(input : Json) -> Iter[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iter::singleton(Json::number(@math.exp(n)))
    _ => raise TypeMismatch("number", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate sine
fn eval_sin(input : Json) -> Iter[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iter::singleton(Json::number(@math.sin(n)))
    _ => raise TypeMismatch("number", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate cosine
fn eval_cos(input : Json) -> Iter[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iter::singleton(Json::number(@math.cos(n)))
    _ => raise TypeMismatch("number", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate tangent
fn eval_tan(input : Json) -> Iter[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iter::singleton(Json::number(@math.tan(n)))
    _ => raise TypeMismatch("number", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate arcsine
fn eval_asin(input : Json) -> Iter[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iter::singleton(Json::number(@math.asin(n)))
    _ => raise TypeMismatch("number", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate arccosine
fn eval_acos(input : Json) -> Iter[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iter::singleton(Json::number(@math.acos(n)))
    _ => raise TypeMismatch("number", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate arctangent
fn eval_atan(input : Json) -> Iter[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iter::singleton(Json::number(@math.atan(n)))
    _ => raise TypeMismatch("number", @ast_internal.json_type_name(input))
  }
}
