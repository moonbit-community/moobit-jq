///|
/// Evaluate AnyGen
fn eval_any_gen(
  gen_expr : Expr,
  cond_expr : Expr,
  input : Json,
  env : Env,
) -> Iter[Json] raise InterpreterError {
  let gen_results = eval_with_env(gen_expr, input, env).collect()
  Iter::singleton(
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
) -> Iter[Json] raise InterpreterError {
  let gen_results = eval_with_env(gen_expr, input, env).collect()
  Iter::singleton(
    Json::boolean(all_gen_results(gen_results[:], cond_expr, env)),
  )
}

///|
fn any_gen_results(
  gen_results : ArrayView[Json],
  cond_expr : Expr,
  env : Env,
) -> Bool raise InterpreterError {
  for value in gen_results {
    match eval_with_env(cond_expr, value, env).collect() {
      [True, ..] => return true
      _ => ()
    }
  }
  false
}

///|
fn all_gen_results(
  gen_results : ArrayView[Json],
  cond_expr : Expr,
  env : Env,
) -> Bool raise InterpreterError {
  for value in gen_results {
    match eval_with_env(cond_expr, value, env).collect() {
      [True, ..] => ()
      _ => return false
    }
  }
  true
}
