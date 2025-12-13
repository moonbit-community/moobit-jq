///|
/// Parser error types
pub(all) suberror ParseError {
  UnexpectedToken(String, String) // (found, expected) - using String to avoid ToJson requirement
  UnexpectedEnd(String) // (expected)
  InvalidSyntax(String)
} derive(Eq, Show)

///|
/// Parser state
priv struct Parser {
  tokens : Array[@lexer.Token]
  mut pos : Int
}

///|
/// Create a new parser from tokens
fn Parser::new(tokens : Array[@lexer.Token]) -> Parser {
  { tokens, pos: 0 }
}

///|
/// Get current token
fn Parser::current(self : Parser) -> @lexer.Token? {
  if self.pos < self.tokens.length() {
    Some(self.tokens[self.pos])
  } else {
    None
  }
}

///|
/// Advance to next token
fn Parser::advance(self : Parser) -> Unit {
  if self.pos < self.tokens.length() {
    self.pos += 1
  }
}

///|
/// Check if current token matches type
fn Parser::check(self : Parser, expected : @lexer.Token) -> Bool {
  match self.current() {
    Some(t) => t == expected
    None => false
  }
}

///|
/// Consume current token if it matches
fn Parser::consume(self : Parser, expected : @lexer.Token) -> Bool {
  if self.check(expected) {
    self.advance()
    true
  } else {
    false
  }
}

///|
/// Expect and consume a token, raise error if not found
fn Parser::expect(
  self : Parser,
  expected : @lexer.Token,
) -> Unit raise ParseError {
  match self.current() {
    Some(t) if t == expected => self.advance()
    Some(t) =>
      raise ParseError::UnexpectedToken(t.to_string(), expected.to_string())
    None => raise ParseError::UnexpectedEnd(expected.to_string())
  }
}

///|
/// Parse entry point
pub fn parse(input : String) -> @ast.Expr raise {
  let tokens = @lexer.lex(input)
  let parser = Parser::new(tokens)
  parser.parse_pipe()
}

///|
/// Parse pipe expression (lowest precedence)
fn Parser::parse_pipe(self : Parser) -> @ast.Expr raise ParseError {
  let mut expr = self.parse_comma()
  while self.consume(@lexer.Token::TPipe) {
    let right = self.parse_comma()
    expr = @ast.Expr::Pipe(expr, right)
  }
  expr
}

///|
/// Parse comma expression
fn Parser::parse_comma(self : Parser) -> @ast.Expr raise ParseError {
  let mut expr = self.parse_assignment()
  while self.consume(@lexer.Token::TComma) {
    let right = self.parse_assignment()
    expr = @ast.Expr::Comma(expr, right)
  }
  expr
}

///|
/// Parse assignment operators
fn Parser::parse_assignment(self : Parser) -> @ast.Expr raise ParseError {
  let expr = self.parse_or()
  match self.current() {
    Some(@lexer.Token::TAssign) => {
      self.advance()
      @ast.Expr::Assign(expr, self.parse_or())
    }
    Some(@lexer.Token::TUpdate) => {
      self.advance()
      @ast.Expr::Update(expr, self.parse_or())
    }
    Some(@lexer.Token::TAlternative) => {
      self.advance()
      @ast.Expr::Alternative(expr, self.parse_or())
    }
    _ => expr
  }
}

///|
/// Parse logical or
fn Parser::parse_or(self : Parser) -> @ast.Expr raise ParseError {
  let mut expr = self.parse_and()
  while self.consume(@lexer.Token::TOr) {
    expr = @ast.Expr::Operation(expr, @ast.BinaryOp::Or, self.parse_and())
  }
  expr
}

///|
/// Parse logical and
fn Parser::parse_and(self : Parser) -> @ast.Expr raise ParseError {
  let mut expr = self.parse_comparison()
  while self.consume(@lexer.Token::TAnd) {
    expr = @ast.Expr::Operation(
      expr,
      @ast.BinaryOp::And,
      self.parse_comparison(),
    )
  }
  expr
}

