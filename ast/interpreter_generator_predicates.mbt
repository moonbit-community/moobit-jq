///|
/// Evaluate AnyGen
fn eval_any_gen(
  gen_expr : Expr,
  cond_expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let gen_results = eval_with_env(gen_expr, input, env).collect()
  Iterator::singleton(
    Json::boolean(any_gen_results(gen_results[:], cond_expr, env)),
  )
}

///|
/// Evaluate AllGen
fn eval_all_gen(
  gen_expr : Expr,
  cond_expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let gen_results = eval_with_env(gen_expr, input, env).collect()
  Iterator::singleton(
    Json::boolean(all_gen_results(gen_results[:], cond_expr, env)),
  )
}

///|
fn any_gen_results(
  gen_results : ArrayView[Json],
  cond_expr : Expr,
  env : Env,
) -> Bool raise InterpreterError {
  match gen_results {
    [] => false
    [head, .. tail] =>
      match eval_with_env(cond_expr, head, env).collect() {
        [True, ..] => true
        _ => any_gen_results(tail, cond_expr, env)
      }
  }
}

///|
fn all_gen_results(
  gen_results : ArrayView[Json],
  cond_expr : Expr,
  env : Env,
) -> Bool raise InterpreterError {
  match gen_results {
    [] => true
    [head, .. tail] =>
      match eval_with_env(cond_expr, head, env).collect() {
        [True, ..] => all_gen_results(tail, cond_expr, env)
        _ => false
      }
  }
}
