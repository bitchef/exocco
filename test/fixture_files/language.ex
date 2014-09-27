defmodule Language do

  defstruct name: "", symbol: "", literate: false, multistart: nil, multiend: nil,
  commentMatcher: nil, dividerText: nil, dividerHtml: nil 

  @type t :: %Language{ name: String.t, symbol: String.t, literate: boolean,
    multistart: String.t, multiend: String.t, commentMatcher: Regex.t,
    dividerText: String.t, dividerHtml: Regex.t}

  # List of languages supported by Exocco.
  #
  # To support a new language,  
  # map a file extension to the name of its Pygments lexer following the same syntax.
  # Then rebuild the project.
  defmacrop mLanguages do
    quote do
      languages = [
        ".applescript": %Language{name: "applescript", symbol: "--"},
        ".as":          %Language{name: "actionscript", symbol: "//"},
        ".bat":         %Language{name: "dos", symbol: "@?rem"},
        ".btm":         %Language{name: "dos", symbol: "@?rem"},
        ".c":           %Language{name: "c", symbol: "//", multistart: "/*", multiend: "*/"},
        ".clj":         %Language{name: "clojure", symbol: ";"},
        ".cls":         %Language{name: "tex", symbol: "%"},
        ".cmake":       %Language{name: "cmake", symbol: "#"},
        ".cmd":         %Language{name: "dos", symbol: "@?rem"},
        ".coffee":      %Language{name: "coffeescript", symbol: "#"},
        ".cpp":         %Language{name: "cpp", symbol: "//", multistart: "/*", multiend: "*/"},
        ".cs":          %Language{name: "cs", symbol: "//"},
        ".cson":        %Language{name: "coffeescript", symbol: "#"},
        ".d":           %Language{name: "d", symbol: "//"},
        ".dtx":         %Language{name: "tex", symbol: "%"},
        ".erl":         %Language{name: "erlang", symbol: "%"},
        ".eex":         %Language{name: "elixir", symbol: "#"},
        ".ex":          %Language{name: "elixir", symbol: "#"},
        ".exs":         %Language{name: "elixir", symbol: "#"},
        ".frag":        %Language{name: "glsl", symbol: "//"},
        ".glsl":        %Language{name: "glsl", symbol: "//"},
        ".go":          %Language{name: "go", symbol: "//"},
        ".groovy":      %Language{name: "groovy", symbol: "//"},
        ".h":           %Language{name: "c", symbol: "//", multistart: "/*", multiend: "*/"},
        ".hrl":         %Language{name: "erlang", symbol: "%"},
        ".hs":          %Language{name: "haskell", symbol: "--", multistart: "{-", multiend: "-}"},
        ".ini":         %Language{name: "ini", symbol: ";"},
        ".js":          %Language{name: "javascript", symbol: "//", multistart: "/*", multiend: "*/"},
        ".java":        %Language{name: "java", symbol: "//", multistart: "/*", multiend: "*/"},
        ".latex":       %Language{name: "tex", symbol: "%"},
        ".less":        %Language{name: "less", symbol: "//"},
        ".lisp":        %Language{name: "lisp", symbol: ";"},
        ".litcoffee":   %Language{name: "coffeescript", symbol: "#", literate: true},
        ".ls":          %Language{name: "coffeescript", symbol: "#"},
        ".lua":         %Language{name: "lua", symbol: "--", multistart: "--[[", multiend: "]]--"},
        ".n":           %Language{name: "nemerle", symbol: "//"},
        ".m":           %Language{name: "objectivec", symbol: "//"},
        ".mel":         %Language{name: "mel", symbol: "//"},
        ".markdown":    %Language{name: "markdown"},
        ".md":          %Language{name: "markdown"},
        ".mm":          %Language{name: "objectivec", symbol: "//"},
        ".p":           %Language{name: "delphi", symbol: "//"},
        ".pas":         %Language{name: "delphi", symbol: "//"},
        ".php":         %Language{name: "php", symbol: "//"},
        ".pl":          %Language{name: "perl", symbol: "#"},
        ".pm":          %Language{name: "perl", symbol: "#"},
        ".pod":         %Language{name: "perl", symbol: "#"},
        ".pp":          %Language{name: "delphi", symbol: "//"},
        ".py":          %Language{name: "python", symbol: "#"},
        ".rb":          %Language{name: "ruby", symbol: "#", multistart: "=begin", multiend: "=end"},
        ".tex":         %Language{name: "tex", symbol: "%"},
        ".scala":       %Language{name: "scala", symbol: "//"},
        ".scm":         %Language{name: "scheme", symbol: ";;", multistart: "#|", multiend: "|#"},
        ".scpt":        %Language{name: "applescript", symbol: "--"},
        ".scss":        %Language{name: "scss", symbol: "//"},
        ".sh":          %Language{name: "bash", symbol: "#"},
        ".sql":         %Language{name: "sql", symbol: "--"},
        ".sty":         %Language{name: "tex", symbol: "%"},
        ".t":           %Language{name: "perl", symbol: "#"},
        ".vala":        %Language{name: "vala", symbol: "//"},
        ".vapi":        %Language{name: "vala", symbol: "//"},
        ".vbe":         %Language{name: "vbscript", symbol: "'"},
        ".vbs":         %Language{name: "vbscript", symbol: "'"},
        ".vert":        %Language{name: "glsl", symbol: "//"},
        ".vhdl":        %Language{name: "vhdl", symbol: "--"},
        ".r":           %Language{name: "r", symbol: "#"},
        ".rc":          %Language{name: "rust", symbol: "//"},
        ".rs":          %Language{name: "rust", symbol: "//"},
        ".wsc":         %Language{name: "vbscript", symbol: "'"},
        ".wsf":         %Language{name: "vbscript", symbol: "'"}
      ]

    # Build out the appropriate matchers and delimiters for each language.
    for { ext,lang } <- languages, do: { ext,  %Language{ lang|
        # Regex to test if a line starts with a comment symbol.
        commentMatcher: Regex.compile!("^\s*#{lang.symbol}+\s?" ),
        # The dividing token we feed into Pygments, to delimit the boundaries between
        # sections.
        dividerText: "\n#{lang.symbol}DIVIDER\n",
        # The mirror of `dividerText` that we expect Pygments to return. We can split
        # on this to recover the original sections.
        dividerHtml: Regex.compile!("\n*<span class=\"c1?\">#{lang.symbol}DIVIDER</span>\n*"),
      } }
  end 
end #defmacrop

# Get language specifications from a file extension.
@spec from_file_ext(fileExtension :: String.t) :: %Language{} | nil

def from_file_ext(fileExtension) do
  extension = String.downcase(fileExtension) |> String.to_atom
  mLanguages[extension]
end #from_file_ext
end #defmodule Language
