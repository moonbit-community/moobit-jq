///|
/// Evaluate FirstGen
fn eval_first_gen(
  gen_expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let gen_results = eval_with_env(gen_expr, input, env).collect()
  if gen_results.is_empty() {
    Iterator::empty()
  } else {
    Iterator::singleton(gen_results[0])
  }
}

///|
/// Evaluate LastGen
fn eval_last_gen(
  gen_expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let gen_results = eval_with_env(gen_expr, input, env).collect()
  if gen_results.is_empty() {
    Iterator::empty()
  } else {
    Iterator::singleton(gen_results[gen_results.length() - 1])
  }
}

///|
/// Evaluate Repeat
fn eval_repeat(
  expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let values = eval_with_env(expr, input, env).collect()
  if values.is_empty() {
    return Iterator::empty()
  }
  let mut i = 0
  Iterator::new(fn() {
    let result = Some(values[i])
    i += 1
    if i >= values.length() {
      i = 0
    }
    result
  })
}
