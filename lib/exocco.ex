# **Exocco** is an Elixir port of [Docco](http://jashkenas.github.com/docco/):
# the original quick-and-dirty, hundred-line-long, literate-programming-style
# documentation generator. It produces HTML that displays your comments
# alongside your code. Comments are passed through
# [Markdown](http://daringfireball.net/projects/markdown/syntax) while code is
# passed through [Pygments](http://pygments.org/) for syntax highlighting.
# This page is the result of running Exocco against its own source file.
# 
# `exocco` is a self contained elixir script. You can run it from the command line as follow:
# 
#     exocco lib/foo.ex
# 
# ...or
#
#     exocco lib/
#
# This will generate linked HTML documentation for the named source files (or first level files
# in a directory), saving it into a folder.
# 
# To get more information about the available options, run:
#
#     exocco --help
#
# **Exocco** is available on [GitHub](https://github.com/bitchef/exocco).
# 
# To build Exocco:
#
#  Install [Elixir](http://elixir-lang.org/)...
#
#  grab the latest Exocco source...
# 
#     git clone git://github.com/bitchef/exocco.git
#
# and build the project:
#     cd exocco
#     mix deps.get
#     mix escript.build
#
# **Exocco** is released under the MIT License.
defmodule Exocco do
  require Resources

  # ### Structs & Macros

  #
  defmodule Section do
    defstruct docText: "", codeText: ""
    @type t :: %Section{docText: String.t, codeText: String.t}
  end

  # `Exocco.document/2` supported options.
  defmodule Document.Opts do
    defstruct output_dir: "docs/", preserve_paths: false, css: nil
    @type t :: %Document.Opts{output_dir: String.t, preserve_paths: boolean, css: String.t}
  end

  defmacrop mHighlightStart do
    quote do
      "<div class=\"highlight\"><pre>"
    end
  end
  defmacrop mHighlightEnd do
    quote do
      "</pre></div>"
    end
  end
  # **Pygments** command line interface.
  defmacrop mPygmentize do 
  quote do
    "pygmentize"
  end
  end
  # **Pygments** web service URL.
  defmacrop mPygmentizeUrl do
    quote do
      'http://pygments.appspot.com/'
    end
  end

  # Processing source files
  #-----------------------------

  # Generate HTML documentation for each file in  a list of source files.
  @spec document(fileList :: [String.t], opts :: [Keyword.t]) :: none
  def document(fileList, opts \\ []) 

  def document([], _opts), do: :ok
  def document(fileList, opts) when is_list(fileList) and is_list(opts) do
    opts = struct(Document.Opts, opts)
    ensure_directory(opts.output_dir)

    case opts.css do
      nil -> cssDest = Path.join(opts.output_dir, "exocco.css")
      :ok = File.write(cssDest, Resources.css)

      csspath ->  cssDest = Path.join(opts.output_dir, Path.basename csspath)
      :ok = File.cp(csspath, cssDest)
    end

    jquery = Path.join(opts.output_dir, "jquery.min.js")
    dropdownjs = Path.join(opts.output_dir, "dropdown.js")
    scripts = [jquery, dropdownjs]

    :ok = File.write(jquery, Resources.jquery)
    :ok = File.write(dropdownjs, Resources.dropdownjs)


    case fileList do
      [filename] -> document([filename], [], cssDest, scripts, opts.output_dir, opts.preserve_paths) 
      files -> jumps = build_nav_entries(files, opts.output_dir, opts.preserve_paths)
      document(files, jumps, cssDest, scripts, opts.output_dir, opts.preserve_paths) 
    end
  end #document

  defp document([], _jumps, _cssDest, _scripts, _output, _preservePaths), do: :ok
  defp document([file|next], jumps, cssDest, scripts, output, preservePaths) do
    outputFile = destination(file, output, preservePaths)
    dropdownLinks = case jumps do
      [] -> ""
      [_jump] -> ""
      jumpList -> Enum.map(jumpList, fn {filename, url} -> {filename, relative_to(url, outputFile)} end)
      |> render_nav_links
    end

    csspath = cond do
      preservePaths -> relative_to(cssDest, outputFile)
      true -> relative_to(cssDest, output)
    end
    
    scriptLinks = Enum.map(scripts, fn script -> relative_to(script, outputFile) end)
    |> render_js_scripts
    
    lang = Path.extname(file) |> Language.from_file_ext
    if lang do
      build_document(file, lang, outputFile, csspath, dropdownLinks, scriptLinks)
    else
      IO.puts "Error: could not determine language for: '#{file}'"
    end

    document(next, jumps, cssDest, scripts, output, preservePaths)
  end #document

  # Building HTML document
  #-----------------------

  #
  defp build_document(sourceFile, lang, dest, cssDest, dropdownLinks, scriptLinks) do
    ensure_directory(Path.dirname dest)
    lines = read_source(sourceFile)
    if lang.literate do
      lines = preprocess_literate(lines, lang)
    end
    sections = parse(lang, lines)
    processedSections = process_sections(lang, sections)
    html = Path.basename(sourceFile) |> render_template(cssDest, processedSections, dropdownLinks, scriptLinks)
    :ok = File.write(dest, html)
    IO.puts "exocco #{sourceFile} -> #{dest}"
  end #build_document

  # Parse lines of a source file into a list of sections. Each section will be of the form: 
  #     {"codeText": ..., 
  #      "docText":  ...,} 
  defp parse(lang, lines, sections \\ [], docText \\ [], codeText \\ [], multiLine \\ false, hasCode \\ false, nbLeadSpaces \\ 0) 

  defp parse(_lang, [], sections, docText, codeText, _multiLine, _hasCode, _nbLeadSpaces) do
    Enum.reverse save_section(sections, docText, codeText) 
  end
  defp parse(lang, [line|lines], sections, docText, codeText, multiLine, hasCode, nbLeadSpaces) do
    multiLineDelimiters = [lang.multistart, lang.multiend]
    cond do
      # Ignore the beginning line of executable scripts (i.e line containing shebang).
      String.starts_with?(line, "#!") ->
        parse(lang, lines, sections, docText, codeText, multiLine, hasCode, nbLeadSpaces) 

      has_multi_line_delim?(line, multiLineDelimiters) ->
        # Start multiline parsing if a start delimiter is detected.
        unless multiLine do
          multiLine = true
        end

        [leadSpaces] = Regex.run(~r/\s*/, line) 
        nbLeadSpaces = String.length(leadSpaces)

        line = String.strip(line)

        # Stop multiline parsing when an end delimiter is detected.
        if multiLine 
        && String.ends_with?(line, lang.multiend)
        && String.length(line) >= String.length(lang.multiend) do
          multiLine = false
        end

        # Remove single line comment delimiters from comment blocks so they do not appear in the final docs.
        line = String.replace(line, lang.multistart, "")
                |> String.replace(lang.multiend, "")
                |> String.strip

        if String.length(line) > 0 do
          docText = [line | docText]
        end

        if !multiLine && ! Enum.empty?(docText) do
          sections = save_section(sections, docText, codeText)
          docText = codeText = []
        end
        parse(lang, lines, sections, docText, codeText, multiLine, hasCode, nbLeadSpaces) 

        # Parse comment block between multiline delimiters.
        multiLine -> 
        line = Regex.compile!("\s{#{nbLeadSpaces}}")
                |> Regex.replace(line, "", global: false)
                |> String.rstrip
        docText = [line | docText]
        parse(lang, lines, sections, docText, codeText, multiLine, hasCode, nbLeadSpaces) 

        # Parse single line comments.
      Regex.match?(lang.commentMatcher, String.lstrip(line)) ->
        if hasCode do
          sections = save_section(sections, docText, codeText)
          hasCode = false
          docText = codeText = []
        end
        line = Regex.replace(lang.commentMatcher, String.lstrip(line), "") 
                |> String.rstrip
        docText = [line | docText]
        parse(lang, lines, sections, docText, codeText, multiLine, hasCode, nbLeadSpaces) 

        # Consider everything else as code.
        true ->  hasCode = true
        codeText = [ String.rstrip(line) | codeText ] 
        parse(lang, lines, sections, docText, codeText, multiLine, hasCode, nbLeadSpaces) 
    end
  end #parse

  # Processing sections
  #---------------------------------


  # Highlight code and convert markdown text to html.
  defp process_sections(lang, sections) do
    markdownTask = Task.async(fn -> Enum.map(sections, fn section -> markdown(section.docText) end) end)

    code = for section <- sections, into: "", do: section.codeText <> lang.dividerText  
    pygmentTask = Task.async(fn -> pygmentize(lang, code) end)

    docSections = Task.await(markdownTask)

    codeHtml = Task.await(pygmentTask)
                |> String.replace(mHighlightStart, "")
                |> String.replace(mHighlightEnd, "")
    codeFragments = Regex.split(lang.dividerHtml, codeHtml)
                    |> Enum.map(fn codeFragment -> 
                    cond do
                      String.length(codeFragment) > 0 -> mHighlightStart <> codeFragment <> mHighlightEnd 
                      true -> ""
                    end
                    end)

    List.zip([docSections, codeFragments])
  end #process_sections

  # Helper functions
  #--------

  #  
  defp read_source(source) do
    {:ok, content} = File.read(source)
    String.split(content, ~r/\n/)
  end #read_source

  defp has_multi_line_delim?(line, multiLineDelimiters) do
    Enum.all?(multiLineDelimiters) && Enum.any?(for delim <- multiLineDelimiters, do: String.starts_with?(String.lstrip(line), delim) || String.ends_with?(String.rstrip(line), delim))
  end #has_multi_line_delim?

  defp render_template(title, cssPath, processedSections, dropdownLinks, scriptLinks) do
    header = String.replace(Resources.htmlHeader, "{{title}}", title)
              |> String.replace("{{css}}", cssPath)
              |> String.replace("{{navigation}}", dropdownLinks)

    body = Enum.with_index(processedSections) |> List.foldl("", fn({{docHtml, codeHtml}, index}, acc) -> 
    template = String.replace(Resources.htmlBody, "{{index}}", to_string(index))
                |> String.replace("{{docs}}", docHtml)
                |> String.replace("{{code}}", codeHtml)
    acc <> template
    end)

    footer = String.replace(Resources.htmlFooter, "{{scripts}}", scriptLinks)

    header <> body <> footer
  end #render_template

  defp save_section(sections, docs, code) do
    docs = Enum.reverse(docs) |> Enum.join("\n")
    code = Enum.reverse(code) |> Enum.join("\n")
    [ %Section{docText: docs, codeText: code }| sections ]
  end #save_section

  # Creates a directory if it doesn't already exist.
  defp ensure_directory(dir), do: File.mkdir_p! dir

  # Remove special characters from a string to make it URL and filename safe.
  defp sanitize_filename(string), do: Regex.replace(~r/[^a-z0-9]/, String.downcase(string), "_")

  defp sanitize_dirpath(string) do
    Path.split(string) 
    |> Enum.filter(fn x ->  ! Enum.member?([".", ".."], x) end)
    |> Path.join
  end

  # Build the documentation file name from the output directory path and the source file name.
  #
  # Example: the documentation of `lib/example.ex` will be in `docs/example.ex.html`
  defp destination(filepath, output, preservePaths) do
    filename = Path.basename(filepath)
                |> Path.rootname
                |> sanitize_filename
    if preservePaths do
      filename = Path.dirname(filepath)
                  |> sanitize_dirpath
                  |> Path.join(filename)
    end
    extension = Path.extname(filepath)
    Path.join(output, "#{filename}#{extension}.html")
  end #destination


  # Build list of dropdown menu entries.
  defp build_nav_entries(fileList, output, preservePaths,  acc \\ [])

  defp build_nav_entries([], _output, _preservePaths, acc), do: List.keysort(acc, 0)
  defp build_nav_entries([filename|fileList], output, preservePaths, acc) do
    basename = Path.basename filename
    url = destination(filename, output, preservePaths)
    build_nav_entries(fileList, output, preservePaths, [{basename, url}| acc])
  end #build_nav_entries

  # Render the dropdown menu entries.
  defp render_nav_links(links, acc \\ [])

  defp render_nav_links([], acc) do
    Resources.htmlJumpBegin <> Enum.join(Enum.reverse(acc)) <> Resources.htmlJumpEnd
  end
  defp render_nav_links([{filename, url}|next], acc) do
    jumpEntry = String.replace(Resources.htmlJumpLink, "{{url}}", url)
                |> String.replace("{{filename}}", filename)
    render_nav_links(next, [jumpEntry | acc])
  end #render_nav_links
  
  defp render_js_scripts(fileList, acc \\ [])

  defp render_js_scripts([], acc), do: Enum.reverse(acc) |> Enum.join
  defp render_js_scripts([path|next], acc) do
    jsLink = String.replace(Resources.jsLink, "{{js}}", path)
    render_js_scripts(next, [jsLink | acc])
  end

  # If at least two files are processes simultaneously, they will keep a reference to each other in a navigation menu.
  # This reference is a relative path from `file A` to `file B` taking `file A`'s parent directory as the starting point.
  #
  # For example to access the file `docs/exocco.css`, `docs/lib/priv/file.html` will have the relative path `./../../exocco.css`.
  #
  # The function `relative_to` will dynamically determine the correct references for each submitted file.
  defp relative_to(filepath, fromfile) do
    dir = Path.dirname(filepath) |> Path.split 
    cwd = Path.dirname(fromfile) |> Path.split
    filename = Path.basename filepath
    relative_to(dir, cwd, []) |> Path.join(filename)
  end #relative_to
  defp relative_to([], [], acc), do: Enum.reverse(acc) |> Path.join
  defp relative_to([], [_last], acc), do: relative_to([], [], [".." | acc])
  defp relative_to([], [_first|rest], acc), do: relative_to([], rest, [".." | acc])
  defp relative_to([head], [], acc), do: relative_to([], [], [head | acc])
  defp relative_to([head], [_last], acc), do: relative_to([head], [], [".." | acc])
  defp relative_to([head], [head|rest], acc), do: relative_to([], rest, ["." | acc])
  defp relative_to([head], [_first|rest], acc), do: relative_to([head], rest, [".." | acc])
  defp relative_to([head|next], [], acc), do: relative_to(next, [], [head | acc])
  defp relative_to([head|next], [head], acc), do: relative_to(next, [], ["." | acc])
  defp relative_to([head|next], [_last], acc), do: relative_to([head|next], [], [".." | acc])
  defp relative_to([head|next], [head|rest], acc), do: relative_to(next, rest, ["." | acc])
  defp relative_to([head|next], [_first|_rest], _acc), do: Path.join([head|next])

  # Invert the comment and code relationship on a per-line basis for files written in literate
  # programming style.
  defp preprocess_literate(lines, lang, isText \\ false, maybeCode \\ true, acc \\ [])

  defp preprocess_literate([], _lang, _isText, _maybeCode, acc), do: Enum.reverse(acc)
  defp preprocess_literate([line|next], lang, isText, maybeCode, acc) do
  match = Regex.run(~r/^([  ]{4}|[  ]{1,3}\t)/, line)
  cond do
    maybeCode && match ->
      isText = false
      nbLeadSpaces = List.first(match) |> String.length 
      line = Regex.compile!("\s{#{nbLeadSpaces}}") |> Regex.replace(line, "", global: false)
      preprocess_literate(next, lang, isText, maybeCode, [line | acc])

        Regex.match?(~r/^\s*$/, line) ->
          maybeCode = true
          cond do
            isText -> preprocess_literate(next, lang, isText, maybeCode, [lang.symbol | acc])
            true -> preprocess_literate(next, lang, isText, maybeCode, ["" | acc])
          end

          true -> isText = true
          maybeCode = false
          line = "#{lang.symbol} #{line}"
          preprocess_literate(next, lang, isText, maybeCode, [line | acc])
      end
  end #preprocess_literate

  # Convert markdown text to html.
  defp markdown(text), do: to_char_list(text) |> :markdown.conv |> to_string

  # Test if Pygments is installed locally.
  defp has_pygmentize?(), do: System.find_executable(mPygmentize)

  # Use **Pygments** to highlight the source code.
  defp pygmentize(lang, code) do
    if has_pygmentize? do
      pygmentize_local(lang, code)
    else
      IO.puts "Warning: Pygments not installed. Using webservice."
      pygmentize_web(lang, code)
    end
  end #pygmentize

  # Use the local **Pygments** command line tool to highlight the code.
  defp pygmentize_local(lang, code) do
    tmpFile = new_tmp_file
    :ok = File.write(tmpFile, code)
    codeHighlighted = :os.cmd(String.to_char_list "#{mPygmentize} -l #{lang.name} -O bg=dark,encoding=utf-8 -f html #{tmpFile}")
    :ok = File.rm tmpFile
    to_string codeHighlighted
  end #pygmentize_local

  defp new_tmp_file do
    {mgSecs, secs, micSecs}= :erlang.now
    filename = "tmpExocco#{mgSecs}#{secs}#{micSecs}"
    Path.join(System.tmp_dir, filename)
  end #new_tmp_file

  # Send the code to highlight to **Pygments** webservice.
  defp pygmentize_web(lang, code) do
    :inets.start()
    case resolve_proxy do
      {host, port} -> :httpc.set_options([{:proxy, {{host, port}, [] }}])
      _ -> :ok
    end
    request_body = URI.encode_query(%{"lang" => lang.name, "code" => code})
    {:ok, {_statusLine, _headers, body}} = :httpc.request(:post, {mPygmentizeUrl, [], 'application/x-www-form-urlencoded', request_body}, [], [])
    :inets.stop()
    to_string body
  end #pygmentize_web

  defp resolve_proxy do
    proxy = System.get_env("http_proxy") 
    cond do
      proxy -> 
      case Regex.split(~r/\/\/|:|@/, proxy) do
        [ _, _, host] -> {String.to_char_list(host), 80 }
        [ _, _, host, port] -> {String.to_char_list(host), String.to_integer(port) }
        [ _, _, _, _, host] -> {String.to_char_list(host), 80 }
        [ _, _, _, _, host, port] -> {String.to_char_list(host), String.to_integer(port) }
      end

      true -> nil
    end
  end #resolve_proxy
end #defmodule Exocco
