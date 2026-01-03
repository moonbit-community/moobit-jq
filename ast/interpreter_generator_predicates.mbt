///|
/// Evaluate AnyGen
fn eval_any_gen(
  gen_expr : Expr,
  cond_expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let gen_results = eval_with_env(gen_expr, input, env).collect()
  let mut found = false
  for gen_result in gen_results {
    let cond_results = eval_with_env(cond_expr, gen_result, env).collect()
    if not(cond_results.is_empty()) {
      match cond_results[0] {
        True => {
          found = true
          break
        }
        _ => ()
      }
    }
  }
  Iterator::singleton(Json::boolean(found))
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
  let mut all_true = true
  for gen_result in gen_results {
    let cond_results = eval_with_env(cond_expr, gen_result, env).collect()
    if not(cond_results.is_empty()) {
      match cond_results[0] {
        True => ()
        _ => {
          all_true = false
          break
        }
      }
    } else {
      all_true = false
      break
    }
  }
  Iterator::singleton(Json::boolean(all_true))
}
