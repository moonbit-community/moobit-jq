///|
/// Evaluate RangeFromTo
fn eval_range_from_to(
  from_expr : Expr,
  to_expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let from_results = eval_with_env(from_expr, input, env).collect()
  let to_results = eval_with_env(to_expr, input, env).collect()
  if from_results.is_empty() || to_results.is_empty() {
    return Iterator::empty()
  }
  match (from_results[0], to_results[0]) {
    (Number(from_num, ..), Number(to_num, ..)) => {
      let from_int = from_num.to_int()
      let to_int = to_num.to_int()
      let results : Array[Json] = []
      for i = from_int; i < to_int; i = i + 1 {
        results.push(Json::number(i.to_double()))
      }
      results.iterator()
    }
    _ => raise TypeMismatch("numbers", "non-numbers")
  }
}

///|
/// Evaluate RangeWithStep
fn eval_range_with_step(
  from_expr : Expr,
  to_expr : Expr,
  step_expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let from_results = eval_with_env(from_expr, input, env).collect()
  let to_results = eval_with_env(to_expr, input, env).collect()
  let step_results = eval_with_env(step_expr, input, env).collect()
  if from_results.is_empty() || to_results.is_empty() || step_results.is_empty() {
    return Iterator::empty()
  }
  match (from_results[0], to_results[0], step_results[0]) {
    (Number(from_num, ..), Number(to_num, ..), Number(step_num, ..)) => {
      let from_int = from_num.to_int()
      let to_int = to_num.to_int()
      let step_int = step_num.to_int()
      let results : Array[Json] = []
      if step_int > 0 {
        let mut i = from_int
        while i < to_int {
          results.push(Json::number(i.to_double()))
          i = i + step_int
        }
      } else if step_int < 0 {
        let mut i = from_int
        while i > to_int {
          results.push(Json::number(i.to_double()))
          i = i + step_int
        }
      }
      results.iterator()
    }
    _ => raise TypeMismatch("numbers", "non-numbers")
  }
}
