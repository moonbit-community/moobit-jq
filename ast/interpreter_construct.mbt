///|
/// Evaluate array construction
fn eval_array_construct(
  expr_opt : Expr?,
  input : Json,
  env : Env,
) -> Iter[Json] raise InterpreterError {
  match expr_opt {
    None => Iter::singleton(Json::array([]))
    Some(e) => {
      let results = eval_with_env(e, input, env).collect()
      Iter::singleton(Json::array(results))
    }
  }
}

///|
/// Evaluate object construction
fn eval_object_construct(
  pairs : Array[(Expr, Expr?)],
  input : Json,
  env : Env,
) -> Iter[Json] raise InterpreterError {
  let obj : Map[String, Json] = {}
  for pair in pairs {
    let (key_expr, value_expr_opt) = pair
    // Evaluate key to get string
    match eval_with_env(key_expr, input, env).collect() {
      [] => ()
      [String(key_str), ..] => {
        // Evaluate value or use key from input
        let value = match value_expr_opt {
          Some(value_expr) =>
            match eval_with_env(value_expr, input, env).collect() {
              [first, ..] => first
              [] => null
            }
          None =>
            // Shorthand: {foo} means {foo: .foo}
            match input {
              Object(input_obj) => input_obj.get(key_str).unwrap_or(null)
              _ => null
            }
        }
        obj[key_str] = value
      }
      [other, ..] =>
        raise TypeMismatch("string", @ast_internal.json_type_name(other))
    }
  }
  Iter::singleton(Json::object(obj))
}
