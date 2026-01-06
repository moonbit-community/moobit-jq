///|
fn eval_expr(expr : @ast.Expr, input : String) -> Array[Json] raise {
  let json_input = @json.parse(input[:])
  @ast.eval(expr, json_input).collect()
}

///|
test "coverage: eval functiondef and path expr" {
  let fn_expr = @ast.Expr::FunctionDef("f", [], @ast.Expr::Identity)
  @json.inspect(eval_expr(fn_expr, "1"), content=[1])
  let path_expr = @ast.Expr::Path(@ast.Expr::Identity)
  @json.inspect(eval_expr(path_expr, "{\"a\":1}"), content=[[]])
}

///|
test "coverage: update with index left branches" {
  let update_expr = @ast.Expr::Literal(@ast.Literal::Number(1.0))
  let path_valid = @ast.Expr::Pipe(@ast.Expr::Index([0]), @ast.Expr::Key("a"))
  let expr_valid = @ast.Expr::Update(path_valid, update_expr)
  @json.inspect(eval_expr(expr_valid, "[{\"a\":0}]"), content=[[{ "a": 1 }]])
  let path_empty = @ast.Expr::Pipe(@ast.Expr::Index([]), @ast.Expr::Key("a"))
  let expr_empty = @ast.Expr::Update(path_empty, update_expr)
  @json.inspect(eval_expr(expr_empty, "[{\"a\":0}]"), content=[[{ "a": 0 }]])
  let path_oob = @ast.Expr::Pipe(@ast.Expr::Index([5]), @ast.Expr::Key("a"))
  let expr_oob = @ast.Expr::Update(path_oob, update_expr)
  @json.inspect(eval_expr(expr_oob, "[{\"a\":0}]"), content=[[{ "a": 0 }]])
  let expr_non_array = @ast.Expr::Update(path_valid, update_expr)
  @json.inspect(eval_expr(expr_non_array, "1"), content=[1])
}

///|
test "coverage: update with complex left pipe" {
  let path = @ast.Expr::Pipe(
    @ast.Expr::Pipe(@ast.Expr::Key("a"), @ast.Expr::Key("b")),
    @ast.Expr::Key("c"),
  )
  let update_expr = @ast.Expr::Literal(@ast.Literal::Number(2.0))
  let expr = @ast.Expr::Update(path, update_expr)
  @json.inspect(eval_expr(expr, "{\"a\":{\"b\":{\"c\":1}}}"), content=[
    { "c": 2 },
  ])
}
