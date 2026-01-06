///|
/// Parse flow range and stream built-ins
fn Parser::parse_builtin_flow_range(
  self : Parser,
  name : String,
) -> @ast.Expr? raise ParseError {
  match name {
    "range" => {
      self.expect(TLParen)
      let first_expr = self.parse_pipe()
      match self.current() {
        Some(TSemicolon) => {
          self.advance()
          let second_expr = self.parse_pipe()
          match self.current() {
            Some(TSemicolon) => {
              self.advance()
              let third_expr = self.parse_pipe()
              self.expect(TRParen)
              Some(
                @ast.Expr::RangeWithStep(first_expr, second_expr, third_expr),
              )
            }
            _ => {
              self.expect(TRParen)
              Some(@ast.Expr::RangeFromTo(first_expr, second_expr))
            }
          }
        }
        _ => {
          self.expect(TRParen)
          match first_expr {
            @ast.Expr::Literal(@ast.Literal::Number(n)) =>
              Some(@ast.Expr::Range(n.to_int()))
            _ => raise InvalidSyntax("range(n) expects literal number")
          }
        }
      }
    }
    "first" =>
      match self.current() {
        Some(TLParen) => {
          self.advance()
          let expr = self.parse_pipe()
          self.expect(TRParen)
          Some(@ast.Expr::FirstGen(expr))
        }
        _ => Some(@ast.Expr::First)
      }
    "last" =>
      match self.current() {
        Some(TLParen) => {
          self.advance()
          let expr = self.parse_pipe()
          self.expect(TRParen)
          Some(@ast.Expr::LastGen(expr))
        }
        _ => Some(@ast.Expr::Last)
      }
    "repeat" => {
      self.expect(TLParen)
      let expr = self.parse_pipe()
      self.expect(TRParen)
      Some(@ast.Expr::Repeat(expr))
    }
    _ => None
  }
}
