///|
enum InputSource {
  Stdin
  File(String)
  Inline(String)
}

///|
struct CliOptions {
  query : String
  input : InputSource
  logs : Bool
}

///|
enum CliParseResult {
  Help
  Error(String)
  Run(CliOptions)
}

///|
fn help_message() -> String {
  let message =
    #|Usage: moon run cmd/jq -- [options] <query> [input]
    #|
    #|Options:
    #|  -f, --file <path>   Read input JSON from a file.
    #|  -l, --logs          Treat input as newline-delimited JSON logs.
    #|  -h, --help          Show this help message.
    #|
    #|If [input] is omitted, stdin is used.
    #|If [input] is provided without --file, it is treated as a JSON string.
    #|
    #|Examples:
    #|  moon run cmd/jq -- '.foo' '{"foo": 1}'
    #|  moon run cmd/jq -- -f data.json '.items[]'
    #|  cat logs.ndjson | moon run cmd/jq -- --logs '.message'
  message
}

///|
fn parse_cli(args : ArrayView[String]) -> CliParseResult {
  let mut logs = false
  let mut input_opt : InputSource? = None
  let mut index = 0
  while index < args.length() {
    let arg = args[index]
    if arg == "-h" || arg == "--help" {
      return CliParseResult::Help
    }
    if arg == "-l" || arg == "--logs" {
      logs = true
      index = index + 1
      continue
    }
    if arg == "-f" || arg == "--file" {
      if index + 1 >= args.length() {
        return CliParseResult::Error("Missing path after --file")
      }
      if input_opt is Some(_) {
        return CliParseResult::Error("Multiple inputs provided")
      }
      input_opt = Some(InputSource::File(args[index + 1]))
      index = index + 2
      continue
    }
    if arg == "--" {
      index = index + 1
      break
    }
    if arg.has_prefix("-") {
      return CliParseResult::Error("Unknown option: \"" + arg + "\"")
    }
    break
  }
  if index >= args.length() {
    return CliParseResult::Error("Missing query")
  }
  let query = args[index]
  index = index + 1
  if index < args.length() {
    if input_opt is Some(_) {
      return CliParseResult::Error("Multiple inputs provided")
    }
    let inline = args[index]
    if inline == "-" {
      input_opt = Some(InputSource::Stdin)
    } else {
      input_opt = Some(InputSource::Inline(inline))
    }
    index = index + 1
  }
  if index < args.length() {
    return CliParseResult::Error("Too many arguments")
  }
  let input = match input_opt {
    Some(source) => source
    None => InputSource::Stdin
  }
  CliParseResult::Run({ query, input, logs })
}

///|
async fn read_input(source : InputSource) -> String raise {
  match source {
    Stdin => @stdio.stdin.read_all().text()
    File(path) => @fs.read_file_to_string(path)
    Inline(text) => text
  }
}

///|
fn run_query(query : String, input : String, logs : Bool) -> Iter[Json] raise {
  if logs {
    @moonjq.parse(query).eval_logs(input)
  } else {
    @moonjq.run(query, input).iter()
  }
}

///|
async fn write_results(results : Iter[Json]) -> Unit {
  let mut first = true
  for value in results {
    if first {
      first = false
    } else {
      @stdio.stdout.write("\n")
    }
    @stdio.stdout.write(value.to_string())
  }
  if !first {
    @stdio.stdout.write("\n")
  }
}

///|
async fn main {
  let args = @sys.get_cli_args()[1:]
  match parse_cli(args) {
    Help => {
      @stdio.stdout.write(help_message())
      return
    }
    Error(msg) => {
      @stdio.stderr.write("Error: " + msg + "\n")
      @stdio.stderr.write(help_message())
      @sys.exit(2)
    }
    Run(options) => {
      try {
        let input = read_input(options.input)
        let results = run_query(options.query, input, options.logs)
        write_results(results)
      } catch {
        err => {
          @stdio.stderr.write("Error: \{err}\n")
          @sys.exit(1)
        }
      }
    }
  }
}
