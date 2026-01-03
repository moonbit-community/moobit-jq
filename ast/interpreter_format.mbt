///|
/// Evaluate format functions: @base64, @uri, @csv, etc.
fn eval_format(format_name : String, input : Json) -> Iterator[Json] raise InterpreterError {
  match format_name {
    "base64" =>
      match input {
        String(s) => {
          // Simple base64 encoding implementation
          let bytes = @encoding/utf8.encode(s)
          let encoded = base64_encode(bytes)
          Iterator::singleton(Json::string(encoded))
        }
        _ => raise TypeError("@base64 requires string")
      }
    "base64d" =>
      match input {
        String(s) => {
          // Simple base64 decoding implementation
          let decoded_bytes = base64_decode(s) catch {
            _ => raise EvalError("Invalid base64")
          }
          let decoded_str = @encoding/utf8.decode(decoded_bytes) catch {
            _ => raise EvalError("Invalid UTF-8")
          }
          Iterator::singleton(Json::string(decoded_str))
        }
        _ => raise TypeError("@base64d requires string")
      }
    "uri" =>
      match input {
        String(s) => {
          let encoded = uri_encode(s)
          Iterator::singleton(Json::string(encoded))
        }
        _ => raise TypeError("@uri requires string")
      }
    "csv" | "tsv" =>
      // Simple CSV/TSV formatting for arrays
      match input {
        Array(arr) => {
          let sep = if format_name == "csv" { "," } else { "\t" }
          let parts : Array[String] = []
          for item in arr {
            match item {
              String(s) =>
                // Quote if contains separator or quotes
                if s.contains(sep) || s.contains("\"") {
                  let escaped = s.replace(old="\"", new="\"\"")
                  parts.push("\"\{escaped}\"")
                } else {
                  parts.push(s)
                }
              Number(n, ..) => parts.push(n.to_string())
              True => parts.push("true")
              False => parts.push("false")
              Null => parts.push("")
              _ => parts.push(item.to_string())
            }
          }
          Iterator::singleton(Json::string(parts.join(sep)))
        }
        _ => raise TypeError("@csv/@tsv requires array")
      }
    "json" => Iterator::singleton(Json::string(input.to_string()))
    "text" => Iterator::singleton(Json::string(input.to_string()))
    "html" =>
      match input {
        String(s) => {
          let escaped = html_escape(s)
          Iterator::singleton(Json::string(escaped))
        }
        _ => raise TypeError("@html requires string")
      }
    _ => raise EvalError("Unknown format: @\{format_name}")
  }
}
