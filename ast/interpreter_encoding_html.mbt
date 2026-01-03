///|
/// HTML escape a string
fn html_escape(s : String) -> String {
  let buf = @buffer.new()
  for char in s {
    match char {
      '<' => buf.write_string("&lt;")
      '>' => buf.write_string("&gt;")
      '&' => buf.write_string("&amp;")
      '"' => buf.write_string("&quot;")
      '\'' => buf.write_string("&#39;")
      _ => buf.write_char(char)
    }
  }
  buf.to_string()
}
