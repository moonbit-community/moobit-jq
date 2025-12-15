///|
/// Parser error types
pub(all) suberror ParseError {
  UnexpectedToken(String, String) // (found, expected) - using String to avoid ToJson requirement
  UnexpectedEnd(String) // (expected)
  InvalidSyntax(String)
  InvalidExpression(String)
} derive(Eq, Show)

///|
/// Parser state
priv struct Parser {
  tokens : Array[Token]
  mut pos : Int
}

///|
/// Create a new parser from tokens
fn Parser::new(tokens : Array[Token]) -> Parser {
  { tokens, pos: 0 }
}

///|
/// Get current token
fn Parser::current(self : Parser) -> Token? {
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
fn Parser::check(self : Parser, expected : Token) -> Bool {
  match self.current() {
    Some(t) => t == expected
    None => false
  }
}

///|
/// Consume current token if it matches
fn Parser::consume(self : Parser, expected : Token) -> Bool {
  if self.check(expected) {
    self.advance()
    true
  } else {
    false
  }
}

///|
/// Expect and consume a token, raise error if not found
fn Parser::expect(self : Parser, expected : Token) -> Unit raise ParseError {
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
  let tokens = lex(input)
  let parser = Parser::new(tokens)
  parser.parse_definitions()
}

///|
/// Parse function definitions followed by expression
fn Parser::parse_definitions(self : Parser) -> @ast.Expr raise ParseError {
  let defs : Array[@ast.Expr] = []
  while self.current() == Some(Token::TDef) {
    defs.push(self.parse_function_def())
  }
  let main_expr = self.parse_pipe()
  // Chain definitions with main expression so they execute in order
  if defs.is_empty() {
    main_expr
  } else {
    // Fold defs from right to left so they execute in order
    defs
    .rev()
    .fold(init=main_expr, fn(expr, def) { @ast.Expr::Pipe(def, expr) })
  }
}

///|
/// Parse pipe expression (lowest precedence)
fn Parser::parse_pipe(self : Parser) -> @ast.Expr raise ParseError {
  let mut expr = self.parse_comma()

  // Check for 'as $var' binding
  if self.consume(Token::TAs) {
    let var_name = match self.current() {
      Some(Token::TVariable(name)) => {
        self.advance()
        name
      }
      _ => raise ParseError::InvalidSyntax("Expected variable after 'as'")
    }
    // Expect pipe, then parse rest as body
    self.expect(Token::TPipe)
    let body = self.parse_pipe() // Recursively parse rest of pipe with variable in scope
    return @ast.Expr::As(expr, var_name, body)
  }

  // Normal pipe processing
  while self.consume(Token::TPipe) {
    let right = self.parse_comma()
    expr = @ast.Expr::Pipe(expr, right)
  }
  expr
}

///|
/// Parse comma expression
fn Parser::parse_comma(self : Parser) -> @ast.Expr raise ParseError {
  let mut expr = self.parse_assignment()
  while self.consume(Token::TComma) {
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
    Some(Token::TAssign) => {
      self.advance()
      @ast.Expr::Assign(expr, self.parse_or())
    }
    Some(Token::TUpdate) => {
      self.advance()
      @ast.Expr::Update(expr, self.parse_or())
    }
    Some(Token::TAlternative) => {
      self.advance()
      @ast.Expr::Alternative(expr, self.parse_or())
    }
    Some(Token::TAddAssign) => {
      self.advance()
      @ast.Expr::AddAssign(expr, self.parse_or())
    }
    Some(Token::TSubAssign) => {
      self.advance()
      @ast.Expr::SubAssign(expr, self.parse_or())
    }
    Some(Token::TMulAssign) => {
      self.advance()
      @ast.Expr::MulAssign(expr, self.parse_or())
    }
    Some(Token::TDivAssign) => {
      self.advance()
      @ast.Expr::DivAssign(expr, self.parse_or())
    }
    Some(Token::TModAssign) => {
      self.advance()
      @ast.Expr::ModAssign(expr, self.parse_or())
    }
    Some(Token::TAltAssign) => {
      self.advance()
      @ast.Expr::AltAssign(expr, self.parse_or())
    }
    _ => expr
  }
}

///|
/// Parse logical or
fn Parser::parse_or(self : Parser) -> @ast.Expr raise ParseError {
  let mut expr = self.parse_and()
  while self.consume(Token::TOr) {
    expr = @ast.Expr::Operation(expr, @ast.BinaryOp::Or, self.parse_and())
  }
  expr
}

///|
/// Parse logical and
fn Parser::parse_and(self : Parser) -> @ast.Expr raise ParseError {
  let mut expr = self.parse_comparison()
  while self.consume(Token::TAnd) {
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
    Some(Token::TEq) => {
      self.advance()
      @ast.Expr::Operation(expr, @ast.BinaryOp::Equal, self.parse_additive())
    }
    Some(Token::TNeq) => {
      self.advance()
      @ast.Expr::Operation(expr, @ast.BinaryOp::NotEqual, self.parse_additive())
    }
    Some(Token::TLt) => {
      self.advance()
      @ast.Expr::Operation(expr, @ast.BinaryOp::LessThan, self.parse_additive())
    }
    Some(Token::TLe) => {
      self.advance()
      @ast.Expr::Operation(expr, @ast.BinaryOp::LessEq, self.parse_additive())
    }
    Some(Token::TGt) => {
      self.advance()
      @ast.Expr::Operation(
        expr,
        @ast.BinaryOp::GreaterThan,
        self.parse_additive(),
      )
    }
    Some(Token::TGe) => {
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
      Some(Token::TPlus) => {
        self.advance()
        expr = @ast.Expr::Operation(
          expr,
          @ast.BinaryOp::Add,
          self.parse_multiplicative(),
        )
      }
      Some(Token::TMinus) => {
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
      Some(Token::TStar) => {
        self.advance()
        expr = @ast.Expr::Operation(
          expr,
          @ast.BinaryOp::Multiply,
          self.parse_unary(),
        )
      }
      Some(Token::TSlash) => {
        self.advance()
        expr = @ast.Expr::Operation(
          expr,
          @ast.BinaryOp::Divide,
          self.parse_unary(),
        )
      }
      Some(Token::TPercent) => {
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
  if self.consume(Token::TNot) {
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
      Some(Token::TQuestion) => {
        self.advance()
        expr = @ast.Expr::Optional(expr)
      }
      Some(Token::TLBracket) => {
        self.advance()
        expr = self.parse_index_or_slice(expr)
      }
      Some(Token::TDot) => {
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
  if self.consume(Token::TRBracket) {
    return @ast.Expr::Pipe(base, @ast.Expr::Index([]))
  }
  let start_or_index = self.parse_slice_part()
  if self.consume(Token::TColon) {
    let end = self.parse_slice_part()
    self.expect(Token::TRBracket)
    @ast.Expr::Pipe(base, @ast.Expr::Slice(start_or_index, end))
  } else {
    let indices : Array[Int] = []
    match start_or_index {
      Some(n) => indices.push(n)
      None => raise ParseError::InvalidSyntax("Expected index")
    }
    while self.consume(Token::TComma) {
      match self.parse_slice_part() {
        Some(n) => indices.push(n)
        None => raise ParseError::InvalidSyntax("Expected index after comma")
      }
    }
    self.expect(Token::TRBracket)
    @ast.Expr::Pipe(base, @ast.Expr::Index(indices))
  }
}

///|
/// Parse optional integer for slice
fn Parser::parse_slice_part(self : Parser) -> Int? raise ParseError {
  match self.current() {
    Some(Token::TNumber(n)) => {
      self.advance()
      Some(n.to_int())
    }
    Some(Token::TMinus) => {
      self.advance()
      match self.current() {
        Some(Token::TNumber(n)) => {
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
    Some(Token::TIdentifier(name)) => {
      self.advance()
      @ast.Expr::Pipe(base, @ast.Expr::Key(name))
    }
    Some(Token::TLBracket) => {
      self.advance()
      self.parse_index_or_slice(base)
    }
    Some(Token::TDot) => {
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
    Some(Token::TNull) => {
      self.advance()
      @ast.Expr::Literal(@ast.Literal::Null)
    }
    Some(Token::TTrue) => {
      self.advance()
      @ast.Expr::Literal(@ast.Literal::Bool(true))
    }
    Some(Token::TFalse) => {
      self.advance()
      @ast.Expr::Literal(@ast.Literal::Bool(false))
    }
    Some(Token::TNumber(n)) => {
      self.advance()
      @ast.Expr::Literal(@ast.Literal::Number(n))
    }
    Some(Token::TString(s)) => {
      self.advance()
      @ast.Expr::Literal(@ast.Literal::String(s))
    }
    Some(Token::TStringInterpolation(parts)) => {
      self.advance()
      let parsed_parts : Array[(String, @ast.Expr?)] = []
      for pair in parts {
        let (text, expr_opt) = pair
        match expr_opt {
          Some(expr_str) => {
            let expr_tokens = lex(expr_str) catch {
              _ =>
                raise ParseError::InvalidExpression(
                  "Failed to parse interpolation",
                )
            }
            let expr_parser = Parser::new(expr_tokens)
            let expr = expr_parser.parse_pipe()
            parsed_parts.push((text, Some(expr)))
          }
          None => parsed_parts.push((text, None))
        }
      }
      @ast.Expr::StringInterpolation(parsed_parts)
    }
    Some(Token::TDotDot) => {
      self.advance()
      @ast.Expr::Recurse
    }
    Some(Token::TDot) => {
      self.advance()
      match self.current() {
        Some(Token::TIdentifier(name)) => {
          self.advance()
          @ast.Expr::Key(name)
        }
        Some(Token::TLBracket) => {
          self.advance()
          self.parse_index_or_slice(@ast.Expr::Identity)
        }
        _ => @ast.Expr::Identity
      }
    }
    Some(Token::TVariable(name)) => {
      self.advance()
      @ast.Expr::Variable(name)
    }
    Some(Token::TFormat(name)) => {
      self.advance()
      @ast.Expr::Format(name)
    }
    Some(Token::TLParen) => {
      self.advance()
      let expr = self.parse_pipe()
      self.expect(Token::TRParen)
      expr
    }
    Some(Token::TLBracket) => {
      self.advance()
      if self.consume(Token::TRBracket) {
        @ast.Expr::ArrayConstruct(None)
      } else {
        let expr = self.parse_pipe()
        self.expect(Token::TRBracket)
        @ast.Expr::ArrayConstruct(Some(expr))
      }
    }
    Some(Token::TLBrace) => {
      self.advance()
      self.parse_object()
    }
    Some(Token::TIf) => self.parse_if()
    Some(Token::TTry) => self.parse_try()
    Some(Token::TReduce) => self.parse_reduce()
    Some(Token::TForeach) => self.parse_foreach()
    Some(Token::TIdentifier(name)) => {
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
  if self.consume(Token::TRBrace) {
    return @ast.Expr::ObjectConstruct([])
  }
  let pairs : Array[(@ast.Expr, @ast.Expr?)] = []
  while true {
    let key = match self.current() {
      Some(Token::TIdentifier(name)) => {
        self.advance()
        @ast.Expr::Literal(@ast.Literal::String(name))
      }
      Some(Token::TString(name)) => {
        self.advance()
        @ast.Expr::Literal(@ast.Literal::String(name))
      }
      Some(Token::TLParen) => {
        self.advance()
        let expr = self.parse_pipe()
        self.expect(Token::TRParen)
        expr
      }
      _ => raise ParseError::InvalidSyntax("Expected object key")
    }
    let value = if self.consume(Token::TColon) {
      Some(self.parse_assignment())
    } else {
      None
    }
    pairs.push((key, value))
    if !self.consume(Token::TComma) {
      break
    }
    if self.check(Token::TRBrace) {
      break
    }
  }
  self.expect(Token::TRBrace)
  @ast.Expr::ObjectConstruct(pairs)
}

///|
/// Parse if-then-else
fn Parser::parse_if(self : Parser) -> @ast.Expr raise ParseError {
  self.advance()
  let cond = self.parse_pipe()
  self.expect(Token::TThen)
  let then_expr = self.parse_pipe()
  self.expect(Token::TElse)
  let else_expr = self.parse_pipe()
  self.expect(Token::TEnd)
  @ast.Expr::IfThenElse(cond, then_expr, else_expr)
}

///|
/// Parse try-catch
fn Parser::parse_try(self : Parser) -> @ast.Expr raise ParseError {
  self.advance()
  let expr = self.parse_postfix()
  let handler = if self.consume(Token::TCatch) {
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
  if not(self.consume(Token::TAs)) {
    raise ParseError::InvalidSyntax("reduce expects 'as' after expression")
  }
  // Expect variable
  let var_name = match self.current() {
    Some(Token::TVariable(name)) => {
      self.advance()
      name
    }
    _ => raise ParseError::InvalidSyntax("reduce expects variable after as")
  }
  // Expect (INIT; UPDATE)
  self.expect(Token::TLParen)
  let init_expr = self.parse_pipe()
  self.expect(Token::TSemicolon)
  let update_expr = self.parse_pipe()
  self.expect(Token::TRParen)
  @ast.Expr::Reduce(gen_expr, var_name, init_expr, update_expr)
}

///|
/// Parse foreach: foreach EXPR as $VAR (INIT; UPDATE) or (INIT; UPDATE; EXTRACT)
fn Parser::parse_foreach(self : Parser) -> @ast.Expr raise ParseError {
  self.advance() // consume 'foreach'
  let gen_expr = self.parse_postfix() // generator expression
  // Expect 'as'
  if not(self.consume(Token::TAs)) {
    raise ParseError::InvalidSyntax("foreach expects 'as' after expression")
  }
  // Expect variable
  let var_name = match self.current() {
    Some(Token::TVariable(name)) => {
      self.advance()
      name
    }
    _ => raise ParseError::InvalidSyntax("foreach expects variable after as")
  }
  // Expect (INIT; UPDATE) or (INIT; UPDATE; EXTRACT)
  self.expect(Token::TLParen)
  let init_expr = self.parse_pipe()
  self.expect(Token::TSemicolon)
  let update_expr = self.parse_pipe()
  // Check for optional extract expression
  let extract_expr = if self.consume(Token::TSemicolon) {
    Some(self.parse_pipe())
  } else {
    None
  }
  self.expect(Token::TRParen)
  @ast.Expr::Foreach(gen_expr, var_name, init_expr, update_expr, extract_expr)
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
      self.expect(Token::TLParen)
      let expr = self.parse_pipe()
      self.expect(Token::TRParen)
      @ast.Expr::Map(expr)
    }
    "select" => {
      self.expect(Token::TLParen)
      let expr = self.parse_pipe()
      self.expect(Token::TRParen)
      @ast.Expr::Select(expr)
    }
    "sort" => @ast.Expr::Sort
    "reverse" => @ast.Expr::Reverse
    "flatten" =>
      if self.consume(Token::TLParen) {
        match self.current() {
          Some(Token::TNumber(n)) => {
            self.advance()
            self.expect(Token::TRParen)
            @ast.Expr::Flatten(Some(n.to_int()))
          }
          _ => {
            self.expect(Token::TRParen)
            @ast.Expr::Flatten(None)
          }
        }
      } else {
        @ast.Expr::Flatten(None)
      }
    "unique" => @ast.Expr::Unique
    "unique_by" => {
      self.expect(Token::TLParen)
      let expr = self.parse_pipe()
      self.expect(Token::TRParen)
      @ast.Expr::UniqueBy(expr)
    }
    "combinations" => @ast.Expr::Combinations
    "transpose" => @ast.Expr::Transpose
    "add" => @ast.Expr::Add
    "floor" => @ast.Expr::Floor
    "sqrt" => @ast.Expr::Sqrt
    "min" => @ast.Expr::Min
    "min_by" => {
      self.expect(Token::TLParen)
      let expr = self.parse_pipe()
      self.expect(Token::TRParen)
      @ast.Expr::MinBy(expr)
    }
    "max" => @ast.Expr::Max
    "max_by" => {
      self.expect(Token::TLParen)
      let expr = self.parse_pipe()
      self.expect(Token::TRParen)
      @ast.Expr::MaxBy(expr)
    }
    "round" => @ast.Expr::Round
    "ceil" => @ast.Expr::Ceil
    "abs" => @ast.Expr::Abs
    "split" => {
      self.expect(Token::TLParen)
      match self.current() {
        Some(Token::TString(sep)) => {
          self.advance()
          self.expect(Token::TRParen)
          @ast.Expr::Split(sep)
        }
        _ => raise ParseError::InvalidSyntax("split expects string argument")
      }
    }
    "join" => {
      self.expect(Token::TLParen)
      match self.current() {
        Some(Token::TString(sep)) => {
          self.advance()
          self.expect(Token::TRParen)
          @ast.Expr::Join(sep)
        }
        _ => raise ParseError::InvalidSyntax("join expects string argument")
      }
    }
    "startswith" => {
      self.expect(Token::TLParen)
      match self.current() {
        Some(Token::TString(prefix)) => {
          self.advance()
          self.expect(Token::TRParen)
          @ast.Expr::StartsWith(prefix)
        }
        _ =>
          raise ParseError::InvalidSyntax("startswith expects string argument")
      }
    }
    "endswith" => {
      self.expect(Token::TLParen)
      match self.current() {
        Some(Token::TString(suffix)) => {
          self.advance()
          self.expect(Token::TRParen)
          @ast.Expr::EndsWith(suffix)
        }
        _ => raise ParseError::InvalidSyntax("endswith expects string argument")
      }
    }
    "contains" => {
      self.expect(Token::TLParen)
      let expr = self.parse_pipe()
      self.expect(Token::TRParen)
      @ast.Expr::Contains(expr)
    }
    "inside" => {
      self.expect(Token::TLParen)
      let expr = self.parse_pipe()
      self.expect(Token::TRParen)
      @ast.Expr::Inside(expr)
    }
    "has" => {
      self.expect(Token::TLParen)
      match self.current() {
        Some(Token::TString(key)) => {
          self.advance()
          self.expect(Token::TRParen)
          @ast.Expr::Has(key)
        }
        Some(Token::TNumber(n)) => {
          self.advance()
          self.expect(Token::TRParen)
          @ast.Expr::Has(n.to_string())
        }
        _ =>
          raise ParseError::InvalidSyntax(
            "has expects string or number argument",
          )
      }
    }
    "in" => {
      self.expect(Token::TLParen)
      let expr = self.parse_pipe()
      self.expect(Token::TRParen)
      @ast.Expr::In(expr)
    }
    "to_entries" => @ast.Expr::ToEntries
    "from_entries" => @ast.Expr::FromEntries
    "with_entries" => {
      self.expect(Token::TLParen)
      let expr = self.parse_pipe()
      self.expect(Token::TRParen)
      @ast.Expr::WithEntries(expr)
    }
    "map_values" => {
      self.expect(Token::TLParen)
      let expr = self.parse_pipe()
      self.expect(Token::TRParen)
      @ast.Expr::MapValues(expr)
    }
    "range" => {
      self.expect(Token::TLParen)
      let first_expr = self.parse_pipe()
      // Check for semicolon to distinguish range(n) from range(from;to) or range(from;to;step)
      match self.current() {
        Some(Token::TSemicolon) => {
          self.advance() // consume semicolon
          let second_expr = self.parse_pipe()
          match self.current() {
            Some(Token::TSemicolon) => {
              // range(from;to;step)
              self.advance()
              let third_expr = self.parse_pipe()
              self.expect(Token::TRParen)
              @ast.Expr::RangeWithStep(first_expr, second_expr, third_expr)
            }
            _ => {
              // range(from;to)
              self.expect(Token::TRParen)
              @ast.Expr::RangeFromTo(first_expr, second_expr)
            }
          }
        }
        _ => {
          // range(n) - single argument
          self.expect(Token::TRParen)
          // Convert expr to literal int if possible
          match first_expr {
            @ast.Expr::Literal(@ast.Literal::Number(n)) =>
              @ast.Expr::Range(n.to_int())
            _ =>
              raise ParseError::InvalidSyntax("range(n) expects literal number")
          }
        }
      }
    }
    "first" =>
      // Check if there's a parenthesis for first(generator)
      match self.current() {
        Some(Token::TLParen) => {
          self.advance()
          let expr = self.parse_pipe()
          self.expect(Token::TRParen)
          @ast.Expr::FirstGen(expr)
        }
        _ => @ast.Expr::First
      }
    "last" =>
      match self.current() {
        Some(Token::TLParen) => {
          self.advance()
          let expr = self.parse_pipe()
          self.expect(Token::TRParen)
          @ast.Expr::LastGen(expr)
        }
        _ => @ast.Expr::Last
      }
    "repeat" => {
      self.expect(Token::TLParen)
      let expr = self.parse_pipe()
      self.expect(Token::TRParen)
      @ast.Expr::Repeat(expr)
    }
    "explode" => @ast.Expr::Explode
    "implode" => @ast.Expr::Implode
    "tojson" => @ast.Expr::ToJsonString
    "fromjson" => @ast.Expr::FromJsonString
    "indices" => {
      self.expect(Token::TLParen)
      let expr = self.parse_pipe()
      self.expect(Token::TRParen)
      @ast.Expr::IndicesOf(expr)
    }
    "index" => {
      self.expect(Token::TLParen)
      let expr = self.parse_pipe()
      self.expect(Token::TRParen)
      @ast.Expr::IndexOf(expr)
    }
    "any" =>
      match self.current() {
        Some(Token::TLParen) => {
          self.advance()
          let gen_expr = self.parse_pipe()
          match self.current() {
            Some(Token::TSemicolon) => {
              self.advance()
              let cond_expr = self.parse_pipe()
              self.expect(Token::TRParen)
              @ast.Expr::AnyGen(gen_expr, cond_expr)
            }
            _ =>
              raise ParseError::InvalidSyntax(
                "any(gen; cond) expects semicolon",
              )
          }
        }
        _ => @ast.Expr::Any
      }
    "all" =>
      match self.current() {
        Some(Token::TLParen) => {
          self.advance()
          let gen_expr = self.parse_pipe()
          match self.current() {
            Some(Token::TSemicolon) => {
              self.advance()
              let cond_expr = self.parse_pipe()
              self.expect(Token::TRParen)
              @ast.Expr::AllGen(gen_expr, cond_expr)
            }
            _ =>
              raise ParseError::InvalidSyntax(
                "all(gen; cond) expects semicolon",
              )
          }
        }
        _ => @ast.Expr::All
      }
    "sort_by" => {
      self.expect(Token::TLParen)
      let expr = self.parse_pipe()
      self.expect(Token::TRParen)
      @ast.Expr::SortBy(expr)
    }
    "group_by" => {
      self.expect(Token::TLParen)
      let expr = self.parse_pipe()
      self.expect(Token::TRParen)
      @ast.Expr::GroupBy(expr)
    }
    "ltrimstr" => {
      self.expect(Token::TLParen)
      match self.current() {
        Some(Token::TString(s)) => {
          self.advance()
          self.expect(Token::TRParen)
          @ast.Expr::LTrimStr(s)
        }
        _ => raise ParseError::InvalidSyntax("ltrimstr expects string argument")
      }
    }
    "rtrimstr" => {
      self.expect(Token::TLParen)
      match self.current() {
        Some(Token::TString(s)) => {
          self.advance()
          self.expect(Token::TRParen)
          @ast.Expr::RTrimStr(s)
        }
        _ => raise ParseError::InvalidSyntax("rtrimstr expects string argument")
      }
    }
    "ascii_upcase" => @ast.Expr::AsciiUpcase
    "ascii_downcase" => @ast.Expr::AsciiDowncase
    "nth" => {
      self.expect(Token::TLParen)
      match self.current() {
        Some(Token::TNumber(n)) => {
          self.advance()
          self.expect(Token::TRParen)
          @ast.Expr::Nth(n.to_int())
        }
        _ => raise ParseError::InvalidSyntax("nth expects number argument")
      }
    }
    "rindex" => {
      self.expect(Token::TLParen)
      let expr = self.parse_pipe()
      self.expect(Token::TRParen)
      @ast.Expr::RIndex(expr)
    }
    "paths" =>
      match self.current() {
        Some(Token::TLParen) => {
          self.advance()
          let expr = self.parse_pipe()
          self.expect(Token::TRParen)
          @ast.Expr::PathsWithFilter(expr)
        }
        _ => @ast.Expr::Paths
      }
    "leaf_paths" => @ast.Expr::LeafPaths
    "getpath" => {
      self.expect(Token::TLParen)
      let expr = self.parse_pipe()
      self.expect(Token::TRParen)
      @ast.Expr::GetPath(expr)
    }
    "setpath" => {
      self.expect(Token::TLParen)
      let path = self.parse_pipe()
      self.expect(Token::TSemicolon)
      let value = self.parse_pipe()
      self.expect(Token::TRParen)
      @ast.Expr::SetPath(path, value)
    }
    "delpaths" => {
      self.expect(Token::TLParen)
      let expr = self.parse_pipe()
      self.expect(Token::TRParen)
      @ast.Expr::DelPaths(expr)
    }
    "limit" => {
      self.expect(Token::TLParen)
      match self.current() {
        Some(Token::TNumber(n)) => {
          self.advance()
          self.expect(Token::TSemicolon)
          let expr = self.parse_pipe()
          self.expect(Token::TRParen)
          @ast.Expr::Limit(n.to_int(), expr)
        }
        _ => raise ParseError::InvalidSyntax("limit expects number argument")
      }
    }
    "until" => {
      self.expect(Token::TLParen)
      let cond = self.parse_pipe()
      self.expect(Token::TSemicolon)
      let update = self.parse_pipe()
      self.expect(Token::TRParen)
      @ast.Expr::Until(cond, update)
    }
    "while" => {
      self.expect(Token::TLParen)
      let cond = self.parse_pipe()
      self.expect(Token::TSemicolon)
      let update = self.parse_pipe()
      self.expect(Token::TRParen)
      @ast.Expr::While(cond, update)
    }
    "reduce" => {
      self.expect(Token::TLParen)
      let gen_expr = self.parse_pipe()
      self.expect(Token::TAs)
      match self.current() {
        Some(Token::TVariable(var_name)) => {
          self.advance()
          self.expect(Token::TLParen)
          let init_expr = self.parse_pipe()
          self.expect(Token::TSemicolon)
          let update_expr = self.parse_pipe()
          self.expect(Token::TRParen)
          self.expect(Token::TRParen)
          @ast.Expr::Reduce(gen_expr, var_name, init_expr, update_expr)
        }
        _ => raise ParseError::InvalidSyntax("reduce expects variable after as")
      }
    }
    "foreach" => {
      self.expect(Token::TLParen)
      let gen_expr = self.parse_pipe()
      self.expect(Token::TAs)
      match self.current() {
        Some(Token::TVariable(var_name)) => {
          self.advance()
          self.expect(Token::TLParen)
          let init_expr = self.parse_pipe()
          self.expect(Token::TSemicolon)
          let update_expr = self.parse_pipe()
          // Check for optional extract expression
          let extract_expr = match self.current() {
            Some(Token::TSemicolon) => {
              self.advance()
              Some(self.parse_pipe())
            }
            _ => None
          }
          self.expect(Token::TRParen)
          self.expect(Token::TRParen)
          @ast.Expr::Foreach(
            gen_expr, var_name, init_expr, update_expr, extract_expr,
          )
        }
        _ =>
          raise ParseError::InvalidSyntax("foreach expects variable after as")
      }
    }
    "scan" => {
      self.expect(Token::TLParen)
      match self.current() {
        Some(Token::TString(s)) => {
          self.advance()
          self.expect(Token::TRParen)
          @ast.Expr::Scan(s)
        }
        _ => raise ParseError::InvalidSyntax("scan expects string argument")
      }
    }
    "recurse" =>
      if self.consume(Token::TLParen) {
        let f = self.parse_pipe()
        self.expect(Token::TSemicolon)
        let cond = self.parse_pipe()
        self.expect(Token::TRParen)
        @ast.Expr::RecurseWith(f, cond)
      } else {
        @ast.Expr::Recurse
      }
    "walk" => {
      self.expect(Token::TLParen)
      let expr = self.parse_pipe()
      self.expect(Token::TRParen)
      @ast.Expr::Walk(expr)
    }
    "pow" => {
      self.expect(Token::TLParen)
      let base = self.parse_pipe()
      // Check if we have semicolon separator for two-argument form
      if self.consume(Token::TSemicolon) {
        let exponent = self.parse_pipe()
        self.expect(Token::TRParen)
        // For pow(base; exponent), create an expression that applies both
        // This will be: base | pow(exponent)
        @ast.Expr::Pipe(base, @ast.Expr::Pow(exponent))
      } else {
        self.expect(Token::TRParen)
        @ast.Expr::Pow(base)
      }
    }
    "log" => @ast.Expr::Log
    "exp" => @ast.Expr::Exp
    "sin" => @ast.Expr::Sin
    "cos" => @ast.Expr::Cos
    "tan" => @ast.Expr::Tan
    "asin" => @ast.Expr::Asin
    "acos" => @ast.Expr::Acos
    "atan" => @ast.Expr::Atan
    "test" => {
      self.expect(Token::TLParen)
      match self.current() {
        Some(Token::TString(s)) => {
          self.advance()
          self.expect(Token::TRParen)
          @ast.Expr::Test(s)
        }
        _ => raise ParseError::InvalidSyntax("test expects string argument")
      }
    }
    "match" => {
      self.expect(Token::TLParen)
      match self.current() {
        Some(Token::TString(s)) => {
          self.advance()
          self.expect(Token::TRParen)
          @ast.Expr::Match(s)
        }
        _ => raise ParseError::InvalidSyntax("match expects string argument")
      }
    }
    "capture" => {
      self.expect(Token::TLParen)
      match self.current() {
        Some(Token::TString(s)) => {
          self.advance()
          self.expect(Token::TRParen)
          @ast.Expr::Capture(s)
        }
        _ => raise ParseError::InvalidSyntax("capture expects string argument")
      }
    }
    "splits" => {
      self.expect(Token::TLParen)
      match self.current() {
        Some(Token::TString(s)) => {
          self.advance()
          self.expect(Token::TRParen)
          @ast.Expr::Splits(s)
        }
        _ => raise ParseError::InvalidSyntax("splits expects string argument")
      }
    }
    "sub" => {
      self.expect(Token::TLParen)
      match self.current() {
        Some(Token::TString(pattern)) => {
          self.advance()
          self.expect(Token::TSemicolon)
          match self.current() {
            Some(Token::TString(replacement)) => {
              self.advance()
              self.expect(Token::TRParen)
              @ast.Expr::Sub(pattern, replacement)
            }
            _ =>
              raise ParseError::InvalidSyntax("sub expects string replacement")
          }
        }
        _ => raise ParseError::InvalidSyntax("sub expects string pattern")
      }
    }
    "gsub" => {
      self.expect(Token::TLParen)
      match self.current() {
        Some(Token::TString(pattern)) => {
          self.advance()
          self.expect(Token::TSemicolon)
          match self.current() {
            Some(Token::TString(replacement)) => {
              self.advance()
              self.expect(Token::TRParen)
              @ast.Expr::GSub(pattern, replacement)
            }
            _ =>
              raise ParseError::InvalidSyntax("gsub expects string replacement")
          }
        }
        _ => raise ParseError::InvalidSyntax("gsub expects string pattern")
      }
    }
    _ =>
      // Check if it's a function call with parentheses
      if self.current() == Some(Token::TLParen) {
        self.advance()
        let args : Array[@ast.Expr] = []
        if not(self.current() == Some(Token::TRParen)) {
          args.push(self.parse_pipe())
          while self.consume(Token::TSemicolon) {
            args.push(self.parse_pipe())
          }
        }
        self.expect(Token::TRParen)
        @ast.Expr::FunctionCall(name, args)
      } else {
        // Zero-argument function call
        @ast.Expr::FunctionCall(name, [])
      }
  }
}

///|
/// Parse function definition: def name(params): body;
fn Parser::parse_function_def(self : Parser) -> @ast.Expr raise ParseError {
  self.expect(Token::TDef)
  let name = match self.current() {
    Some(Token::TIdentifier(n)) => {
      self.advance()
      n
    }
    _ => raise ParseError::UnexpectedToken("identifier", "function name")
  }
  let params : Array[String] = []
  // Optional parameters
  if self.consume(Token::TLParen) {
    if not(self.current() == Some(Token::TRParen)) {
      match self.current() {
        Some(Token::TIdentifier(p)) => {
          self.advance()
          params.push(p)
        }
        _ => raise ParseError::UnexpectedToken("identifier", "parameter")
      }
      while self.consume(Token::TSemicolon) {
        match self.current() {
          Some(Token::TIdentifier(p)) => {
            self.advance()
            params.push(p)
          }
          _ => raise ParseError::UnexpectedToken("identifier", "parameter")
        }
      }
    }
    self.expect(Token::TRParen)
  }
  self.expect(Token::TColon)
  let body = self.parse_pipe()
  self.expect(Token::TSemicolon)
  @ast.Expr::FunctionDef(name, params, body)
}
