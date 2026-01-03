///|
/// Main lexing function
pub fn lex(input : String) -> Array[Token] raise LexError {
  let lexer = Lexer::new(input)
  let _ = loop () {
    _ => {
      lexer.skip_whitespace()
      match lexer.current() {
        None => ()
        Some('#') => {
          lexer.skip_comment()
          continue ()
        }
        Some('"') => {
          lexer.lex_string()
          continue ()
        }
        Some('$') => {
          lexer.lex_variable()
          continue ()
        }
        Some('@') => {
          lexer.lex_format()
          continue ()
        }
        Some(c) if is_digit(c) ||
          (c == '-' && lexer.peek().map(is_digit).unwrap_or(false)) => {
          lexer.lex_number()
          continue ()
        }
        Some(c) if is_alpha(c) => {
          lexer.lex_identifier()
          continue ()
        }
        Some(c) => {
          lexer.lex_symbol(c)
          continue ()
        }
      }
    }
  }
  lexer.add_token(TEof)
  lexer.tokens
}
