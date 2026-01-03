///|
/// Evaluate binary operation expressions
fn eval_operation_expr(
  left : Expr,
  op : BinaryOp,
  right : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let left_results = eval_with_env(left, input, env).collect()
  let right_results = eval_with_env(right, input, env).collect()
  let all_results : Array[Json] = []
  for left_val in left_results {
    for right_val in right_results {
      all_results.push(eval_binary_op(op, left_val, right_val))
    }
  }
  all_results.iterator()
}
