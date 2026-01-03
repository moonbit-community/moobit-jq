///|
/// Evaluate Foreach
fn eval_foreach(
  gen_expr : Expr,
  var_name : String,
  init_expr : Expr,
  update_expr : Expr,
  extract_expr : Expr?,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let gen_results = eval_with_env(gen_expr, input, env).collect()
  let init_results = eval_with_env(init_expr, input, env).collect()
  if init_results.is_empty() {
    return Iterator::empty()
  }
  let mut accumulator = init_results[0]
  let results : Array[Json] = []
  for gen_result in gen_results {
    let mut new_env = Env::new()
    for key, value in env.bindings {
      new_env = new_env.set(key, value)
    }
    for key, value in env.functions {
      new_env = new_env.set_function(key, value.0, value.1)
    }
    new_env = new_env.set(var_name, gen_result)
    let update_results = eval_with_env(update_expr, accumulator, new_env).collect()
    if not(update_results.is_empty()) {
      accumulator = update_results[0]
      let output = match extract_expr {
        Some(extract) => {
          let extract_results = eval_with_env(extract, accumulator, new_env).collect()
          if extract_results.is_empty() {
            accumulator
          } else {
            extract_results[0]
          }
        }
        None => accumulator
      }
      results.push(output)
    }
  }
  results.iterator()
}
