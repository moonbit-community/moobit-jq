///|
pub fn first_opt(results : Array[Json]) -> Json? {
  match results {
    [] => None
    [first, ..] => Some(first)
  }
}

///|
pub fn first_or_null(results : Array[Json]) -> Json {
  match results {
    [] => null
    [first, ..] => first
  }
}
