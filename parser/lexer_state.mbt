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
  let _ = loop () {
    _ =>
      match self.current() {
        Some(' ') | Some('\n') | Some('\r') | Some('\t') => {
          self.advance()
          continue ()
        }
        _ => ()
      }
  }
}

///|
/// Skip comment (# to end of line)
fn Lexer::skip_comment(self : Lexer) -> Unit {
  let _ = loop () {
    _ =>
      match self.current() {
        Some('\n') | None => ()
        _ => {
          self.advance()
          continue ()
        }
      }
  }
}
