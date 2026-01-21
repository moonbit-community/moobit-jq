///|
/// Evaluate string interpolation expressions
fn eval_string_interpolation(
  parts : Array[(String, Expr?)],
  input : Json,
  env : Env,
) -> Iter[Json] raise InterpreterError {
  let buf = @buffer.new()
  for pair in parts {
    let (text, expr_opt) = pair
    buf.write_string(text)
    match expr_opt {
      Some(expr) =>
        match eval_with_env(expr, input, env).collect() {
          [String(s), ..] => buf.write_string(s)
          [other, ..] => buf.write_string(other.to_string())
          [] => ()
        }
      None => ()
    }
  }
  Iter::singleton(Json::string(buf.to_string()))
}
