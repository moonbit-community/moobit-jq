///|
/// Lexer error type
pub suberror LexError {
  UnexpectedChar(Int, Char)
  UnterminatedString(Int)
  InvalidNumber(Int, String)
  InvalidEscape(Int, Char)
} derive(Show, Eq)

///|
/// Lexer state
priv struct Lexer {
  input : String
  mut pos : Int
  mut tokens : Array[Token]
}

///|
/// Create a new lexer
fn Lexer::new(input : String) -> Lexer {
  { input, pos: 0, tokens: [] }
}

///|
/// Get current character
fn Lexer::current(self : Lexer) -> Char? {
  if self.pos < self.input.length() {
    self.input.get_char(self.pos)
  } else {
    None
  }
}

///|
/// Peek at next character
fn Lexer::peek(self : Lexer) -> Char? {
  if self.pos + 1 < self.input.length() {
    self.input.get_char(self.pos + 1)
  } else {
    None
  }
}

///|
/// Advance position
fn Lexer::advance(self : Lexer) -> Unit {
  self.pos = self.pos + 1
}

///|
/// Add a token
fn Lexer::add_token(self : Lexer, token : Token) -> Unit {
  self.tokens = self.tokens + [token]
}

///|
/// Skip whitespace
fn Lexer::skip_whitespace(self : Lexer) -> Unit {
  while true {
    match self.current() {
      Some(' ') | Some('\n') | Some('\r') | Some('\t') => self.advance()
      _ => break
    }
  }
}

///|
/// Skip comment (# to end of line)
fn Lexer::skip_comment(self : Lexer) -> Unit {
  while true {
    match self.current() {
      Some('\n') | None => break
      _ => self.advance()
    }
  }
}

