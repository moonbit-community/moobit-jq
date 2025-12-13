///|
test "type_name" {
  inspect(type_name(Json::null()), content="null")
  inspect(type_name(Json::boolean(true)), content="boolean")
  inspect(type_name(Json::boolean(false)), content="boolean")
  inspect(type_name(Json::number(42.0)), content="number")
  inspect(type_name(Json::string("hello")), content="string")
  inspect(type_name(Json::array([])), content="array")
  inspect(type_name(Json::object({})), content="object")
}

///|
test "Json::to_string - basic types" {
  inspect(Json::null().to_string(), content="Null")
  inspect(Json::boolean(true).to_string(), content="True")
  inspect(Json::boolean(false).to_string(), content="False")
  inspect(Json::number(42.0).to_string(), content="Number(42)")
  inspect(Json::number(3.14).to_string(), content="Number(3.14)")
  inspect(
    Json::string("hello").to_string(),
    content=(
      #|String("hello")
    ),
  )
}

///|
test "Json::to_string - arrays" {
  inspect(Json::array([]).to_string(), content="Array([])")
  inspect(
    Json::array([Json::number(1.0), Json::number(2.0), Json::number(3.0)]).to_string(),
    content="Array([Number(1), Number(2), Number(3)])",
  )
  inspect(
    Json::array([Json::string("a"), Json::string("b")]).to_string(),
    content=(
      #|Array([String("a"), String("b")])
    ),
  )
}

///|
test "Json::to_string - objects" {
  inspect(Json::object({}).to_string(), content="Object({})")
  let obj : Map[String, Json] = { "foo": Json::number(42.0) }
  inspect(
    Json::object(obj).to_string(),
    content=(
      #|Object({"foo": Number(42)})
    ),
  )
}

///|
test "Json::to_string - escape strings" {
  inspect(
    Json::string("hello\nworld").to_string(),
    content=(
      #|String("hello\nworld")
    ),
  )
  inspect(
    Json::string("tab\there").to_string(),
    content=(
      #|String("tab\there")
    ),
  )
  inspect(
    Json::string("quote\"here").to_string(),
    content=(
      #|String("quote\"here")
    ),
  )
  inspect(
    Json::string("back\\slash").to_string(),
    content=(
      #|String("back\\slash")
    ),
  )
}

///|
test "Json::parse - basic" {
  let json = parse("{\"foo\": 42}")
  inspect(type_name(json), content="object")
  inspect(
    json.to_string(),
    content=(
      #|Object({"foo": Number(42)})
    ),
  )
}

///|
test "Json equality" {
  assert_eq(Json::null(), Json::null())
  assert_eq(Json::boolean(true), Json::boolean(true))
  assert_eq(Json::boolean(false), Json::boolean(false))
  assert_eq(Json::number(42.0), Json::number(42.0))
  assert_eq(Json::string("hello"), Json::string("hello"))
}
