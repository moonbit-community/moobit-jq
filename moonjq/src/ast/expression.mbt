///|
/// jq expression AST
pub(all) enum Expr {
  // Core
  Identity // .
  Literal(Literal) // null, true, 123, "str"
  Pipe(Expr, Expr) // expr | expr
  Comma(Expr, Expr) // expr, expr
  // Access
  Key(String) // .foo
  Index(Array[Int]) // .[0], .[1,2,3], .[] (empty = iterator)
  Slice(Int?, Int?) // .[2:4], .[2:], .[:4]
  Optional(Expr) // expr?
  // Constructors
  ArrayConstruct(Expr?) // [expr] or []
  ObjectConstruct(Array[(Expr, Expr?)]) // {key: value, ...}
  // Operations
  Operation(Expr, BinaryOp, Expr) // expr op expr
  // Built-ins (Phase 2b)
  Length // length
  Keys // keys
  Values // values
  Type // type
  Empty // empty
  Not // not
  // Array/Object functions
  Map(Expr) // map(expr)
  Select(Expr) // select(expr)
  Sort // sort
  SortBy(Expr) // sort_by(expr)
  Reverse // reverse
  Flatten(Int?) // flatten, flatten(n)
  Unique // unique
  GroupBy(Expr) // group_by(expr)
  // Numeric
  Add // add (sum array)
  Floor // floor
  Sqrt // sqrt
  Min // min
  Max // max
  Round // round
  Ceil // ceil
  Abs // abs
  // String operations
  Split(String) // split(sep)
  Join(String) // join(sep)
  StartsWith(String) // startswith(str)
  EndsWith(String) // endswith(str)
  Contains(Expr) // contains(value)
  Inside(Expr) // inside(value)
  // Object/Array operations
  Has(String) // has(key)
  In(Expr) // in(object)
  ToEntries // to_entries
  FromEntries // from_entries
  WithEntries(Expr) // with_entries(expr)
  // Iteration helpers
  Range(Int) // range(n)
  First // first
  Last // last
  IndicesOf(Expr) // indices(value) - find all indices
  IndexOf(Expr) // index(value) - find first index
  // Predicates
  Any // any
  All // all
  // Control flow (Phase 2c)
  IfThenElse(Expr, Expr, Expr) // if cond then a else b end
  TryCatch(Expr, Expr?) // try expr catch handler
  // Variables and Reduce
  Variable(String) // $var
  As(Expr, String, Expr) // expr as $var | expr
  Reduce(Expr, String, Expr, Expr) // reduce expr as $var (init; update)
  // Advanced
  Recurse // recurse, ..
  RecurseWith(Expr, Expr) // recurse(f; cond)
  Walk(Expr) // walk(expr)
  Path(Expr) // path(expr)
  // Assignment
  Update(Expr, Expr) // |=
  Assign(Expr, Expr) // =
  Alternative(Expr, Expr) // //
  // Additional string functions
  LTrimStr(String) // ltrimstr(str)
  RTrimStr(String) // rtrimstr(str)
  AsciiUpcase // ascii_upcase
  AsciiDowncase // ascii_downcase
  // Additional array functions
  Nth(Int) // nth(n)
  RIndex(Expr) // rindex(value)
  // Path functions
  Paths // paths
  LeafPaths // leaf_paths
  GetPath(Expr) // getpath(path)
  SetPath(Expr, Expr) // setpath(path; value)
  DelPaths(Expr) // delpaths(paths)
  // Control flow
  Limit(Int, Expr) // limit(n; expr)
  Until(Expr, Expr) // until(cond; update)
  While(Expr, Expr) // while(cond; update)
  // Math functions
  Pow(Expr) // pow(base; exp)
  Log // log (natural log)
  Exp // exp (e^x)
  Sin // sin
  Cos // cos
  Tan // tan
  Asin // asin
  Acos // acos
  Atan // atan
  // Regex functions (stubs for now)
  Test(String) // test(regex)
  Match(String) // match(regex)
  Capture(String) // capture(regex)
  Splits(String) // splits(regex)
  Sub(String, String) // sub(regex; replacement)
  GSub(String, String) // gsub(regex; replacement)
} derive(Show, Eq, ToJson)