///|
/// Parse comparison operators
fn Parser::parse_comparison(self : Parser) -> @ast.Expr raise ParseError {
  let expr = self.parse_additive()
  match self.current() {
    Some(@lexer.Token::TEq) => {
      self.advance()
      @ast.Expr::Operation(expr, @ast.BinaryOp::Equal, self.parse_additive())
    }
    Some(@lexer.Token::TNeq) => {
      self.advance()
      @ast.Expr::Operation(expr, @ast.BinaryOp::NotEqual, self.parse_additive())
    }
    Some(@lexer.Token::TLt) => {
      self.advance()
      @ast.Expr::Operation(expr, @ast.BinaryOp::LessThan, self.parse_additive())
    }
    Some(@lexer.Token::TLe) => {
      self.advance()
      @ast.Expr::Operation(expr, @ast.BinaryOp::LessEq, self.parse_additive())
    }
    Some(@lexer.Token::TGt) => {
      self.advance()
      @ast.Expr::Operation(
        expr,
        @ast.BinaryOp::GreaterThan,
        self.parse_additive(),
      )
    }
    Some(@lexer.Token::TGe) => {
      self.advance()
      @ast.Expr::Operation(
        expr,
        @ast.BinaryOp::GreaterEq,
        self.parse_additive(),
      )
    }
    _ => expr
  }
}

///|
/// Parse additive operators
fn Parser::parse_additive(self : Parser) -> @ast.Expr raise ParseError {
  let mut expr = self.parse_multiplicative()
  while true {
    match self.current() {
      Some(@lexer.Token::TPlus) => {
        self.advance()
        expr = @ast.Expr::Operation(
          expr,
          @ast.BinaryOp::Add,
          self.parse_multiplicative(),
        )
      }
      Some(@lexer.Token::TMinus) => {
        self.advance()
        expr = @ast.Expr::Operation(
          expr,
          @ast.BinaryOp::Subtract,
          self.parse_multiplicative(),
        )
      }
      _ => break
    }
  }
  expr
}

///|
/// Parse multiplicative operators
fn Parser::parse_multiplicative(self : Parser) -> @ast.Expr raise ParseError {
  let mut expr = self.parse_unary()
  while true {
    match self.current() {
      Some(@lexer.Token::TStar) => {
        self.advance()
        expr = @ast.Expr::Operation(
          expr,
          @ast.BinaryOp::Multiply,
          self.parse_unary(),
        )
      }
      Some(@lexer.Token::TSlash) => {
        self.advance()
        expr = @ast.Expr::Operation(
          expr,
          @ast.BinaryOp::Divide,
          self.parse_unary(),
        )
      }
      Some(@lexer.Token::TPercent) => {
        self.advance()
        expr = @ast.Expr::Operation(
          expr,
          @ast.BinaryOp::Modulo,
          self.parse_unary(),
        )
      }
      _ => break
    }
  }
  expr
}

///|
/// Parse unary operators
fn Parser::parse_unary(self : Parser) -> @ast.Expr raise ParseError {
  if self.consume(@lexer.Token::TNot) {
    @ast.Expr::Not
  } else {
    self.parse_postfix()
  }
}

///|
/// Parse postfix operators
fn Parser::parse_postfix(self : Parser) -> @ast.Expr raise ParseError {
  let mut expr = self.parse_primary()
  while true {
    match self.current() {
      Some(@lexer.Token::TQuestion) => {
        self.advance()
        expr = @ast.Expr::Optional(expr)
      }
      Some(@lexer.Token::TLBracket) => {
        self.advance()
        expr = self.parse_index_or_slice(expr)
      }
      Some(@lexer.Token::TDot) => {
        self.advance()
        expr = self.parse_field_access(expr)
      }
      _ => break
    }
  }
  expr
}

