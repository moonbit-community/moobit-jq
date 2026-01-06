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
  match (from_results, to_results) {
    ([], _) | (_, []) => Iterator::empty()
    ([Number(from_num, ..), ..], [Number(to_num, ..), ..]) => {
      let from_int = from_num.to_int()
      let to_int = to_num.to_int()
      if to_int <= from_int {
        [].iterator()
      } else {
        let count = to_int - from_int
        Array::makei(count, i => Json::number((from_int + i).to_double())).iterator()
      }
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
  match (from_results, to_results, step_results) {
    ([], _, _) | (_, [], _) | (_, _, []) => Iterator::empty()
    (
      [Number(from_num, ..), ..],
      [Number(to_num, ..), ..],
      [Number(step_num, ..), ..],
    ) => {
      let from_int = from_num.to_int()
      let to_int = to_num.to_int()
      let step_int = step_num.to_int()
      let count = range_step_count(from_int, to_int, step_int)
      if count <= 0 {
        [].iterator()
      } else {
        Array::makei(count, i => Json::number(
          (from_int + i * step_int).to_double(),
        )).iterator()
      }
    }
    _ => raise TypeMismatch("numbers", "non-numbers")
  }
}

///|
fn range_step_count(from_int : Int, to_int : Int, step_int : Int) -> Int {
  if step_int == 0 {
    0
  } else if step_int > 0 {
    if from_int >= to_int {
      0
    } else {
      (to_int - from_int - 1) / step_int + 1
    }
  } else if from_int <= to_int {
    0
  } else {
    let step_abs = -step_int
    (from_int - to_int - 1) / step_abs + 1
  }
}