///|
/// Check if character is digit
fn is_digit(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

///|
/// Check if character is letter or underscore
fn is_alpha(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_'
}

///|
/// Check if character is alphanumeric or underscore
fn is_alnum(c : Char) -> Bool {
  is_alpha(c) || is_digit(c)
}

///|
/// Lex a number
fn Lexer::lex_number(self : Lexer) -> Unit raise LexError {
  let start = self.pos
  let mut has_dot = false
  if self.current() == Some('-') {
    self.advance()
  }
  while true {
    match self.current() {
      Some(c) if is_digit(c) => self.advance()
      Some('.') if not(has_dot) && self.peek().map(is_digit).unwrap_or(false) => {
        has_dot = true
        self.advance()
      }
      _ => break
    }
  }
  let text = self.input[start:self.pos].to_string() catch {
    _ => raise LexError::InvalidNumber(start, "invalid slice")
  }
  let n = @strconv.parse_double(text) catch {
    _ => raise LexError::InvalidNumber(start, text)
  }
  self.add_token(TNumber(n))
}

///|
/// Lex a string
fn Lexer::lex_string(self : Lexer) -> Unit raise LexError {
  let start = self.pos
  self.advance()
  let buf = @buffer.new()
  while true {
    match self.current() {
      None => raise LexError::UnterminatedString(start)
      Some('"') => {
        self.advance()
        break
      }
      Some('\\') => {
        self.advance()
        match self.current() {
          None => raise LexError::UnterminatedString(start)
          Some('n') => {
            buf.write_char('\n')
            self.advance()
          }
          Some('r') => {
            buf.write_char('\r')
            self.advance()
          }
          Some('t') => {
            buf.write_char('\t')
            self.advance()
          }
          Some('\\') => {
            buf.write_char('\\')
            self.advance()
          }
          Some('"') => {
            buf.write_char('"')
            self.advance()
          }
          Some('/') => {
            buf.write_char('/')
            self.advance()
          }
          Some('b') => {
            buf.write_char('\b')
            self.advance()
          }
          Some(c) => raise LexError::InvalidEscape(self.pos, c)
        }
      }
      Some(c) => {
        buf.write_char(c)
        self.advance()
      }
    }
  }
  self.add_token(TString(buf.to_string()))
}

///|
/// Lex an identifier or keyword
fn Lexer::lex_identifier(self : Lexer) -> Unit raise LexError {
  let start = self.pos
  while true {
    match self.current() {
      Some(c) if is_alnum(c) => self.advance()
      _ => break
    }
  }
  let text = self.input[start:self.pos].to_string() catch {
    _ => raise LexError::UnexpectedChar(start, ' ')
  }
  let token = match text {
    "true" => TTrue
    "false" => TFalse
    "null" => TNull
    "and" => TAnd
    "or" => TOr
    "not" => TNot
    "if" => TIf
    "then" => TThen
    "else" => TElse
    "elif" => TElif
    "end" => TEnd
    "as" => TAs
    "reduce" => TReduce
    "foreach" => TForeach
    "try" => TTry
    "catch" => TCatch
    "def" => TDef
    _ => TIdentifier(text)
  }
  self.add_token(token)
}

///|
/// Lex a variable ($name)
fn Lexer::lex_variable(self : Lexer) -> Unit raise LexError {
  self.advance()
  let start = self.pos
  while true {
    match self.current() {
      Some(c) if is_alnum(c) => self.advance()
      _ => break
    }
  }
  let name = self.input[start:self.pos].to_string() catch {
    _ => raise LexError::UnexpectedChar(start, '$')
  }
  self.add_token(TVariable(name))
}

///|
/// Lex a format specifier (@base64, @uri, etc.)
fn Lexer::lex_format(self : Lexer) -> Unit raise LexError {
  self.advance()
  let start = self.pos
  while true {
    match self.current() {
      Some(c) if is_alnum(c) => self.advance()
      _ => break
    }
  }
  let name = self.input[start:self.pos].to_string() catch {
    _ => raise LexError::UnexpectedChar(start, '@')
  }
  self.add_token(TFormat(name))
}

///|
/// Main lexing function
pub fn lex(input : String) -> Array[Token] raise LexError {
  let lexer = Lexer::new(input)
  while true {
    lexer.skip_whitespace()
    match lexer.current() {
      None => break
      Some('#') => {
        lexer.skip_comment()
        continue
      }
      Some(c) =>
        if is_digit(c) ||
          (c == '-' && lexer.peek().map(is_digit).unwrap_or(false)) {
          lexer.lex_number()
        } else if c == '"' {
          lexer.lex_string()
        } else if is_alpha(c) {
          lexer.lex_identifier()
        } else if c == '$' {
          lexer.lex_variable()
        } else if c == '@' {
          lexer.lex_format()
        } else {
          match c {
            '.' => {
              lexer.advance()
              if lexer.current() == Some('.') {
                lexer.advance()
                lexer.add_token(TDotDot)
              } else {
                lexer.add_token(TDot)
              }
            }
            '|' => {
              lexer.advance()
              if lexer.current() == Some('=') {
                lexer.advance()
                lexer.add_token(TUpdate)
              } else {
                lexer.add_token(TPipe)
              }
            }
            '/' => {
              lexer.advance()
              if lexer.current() == Some('/') {
                lexer.advance()
                if lexer.current() == Some('=') {
                  lexer.advance()
                  lexer.add_token(TAltAssign)
                } else {
                  lexer.add_token(TAlternative)
                }
              } else if lexer.current() == Some('=') {
                lexer.advance()
                lexer.add_token(TDivAssign)
              } else {
                lexer.add_token(TSlash)
              }
            }
            '=' => {
              lexer.advance()
              if lexer.current() == Some('=') {
                lexer.advance()
                lexer.add_token(TEq)
              } else {
                lexer.add_token(TAssign)
              }
            }
            '!' => {
              lexer.advance()
              if lexer.current() == Some('=') {
                lexer.advance()
                lexer.add_token(TNeq)
              } else {
                raise LexError::UnexpectedChar(lexer.pos - 1, '!')
              }
            }
            '<' => {
              lexer.advance()
              if lexer.current() == Some('=') {
                lexer.advance()
                lexer.add_token(TLe)
              } else {
                lexer.add_token(TLt)
              }
            }
            '>' => {
              lexer.advance()
              if lexer.current() == Some('=') {
                lexer.advance()
                lexer.add_token(TGe)
              } else {
                lexer.add_token(TGt)
              }
            }
            ',' => {
              lexer.advance()
              lexer.add_token(TComma)
            }
            ':' => {
              lexer.advance()
              lexer.add_token(TColon)
            }
            ';' => {
              lexer.advance()
              lexer.add_token(TSemicolon)
            }
            '?' => {
              lexer.advance()
              lexer.add_token(TQuestion)
            }
            '(' => {
              lexer.advance()
              lexer.add_token(TLParen)
            }
            ')' => {
              lexer.advance()
              lexer.add_token(TRParen)
            }
            '[' => {
              lexer.advance()
              lexer.add_token(TLBracket)
            }
            ']' => {
              lexer.advance()
              lexer.add_token(TRBracket)
            }
            '{' => {
              lexer.advance()
              lexer.add_token(TLBrace)
            }
            '}' => {
              lexer.advance()
              lexer.add_token(TRBrace)
            }
            '+' => {
              lexer.advance()
              if lexer.current() == Some('=') {
                lexer.advance()
                lexer.add_token(TAddAssign)
              } else {
                lexer.add_token(TPlus)
              }
            }
            '-' => {
              lexer.advance()
              if lexer.current() == Some('=') {
                lexer.advance()
                lexer.add_token(TSubAssign)
              } else {
                lexer.add_token(TMinus)
              }
            }
            '*' => {
              lexer.advance()
              if lexer.current() == Some('=') {
                lexer.advance()
                lexer.add_token(TMulAssign)
              } else {
                lexer.add_token(TStar)
              }
            }
            '%' => {
              lexer.advance()
              if lexer.current() == Some('=') {
                lexer.advance()
                lexer.add_token(TModAssign)
              } else {
                lexer.add_token(TPercent)
              }
            }
            _ => raise LexError::UnexpectedChar(lexer.pos, c)
          }
        }
    }
  }
  lexer.add_token(TEof)
  lexer.tokens
}
