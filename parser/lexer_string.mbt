///|
/// Lex a string (with interpolation support)
fn Lexer::lex_string(self : Lexer) -> Unit raise LexError {
  let start = self.pos
  self.advance()
  let parts : Array[(String, String?)] = []
  let buf = @buffer.new()
  let _ = loop () {
    _ =>
      match self.current() {
        None => raise UnterminatedString(start)
        Some('"') => {
          self.advance()
          ()
        }
        Some('\\') => {
          self.advance()
          match self.current() {
            None => raise UnterminatedString(start)
            Some('(') => {
              // String interpolation: \\(expr)
              self.advance()
              parts.push((buf.to_string(), None))
              buf.reset()
              // Find the matching closing paren
              let expr_start = self.pos
              let _ = loop 1 {
                paren_depth =>
                  match self.current() {
                    None => raise UnterminatedString(start)
                    Some('(') => {
                      self.advance()
                      continue paren_depth + 1
                    }
                    Some(')') => {
                      let next_depth = paren_depth - 1
                      if next_depth == 0 {
                        let expr_text = try! self.input[expr_start:self.pos].to_string()
                        parts.push(("", Some(expr_text)))
                        self.advance()
                        ()
                      } else {
                        self.advance()
                        continue next_depth
                      }
                    }
                    Some('"') => {
                      // Skip nested strings
                      self.advance()
                      let _ = loop () {
                        _ =>
                          match self.current() {
                            Some('"') => {
                              self.advance()
                              ()
                            }
                            Some('\\') => {
                              self.advance()
                              self.advance()
                              continue ()
                            }
                            None => raise UnterminatedString(start)
                            _ => {
                              self.advance()
                              continue ()
                            }
                          }
                      }
                      continue paren_depth
                    }
                    _ => {
                      self.advance()
                      continue paren_depth
                    }
                  }
              }
              continue ()
            }
            Some('n') => {
              buf.write_char('\n')
              self.advance()
              continue ()
            }
            Some('r') => {
              buf.write_char('\r')
              self.advance()
              continue ()
            }
            Some('t') => {
              buf.write_char('\t')
              self.advance()
              continue ()
            }
            Some('\\') => {
              buf.write_char('\\')
              self.advance()
              continue ()
            }
            Some('"') => {
              buf.write_char('"')
              self.advance()
              continue ()
            }
            Some('/') => {
              buf.write_char('/')
              self.advance()
              continue ()
            }
            Some('b') => {
              buf.write_char('\b')
              self.advance()
              continue ()
            }
            Some(c) => raise InvalidEscape(self.pos, c)
          }
        }
        Some(c) => {
          buf.write_char(c)
          self.advance()
          continue ()
        }
      }
  }
  parts.push((buf.to_string(), None))
  if parts.length() == 1 && parts[0].1 is None {
    self.add_token(TString(parts[0].0))
  } else {
    self.add_token(TStringInterpolation(parts))
  }
}
