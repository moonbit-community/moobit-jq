///|
/// Evaluate Assign operator
fn eval_assign(
  _path : Expr,
  value_expr : Expr,
  input : Json,
  env : Env,
) -> Iter[Json] raise InterpreterError {
  match eval_with_env(value_expr, input, env).collect() {
    [] => Iter::singleton(input)
    [first, ..] => Iter::singleton(first)
  }
}
