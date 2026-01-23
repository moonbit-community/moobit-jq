///|
/// Interpreter error types
pub(all) suberror InterpreterError {
  TypeMismatch(String, String) // (expected, got)
  KeyNotFound(String)
  IndexOutOfBounds(Int)
  InvalidOperation(String)
  DivisionByZero
  TypeError(String)
  EvalError(String)
} derive(Eq, Debug, Show)
