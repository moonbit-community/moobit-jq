///|
/// URI encode a string
fn uri_encode(s : String) -> String {
  fn is_unreserved_byte(b : Byte) -> Bool {
    let code = b.to_uint().reinterpret_as_int()
    match code {
      0x41..=0x5A
      | 0x61..=0x7A
      | 0x30..=0x39
      | 0x2D
      | 0x5F
      | 0x2E
      // A-Z
      // a-z
      // 0-9
      // -
      // _
      // .
      // ~
      | 0x7E => true
      _ => false
    }
  }

  fn hex_upper_digit(n : Int) -> Char {
    let digits = "0123456789ABCDEF"
    digits.get_char(n).unwrap()
  }

  let bytes = @encoding/utf8.encode(s)
  let buf = @buffer.new()
  for b in bytes {
    if is_unreserved_byte(b) {
      buf.write_char(Int::unsafe_to_char(b.to_uint().reinterpret_as_int()))
    } else {
      let code = b.to_uint().reinterpret_as_int()
      buf.write_char('%')
      buf.write_char(hex_upper_digit((code >> 4) & 0x0f))
      buf.write_char(hex_upper_digit(code & 0x0f))
    }
  }
  buf.to_string()
}
