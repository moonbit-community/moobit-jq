///|
/// Evaluate FirstGen
fn eval_first_gen(
  gen_expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  match eval_with_env(gen_expr, input, env).collect()[:] {
    [] => Iterator::empty()
    [head, .. _] => Iterator::singleton(head)
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
  match last_in_view(gen_results[:]) {
    Some(value) => Iterator::singleton(value)
    None => Iterator::empty()
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
  let idx : Ref[Int] = Ref::new(0)
  Iterator::new(fn() {
    let i = idx.val
    let result = Some(values[i])
    idx.val = if i + 1 >= values.length() { 0 } else { i + 1 }
    result
  })
}