///|
/// Parse array index or slice
fn Parser::parse_index_or_slice(
  self : Parser,
  base : @ast.Expr,
) -> @ast.Expr raise ParseError {
  if self.consume(@lexer.Token::TRBracket) {
    return @ast.Expr::Pipe(base, @ast.Expr::Index([]))
  }
  let start_or_index = self.parse_slice_part()
  if self.consume(@lexer.Token::TColon) {
    let end = self.parse_slice_part()
    self.expect(@lexer.Token::TRBracket)
    @ast.Expr::Pipe(base, @ast.Expr::Slice(start_or_index, end))
  } else {
    let mut indices = match start_or_index {
      Some(n) => [n]
      None => raise ParseError::InvalidSyntax("Expected index")
    }
    while self.consume(@lexer.Token::TComma) {
      match self.parse_slice_part() {
        Some(n) => indices = indices + [n]
        None => raise ParseError::InvalidSyntax("Expected index after comma")
      }
    }
    self.expect(@lexer.Token::TRBracket)
    @ast.Expr::Pipe(base, @ast.Expr::Index(indices))
  }
}

///|
/// Parse optional integer for slice
fn Parser::parse_slice_part(self : Parser) -> Int? raise ParseError {
  match self.current() {
    Some(@lexer.Token::TNumber(n)) => {
      self.advance()
      Some(n.to_int())
    }
    Some(@lexer.Token::TMinus) => {
      self.advance()
      match self.current() {
        Some(@lexer.Token::TNumber(n)) => {
          self.advance()
          Some(-n.to_int())
        }
        _ => raise ParseError::InvalidSyntax("Expected number after minus")
      }
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
    Some(@lexer.Token::TIdentifier(name)) => {
      self.advance()
      @ast.Expr::Pipe(base, @ast.Expr::Key(name))
    }
    Some(@lexer.Token::TLBracket) => {
      self.advance()
      self.parse_index_or_slice(base)
    }
    Some(@lexer.Token::TDot) => {
      self.advance()
      @ast.Expr::Recurse
    }
    _ => base
  }
}

///|
/// Parse primary expressions
fn Parser::parse_primary(self : Parser) -> @ast.Expr raise ParseError {
  match self.current() {
    Some(@lexer.Token::TNull) => {
      self.advance()
      @ast.Expr::Literal(@ast.Literal::Null)
    }
    Some(@lexer.Token::TTrue) => {
      self.advance()
      @ast.Expr::Literal(@ast.Literal::Bool(true))
    }
    Some(@lexer.Token::TFalse) => {
      self.advance()
      @ast.Expr::Literal(@ast.Literal::Bool(false))
    }
    Some(@lexer.Token::TNumber(n)) => {
      self.advance()
      @ast.Expr::Literal(@ast.Literal::Number(n))
    }
    Some(@lexer.Token::TString(s)) => {
      self.advance()
      @ast.Expr::Literal(@ast.Literal::String(s))
    }
    Some(@lexer.Token::TDotDot) => {
      self.advance()
      @ast.Expr::Recurse
    }
    Some(@lexer.Token::TDot) => {
      self.advance()
      match self.current() {
        Some(@lexer.Token::TIdentifier(name)) => {
          self.advance()
          @ast.Expr::Key(name)
        }
        Some(@lexer.Token::TLBracket) => {
          self.advance()
          self.parse_index_or_slice(@ast.Expr::Identity)
        }
        _ => @ast.Expr::Identity
      }
    }
    Some(@lexer.Token::TVariable(name)) => {
      self.advance()
      @ast.Expr::Variable(name)
    }
    Some(@lexer.Token::TLParen) => {
      self.advance()
      let expr = self.parse_pipe()
      self.expect(@lexer.Token::TRParen)
      expr
    }
    Some(@lexer.Token::TLBracket) => {
      self.advance()
      if self.consume(@lexer.Token::TRBracket) {
        @ast.Expr::ArrayConstruct(None)
      } else {
        let expr = self.parse_pipe()
        self.expect(@lexer.Token::TRBracket)
        @ast.Expr::ArrayConstruct(Some(expr))
      }
    }
    Some(@lexer.Token::TLBrace) => {
      self.advance()
      self.parse_object()
    }
    Some(@lexer.Token::TIf) => self.parse_if()
    Some(@lexer.Token::TTry) => self.parse_try()
    Some(@lexer.Token::TIdentifier(name)) => {
      self.advance()
      self.parse_builtin(name)
    }
    Some(t) => raise ParseError::UnexpectedToken(t.to_string(), "expression")
    None => raise ParseError::UnexpectedEnd("expression")
  }
}

///|
/// Parse object constructor  
fn Parser::parse_object(self : Parser) -> @ast.Expr raise ParseError {
  if self.consume(@lexer.Token::TRBrace) {
    return @ast.Expr::ObjectConstruct([])
  }
  let mut pairs : Array[(@ast.Expr, @ast.Expr?)] = []
  while true {
    let key = match self.current() {
      Some(@lexer.Token::TIdentifier(name)) => {
        self.advance()
        @ast.Expr::Literal(@ast.Literal::String(name))
      }
      Some(@lexer.Token::TString(name)) => {
        self.advance()
        @ast.Expr::Literal(@ast.Literal::String(name))
      }
      Some(@lexer.Token::TLParen) => {
        self.advance()
        let expr = self.parse_pipe()
        self.expect(@lexer.Token::TRParen)
        expr
      }
      _ => raise ParseError::InvalidSyntax("Expected object key")
    }
    let value = if self.consume(@lexer.Token::TColon) {
      Some(self.parse_assignment())
    } else {
      None
    }
    pairs = pairs + [(key, value)]
    if !self.consume(@lexer.Token::TComma) {
      break
    }
    if self.check(@lexer.Token::TRBrace) {
      break
    }
  }
  self.expect(@lexer.Token::TRBrace)
  @ast.Expr::ObjectConstruct(pairs)
}

///|
/// Parse if-then-else
fn Parser::parse_if(self : Parser) -> @ast.Expr raise ParseError {
  self.advance()
  let cond = self.parse_pipe()
  self.expect(@lexer.Token::TThen)
  let then_expr = self.parse_pipe()
  self.expect(@lexer.Token::TElse)
  let else_expr = self.parse_pipe()
  self.expect(@lexer.Token::TEnd)
  @ast.Expr::IfThenElse(cond, then_expr, else_expr)
}

///|
/// Parse try-catch
fn Parser::parse_try(self : Parser) -> @ast.Expr raise ParseError {
  self.advance()
  let expr = self.parse_postfix()
  let handler = if self.consume(@lexer.Token::TCatch) {
    Some(self.parse_postfix())
  } else {
    None
  }
  @ast.Expr::TryCatch(expr, handler)
}

///|
/// Parse built-in functions
fn Parser::parse_builtin(
  self : Parser,
  name : String,
) -> @ast.Expr raise ParseError {
  match name {
    "length" => @ast.Expr::Length
    "keys" => @ast.Expr::Keys
    "values" => @ast.Expr::Values
    "type" => @ast.Expr::Type
    "empty" => @ast.Expr::Empty
    "not" => @ast.Expr::Not
    "map" => {
      self.expect(@lexer.Token::TLParen)
      let expr = self.parse_pipe()
      self.expect(@lexer.Token::TRParen)
      @ast.Expr::Map(expr)
    }
    "select" => {
      self.expect(@lexer.Token::TLParen)
      let expr = self.parse_pipe()
      self.expect(@lexer.Token::TRParen)
      @ast.Expr::Select(expr)
    }
    "sort" => @ast.Expr::Sort
    "reverse" => @ast.Expr::Reverse
    "flatten" =>
      if self.consume(@lexer.Token::TLParen) {
        match self.current() {
          Some(@lexer.Token::TNumber(n)) => {
            self.advance()
            self.expect(@lexer.Token::TRParen)
            @ast.Expr::Flatten(Some(n.to_int()))
          }
          _ => {
            self.expect(@lexer.Token::TRParen)
            @ast.Expr::Flatten(None)
          }
        }
      } else {
        @ast.Expr::Flatten(None)
      }
    "unique" => @ast.Expr::Unique
    "add" => @ast.Expr::Add
    "floor" => @ast.Expr::Floor
    "sqrt" => @ast.Expr::Sqrt
    "min" => @ast.Expr::Min
    "max" => @ast.Expr::Max
    "round" => @ast.Expr::Round
    "ceil" => @ast.Expr::Ceil
    "abs" => @ast.Expr::Abs
    "split" => {
      self.expect(@lexer.Token::TLParen)
      match self.current() {
        Some(@lexer.Token::TString(sep)) => {
          self.advance()
          self.expect(@lexer.Token::TRParen)
          @ast.Expr::Split(sep)
        }
        _ => raise ParseError::InvalidSyntax("split expects string argument")
      }
    }
    "join" => {
      self.expect(@lexer.Token::TLParen)
      match self.current() {
        Some(@lexer.Token::TString(sep)) => {
          self.advance()
          self.expect(@lexer.Token::TRParen)
          @ast.Expr::Join(sep)
        }
        _ => raise ParseError::InvalidSyntax("join expects string argument")
      }
    }
    "startswith" => {
      self.expect(@lexer.Token::TLParen)
      match self.current() {
        Some(@lexer.Token::TString(prefix)) => {
          self.advance()
          self.expect(@lexer.Token::TRParen)
          @ast.Expr::StartsWith(prefix)
        }
        _ =>
          raise ParseError::InvalidSyntax("startswith expects string argument")
      }
    }
    "endswith" => {
      self.expect(@lexer.Token::TLParen)
      match self.current() {
        Some(@lexer.Token::TString(suffix)) => {
          self.advance()
          self.expect(@lexer.Token::TRParen)
          @ast.Expr::EndsWith(suffix)
        }
        _ => raise ParseError::InvalidSyntax("endswith expects string argument")
      }
    }
    "contains" => {
      self.expect(@lexer.Token::TLParen)
      let expr = self.parse_pipe()
      self.expect(@lexer.Token::TRParen)
      @ast.Expr::Contains(expr)
    }
    "inside" => {
      self.expect(@lexer.Token::TLParen)
      let expr = self.parse_pipe()
      self.expect(@lexer.Token::TRParen)
      @ast.Expr::Inside(expr)
    }
    "has" => {
      self.expect(@lexer.Token::TLParen)
      match self.current() {
        Some(@lexer.Token::TString(key)) => {
          self.advance()
          self.expect(@lexer.Token::TRParen)
          @ast.Expr::Has(key)
        }
        _ => raise ParseError::InvalidSyntax("has expects string argument")
      }
    }
    "in" => {
      self.expect(@lexer.Token::TLParen)
      let expr = self.parse_pipe()
      self.expect(@lexer.Token::TRParen)
      @ast.Expr::In(expr)
    }
    "to_entries" => @ast.Expr::ToEntries
    "from_entries" => @ast.Expr::FromEntries
    "with_entries" => {
      self.expect(@lexer.Token::TLParen)
      let expr = self.parse_pipe()
      self.expect(@lexer.Token::TRParen)
      @ast.Expr::WithEntries(expr)
    }
    "range" => {
      self.expect(@lexer.Token::TLParen)
      match self.current() {
        Some(@lexer.Token::TNumber(n)) => {
          self.advance()
          self.expect(@lexer.Token::TRParen)
          @ast.Expr::Range(n.to_int())
        }
        _ => raise ParseError::InvalidSyntax("range expects number argument")
      }
    }
    "first" => @ast.Expr::First
    "last" => @ast.Expr::Last
    "indices" => {
      self.expect(@lexer.Token::TLParen)
      let expr = self.parse_pipe()
      self.expect(@lexer.Token::TRParen)
      @ast.Expr::IndicesOf(expr)
    }
    "index" => {
      self.expect(@lexer.Token::TLParen)
      let expr = self.parse_pipe()
      self.expect(@lexer.Token::TRParen)
      @ast.Expr::IndexOf(expr)
    }
    "any" => @ast.Expr::Any
    "all" => @ast.Expr::All
    "sort_by" => {
      self.expect(@lexer.Token::TLParen)
      let expr = self.parse_pipe()
      self.expect(@lexer.Token::TRParen)
      @ast.Expr::SortBy(expr)
    }
    "group_by" => {
      self.expect(@lexer.Token::TLParen)
      let expr = self.parse_pipe()
      self.expect(@lexer.Token::TRParen)
      @ast.Expr::GroupBy(expr)
    }
    _ => raise ParseError::InvalidSyntax("Unknown function: \{name}")
  }
}
