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
  let base_env : Env = {
    bindings: env.bindings.copy(),
    functions: env.functions.copy(),
  }
  let (_acc, results) : (Json, Array[Json]) = gen_results.fold(
    init=(init_results[0], []),
    fn(state, gen_result) raise InterpreterError {
      let (acc, results) = state
      let new_env = base_env.set(var_name, gen_result)
      let update_results = eval_with_env(update_expr, acc, new_env).collect()
      match update_results {
        [] => (acc, results)
        [next, .. _] => {
          let output = match extract_expr {
            Some(extract) => {
              let extract_results = eval_with_env(extract, next, new_env).collect()
              match extract_results {
                [] => next
                [first, .. _] => first
              }
            }
            None => next
          }
          results.push(output)
          (next, results)
        }
      }
    },
  )
  results.iterator()
}
