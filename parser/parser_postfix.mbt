///|
/// Parse postfix operators
fn Parser::parse_postfix(self : Parser) -> @ast.Expr raise ParseError {
  loop self.parse_primary() {
    expr =>
      match self.current() {
        Some(TQuestion) => {
          self.advance()
          continue @ast.Expr::Optional(expr)
        }
        Some(TLBracket) => {
          self.advance()
          continue self.parse_index_or_slice(expr)
        }
        Some(TDot) => {
          self.advance()
          continue self.parse_field_access(expr)
        }
        _ => expr
      }
  }
}

///|
/// Parse array index or slice
fn Parser::parse_index_or_slice(
  self : Parser,
  base : @ast.Expr,
) -> @ast.Expr raise ParseError {
  if self.consume(TRBracket) {
    return @ast.Expr::Pipe(base, @ast.Expr::Index([]))
  }
  let start_or_index = self.parse_slice_part()
  if self.consume(TColon) {
    let end = self.parse_slice_part()
    self.expect(TRBracket)
    @ast.Expr::Pipe(base, @ast.Expr::Slice(start_or_index, end))
  } else {
    let indices : Array[Int] = []
    guard start_or_index is Some(n) else {
      raise InvalidSyntax("Expected index")
    }
    indices.push(n)
    while self.consume(TComma) {
      guard self.parse_slice_part() is Some(n2) else {
        raise InvalidSyntax("Expected index after comma")
      }
      indices.push(n2)
    }
    self.expect(TRBracket)
    @ast.Expr::Pipe(base, @ast.Expr::Index(indices))
  }
}

///|
/// Parse optional integer for slice
fn Parser::parse_slice_part(self : Parser) -> Int? raise ParseError {
  match self.current() {
    Some(TNumber(n)) => {
      self.advance()
      Some(n.to_int())
    }
    Some(TMinus) => {
      self.advance()
      guard self.current() is Some(TNumber(n)) else {
        raise InvalidSyntax("Expected number after minus")
      }
      self.advance()
      Some(-n.to_int())
    }
    _ => None
  }
}

///|
/// Parse field access after dot
fn Parser::parse_field_access(
  self : Parser,
  base : @ast.Expr,
) -> @ast.Expr raise ParseError {
  match self.current() {
    Some(TIdentifier(name)) => {
      self.advance()
      @ast.Expr::Pipe(base, @ast.Expr::Key(name))
    }
    Some(TLBracket) => {
      self.advance()
      self.parse_index_or_slice(base)
    }
    Some(TDot) => {
      self.advance()
      @ast.Expr::Recurse
    }
    _ => base
  }
}
