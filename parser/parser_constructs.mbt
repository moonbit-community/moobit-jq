///|
/// Parse object constructor
fn Parser::parse_object(self : Parser) -> @ast.Expr raise ParseError {
  if self.consume(TRBrace) {
    return @ast.Expr::ObjectConstruct([])
  }
  let pairs : Array[(@ast.Expr, @ast.Expr?)] = loop [] {
    acc => {
      let key = match self.current() {
        Some(TIdentifier(name)) => {
          self.advance()
          @ast.Expr::Literal(@ast.Literal::String(name))
        }
        Some(TString(name)) => {
          self.advance()
          @ast.Expr::Literal(@ast.Literal::String(name))
        }
        Some(TLParen) => {
          self.advance()
          let expr = self.parse_pipe()
          self.expect(TRParen)
          expr
        }
        _ => raise InvalidSyntax("Expected object key")
      }
      let value = if self.consume(TColon) {
        Some(self.parse_assignment())
      } else {
        None
      }
      acc.push((key, value))
      if !self.consume(TComma) || self.check(TRBrace) {
        acc
      } else {
        continue acc
      }
    }
  }
  self.expect(TRBrace)
  @ast.Expr::ObjectConstruct(pairs)
}

///|
/// Parse if-then-else
fn Parser::parse_if(self : Parser) -> @ast.Expr raise ParseError {
  self.advance()
  let cond = self.parse_pipe()
  self.expect(TThen)
  let then_expr = self.parse_pipe()
  self.expect(TElse)
  let else_expr = self.parse_pipe()
  self.expect(TEnd)
  @ast.Expr::IfThenElse(cond, then_expr, else_expr)
}

///|
/// Parse try-catch
fn Parser::parse_try(self : Parser) -> @ast.Expr raise ParseError {
  self.advance()
  let expr = self.parse_postfix()
  let handler = if self.consume(TCatch) {
    Some(self.parse_postfix())
  } else {
    None
  }
  @ast.Expr::TryCatch(expr, handler)
}

///|
/// Parse reduce: reduce EXPR as $VAR (INIT; UPDATE)
fn Parser::parse_reduce(self : Parser) -> @ast.Expr raise ParseError {
  self.advance() // consume 'reduce'
  let gen_expr = self.parse_postfix() // generator expression
  // Expect 'as'
  if not(self.consume(TAs)) {
    raise InvalidSyntax("reduce expects 'as' after expression")
  }
  // Expect variable
  let var_name = match self.current() {
    Some(TVariable(name)) => {
      self.advance()
      name
    }
    _ => raise InvalidSyntax("reduce expects variable after as")
  }
  // Expect (INIT; UPDATE)
  self.expect(TLParen)
  let init_expr = self.parse_pipe()
  self.expect(TSemicolon)
  let update_expr = self.parse_pipe()
  self.expect(TRParen)
  @ast.Expr::Reduce(gen_expr, var_name, init_expr, update_expr)
}

///|
/// Parse foreach: foreach EXPR as $VAR (INIT; UPDATE) or (INIT; UPDATE; EXTRACT)
fn Parser::parse_foreach(self : Parser) -> @ast.Expr raise ParseError {
  self.advance() // consume 'foreach'
  let gen_expr = self.parse_postfix() // generator expression
  // Expect 'as'
  if not(self.consume(TAs)) {
    raise InvalidSyntax("foreach expects 'as' after expression")
  }
  // Expect variable
  let var_name = match self.current() {
    Some(TVariable(name)) => {
      self.advance()
      name
    }
    _ => raise InvalidSyntax("foreach expects variable after as")
  }
  // Expect (INIT; UPDATE) or (INIT; UPDATE; EXTRACT)
  self.expect(TLParen)
  let init_expr = self.parse_pipe()
  self.expect(TSemicolon)
  let update_expr = self.parse_pipe()
  // Check for optional extract expression
  let extract_expr = if self.consume(TSemicolon) {
    Some(self.parse_pipe())
  } else {
    None
  }
  self.expect(TRParen)
  @ast.Expr::Foreach(gen_expr, var_name, init_expr, update_expr, extract_expr)
}
