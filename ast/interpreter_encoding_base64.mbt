///|
/// Simple base64 encoding
fn base64_encode(bytes : Bytes) -> String {
  let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
  let buf = @buffer.new()
  let len = bytes.length()
  let mut i = 0
  while i < len {
    let b1 : UInt = bytes[i].to_uint()
    let b2 : UInt = if i + 1 < len { bytes[i + 1].to_uint() } else { 0 }
    let b3 : UInt = if i + 2 < len { bytes[i + 2].to_uint() } else { 0 }
    let c1 = (b1 >> 2).reinterpret_as_int()
    let c2 = (((b1 & 0x03) << 4) | (b2 >> 4)).reinterpret_as_int()
    let c3 = (((b2 & 0x0f) << 2) | (b3 >> 6)).reinterpret_as_int()
    let c4 = (b3 & 0x3f).reinterpret_as_int()
    buf.write_char(chars.get_char(c1).unwrap())
    buf.write_char(chars.get_char(c2).unwrap())
    if i + 1 < len {
      buf.write_char(chars.get_char(c3).unwrap())
    } else {
      buf.write_char('=')
    }
    if i + 2 < len {
      buf.write_char(chars.get_char(c4).unwrap())
    } else {
      buf.write_char('=')
    }
    i = i + 3
  }
  buf.to_string()
}

///|
/// Simple base64 decoding
fn base64_decode(s : String) -> Bytes raise InterpreterError {
  let len = s.length()
  if len % 4 != 0 {
    raise EvalError("Invalid base64")
  }
  fn base64_value(ch : Char) -> Int? {
    match ch {
      'A'..='Z' => Some(ch.to_int() - 'A'.to_int())
      'a'..='z' => Some(26 + ch.to_int() - 'a'.to_int())
      '0'..='9' => Some(52 + ch.to_int() - '0'.to_int())
      '+' => Some(62)
      '/' => Some(63)
      _ => None
    }
  }

  let buf : Array[Byte] = []
  let mut i = 0
  while i < len {
    let c1 = s.get_char(i).unwrap()
    let c2 = s.get_char(i + 1).unwrap()
    let c3 = s.get_char(i + 2).unwrap()
    let c4 = s.get_char(i + 3).unwrap()
    let v1 = match base64_value(c1) {
      Some(v) => v
      None => raise EvalError("Invalid base64")
    }
    let v2 = match base64_value(c2) {
      Some(v) => v
      None => raise EvalError("Invalid base64")
    }

    // Padding can only appear in the final 4-character quantum.
    if (c3 == '=' || c4 == '=') && i + 4 != len {
      raise EvalError("Invalid base64")
    }
    let v1u : UInt = v1.reinterpret_as_uint()
    let v2u : UInt = v2.reinterpret_as_uint()
    let b1 : UInt = (v1u << 2) | (v2u >> 4)
    buf.push(b1.to_byte())
    if c3 != '=' {
      let v3 = match base64_value(c3) {
        Some(v) => v
        None => raise EvalError("Invalid base64")
      }
      let v3u : UInt = v3.reinterpret_as_uint()
      let b2 : UInt = ((v2u & 0x0f) << 4) | (v3u >> 2)
      buf.push(b2.to_byte())
      if c4 != '=' {
        let v4 = match base64_value(c4) {
          Some(v) => v
          None => raise EvalError("Invalid base64")
        }
        let v4u : UInt = v4.reinterpret_as_uint()
        let b3 : UInt = ((v3u & 0x03) << 6) | v4u
        buf.push(b3.to_byte())
      }
    } else if c4 != '=' {
      raise EvalError("Invalid base64")
    }
    i = i + 4
  }
  Bytes::from_array(buf)
}
