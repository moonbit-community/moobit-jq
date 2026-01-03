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

///|
/// Evaluate FirstGen
fn eval_first_gen(
  gen_expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let gen_results = eval_with_env(gen_expr, input, env).collect()
  if gen_results.is_empty() {
    Iterator::empty()
  } else {
    Iterator::singleton(gen_results[0])
  }
}

///|
/// Evaluate LastGen
fn eval_last_gen(
  gen_expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let gen_results = eval_with_env(gen_expr, input, env).collect()
  if gen_results.is_empty() {
    Iterator::empty()
  } else {
    Iterator::singleton(gen_results[gen_results.length() - 1])
  }
}

///|
/// Evaluate Repeat
fn eval_repeat(
  expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let values = eval_with_env(expr, input, env).collect()
  if values.is_empty() {
    return Iterator::empty()
  }
  let mut i = 0
  Iterator::new(fn() {
    let result = Some(values[i])
    i += 1
    if i >= values.length() {
      i = 0
    }
    result
  })
}

///|
/// Evaluate AnyGen
fn eval_any_gen(
  gen_expr : Expr,
  cond_expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let gen_results = eval_with_env(gen_expr, input, env).collect()
  let mut found = false
  for gen_result in gen_results {
    let cond_results = eval_with_env(cond_expr, gen_result, env).collect()
    if not(cond_results.is_empty()) {
      match cond_results[0] {
        True => {
          found = true
          break
        }
        _ => ()
      }
    }
  }
  Iterator::singleton(Json::boolean(found))
}

///|
/// Evaluate AllGen
fn eval_all_gen(
  gen_expr : Expr,
  cond_expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let gen_results = eval_with_env(gen_expr, input, env).collect()
  let mut all_true = true
  for gen_result in gen_results {
    let cond_results = eval_with_env(cond_expr, gen_result, env).collect()
    if not(cond_results.is_empty()) {
      match cond_results[0] {
        True => ()
        _ => {
          all_true = false
          break
        }
      }
    } else {
      all_true = false
      break
    }
  }
  Iterator::singleton(Json::boolean(all_true))
}

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
