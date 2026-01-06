///|
/// Evaluate MapValues
fn eval_map_values(
  expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  match input {
    Object(obj) => {
      let result : Map[String, Json] = obj
        .to_array()
        .fold(init={}, fn(acc, pair) raise InterpreterError {
          let (key, value) = pair
          let transformed_results = eval_with_env(expr, value, env).collect()
          match transformed_results {
            [first, ..] => acc[key] = first
            _ => ()
          }
          acc
        })
      Iterator::singleton(Json::object(result))
    }
    _ => raise TypeMismatch("object", @ast_internal.json_type_name(input))
  }
}
