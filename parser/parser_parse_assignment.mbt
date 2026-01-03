///|
/// Parse assignment operators
fn Parser::parse_assignment(self : Parser) -> @ast.Expr raise ParseError {
  let expr = self.parse_or()
  match self.current() {
    Some(TAssign) => {
      self.advance()
      @ast.Expr::Assign(expr, self.parse_or())
    }
    Some(TUpdate) => {
      self.advance()
      @ast.Expr::Update(expr, self.parse_or())
    }
    Some(TAlternative) => {
      self.advance()
      @ast.Expr::Alternative(expr, self.parse_or())
    }
    Some(TAddAssign) => {
      self.advance()
      @ast.Expr::AddAssign(expr, self.parse_or())
    }
    Some(TSubAssign) => {
      self.advance()
      @ast.Expr::SubAssign(expr, self.parse_or())
    }
    Some(TMulAssign) => {
      self.advance()
      @ast.Expr::MulAssign(expr, self.parse_or())
    }
    Some(TDivAssign) => {
      self.advance()
      @ast.Expr::DivAssign(expr, self.parse_or())
    }
    Some(TModAssign) => {
      self.advance()
      @ast.Expr::ModAssign(expr, self.parse_or())
    }
    Some(TAltAssign) => {
      self.advance()
      @ast.Expr::AltAssign(expr, self.parse_or())
    }
    _ => expr
  }
}
