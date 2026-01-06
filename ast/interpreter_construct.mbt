///|
/// Evaluate array construction
fn eval_array_construct(
  expr_opt : Expr?,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  match expr_opt {
    None => Iterator::singleton(Json::array([]))
    Some(e) => {
      let results = eval_with_env(e, input, env).collect()
      Iterator::singleton(Json::array(results))
    }
  }
}

///|
/// Evaluate object construction
fn eval_object_construct(
  pairs : Array[(Expr, Expr?)],
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let obj : Map[String, Json] = {}
  for pair in pairs {
    let (key_expr, value_expr_opt) = pair
    // Evaluate key to get string
    let key_results = eval_with_env(key_expr, input, env).collect()
    match @ast_internal.first_opt(key_results) {
      None => ()
      Some(String(key_str)) => {
        // Evaluate value or use key from input
        let value = match value_expr_opt {
          Some(value_expr) => {
            let value_results = eval_with_env(value_expr, input, env).collect()
            @ast_internal.first_or_null(value_results)
          }
          None =>
            // Shorthand: {foo} means {foo: .foo}
            match input {
              Object(input_obj) =>
                match input_obj.get(key_str) {
                  Some(v) => v
                  None => null
                }
              _ => null
            }
        }
        obj[key_str] = value
      }
      Some(other) =>
        raise TypeMismatch("string", @ast_internal.json_type_name(other))
    }
  }
  Iterator::singleton(Json::object(obj))
}
