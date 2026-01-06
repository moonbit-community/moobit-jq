///|
/// Evaluate variable lookup
fn eval_variable(
  name : String,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  match env.get(name) {
    Some(v) => Iterator::singleton(v)
    None => raise InvalidOperation("Undefined variable: $\{name}")
  }
}

///|
/// Evaluate function call
fn eval_function_call(
  name : String,
  args : Array[Expr],
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  match env.get_function(name) {
    Some((body, params)) =>
      if params.is_empty() {
        eval_with_env(body, input, env)
      } else if args.length() != params.length() {
        raise EvalError(
          "Function \{name} expects \{params.length()} arguments, got \{args.length()}",
        )
      } else {
        let arg_values = args.map(fn(arg) raise InterpreterError {
          let results = eval_with_env(arg, input, env).collect()
          match results {
            [] => null
            [first, ..] => first
          }
        })
        let new_env = bind_params(env, params[:], arg_values[:])
        eval_with_env(body, input, new_env)
      }
    None => raise EvalError("Undefined function: \{name}")
  }
}

///|
fn bind_params(
  env : Env,
  params : ArrayView[String],
  values : ArrayView[Json],
) -> Env {
  match (params, values) {
    ([], []) => env
    ([name, .. rest_params], [value, .. rest_values]) =>
      bind_params(env.set(name, value), rest_params, rest_values)
    _ => env
  }
}

///|
/// Evaluate As binding
fn eval_as(
  expr : Expr,
  var_name : String,
  body : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let results = eval_with_env(expr, input, env).collect()
  let all_results : Array[Json] = []
  for result in results {
    let new_env = env.set(var_name, result)
    for val in eval_with_env(body, input, new_env) {
      all_results.push(val)
    }
  }
  all_results.iterator()
}
