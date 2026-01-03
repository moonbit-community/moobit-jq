///|
/// Evaluate IfThenElse
fn eval_if_then_else(
  cond : Expr,
  then_expr : Expr,
  else_expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let cond_results = eval_with_env(cond, input, env).collect()
  if cond_results.is_empty() {
    eval_with_env(else_expr, input, env)
  } else {
    let truthy = is_truthy(cond_results[0])
    if truthy {
      eval_with_env(then_expr, input, env)
    } else {
      eval_with_env(else_expr, input, env)
    }
  }
}

///|
/// Evaluate TryCatch
fn eval_try_catch(
  try_expr : Expr,
  catch_opt : Expr?,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  eval_with_env(try_expr, input, env) catch {
    _ =>
      match catch_opt {
        Some(catch_expr) => eval_with_env(catch_expr, input, env)
        None => Iterator::empty()
      }
  }
}

///|
/// Evaluate Alternative
fn eval_alternative(
  left : Expr,
  right : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let left_results = eval_with_env(left, input, env).collect()
  if left_results.is_empty() {
    eval_with_env(right, input, env)
  } else if is_truthy(left_results[0]) {
    left_results.iterator()
  } else {
    eval_with_env(right, input, env)
  }
}

///|
/// Evaluate Limit
fn eval_limit(
  n : Int,
  expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  eval_with_env(expr, input, env).take(n)
}

///|
/// Evaluate Until
fn eval_until(
  cond_expr : Expr,
  update_expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let result = loop input {
    current => {
      let cond_results = eval_with_env(cond_expr, current, env).collect()
      match cond_results {
        [] => current
        [True, .. _] => current
        _ => {
          let update_results = eval_with_env(update_expr, current, env).collect()
          match update_results {
            [] => current
            [next, .. _] => continue next
          }
        }
      }
    }
  }
  Iterator::singleton(result)
}

///|
/// Evaluate While
fn eval_while(
  cond_expr : Expr,
  update_expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let results : Array[Json] = loop (input, []) {
    (current, results) => {
      let cond_results = eval_with_env(cond_expr, current, env).collect()
      match cond_results {
        [] => results
        [first, .. _] =>
          if not(is_truthy(first)) {
            results
          } else {
            results.push(current)
            let update_results = eval_with_env(update_expr, current, env).collect()
            match update_results {
              [] => results
              [next, .. _] => continue (next, results)
            }
          }
      }
    }
  }
  results.iterator()
}
