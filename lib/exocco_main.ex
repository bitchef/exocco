defmodule ExoccoMain do
  defmacrop mOptions do
    quote do 
    [
      switches: [ help: :boolean, css: :string, output: :string, preserve_paths: :boolean, recursive: :boolean ],
      aliases: [ h: :help, c: :css, o: :output, p: :preserve_paths, r: :recursive ]
    ]
    end
  end #defmacrop mOptions

  def main(args) do
    case parse_cmdline args do
      {:exit, reason} -> exit_prog(reason)
      {:ok, {files, opts}} -> Exocco.document(files, opts)
    end
  end #main

  # Helper functions
  #--------

  #
  defp parse_cmdline(args) do 
  case OptionParser.parse(args, mOptions) do
    {[help: true], _arguments, _invalidOptions} -> {:exit, {help_msg, 0}}
    {_options, [], []} -> msg = "exocco: Please, tell me which file(s) to process!\nTry 'exocco --help' for more information."
    {:exit, {msg, 1}}
    {_options, _arguments, [opt|_invalidOptions]} -> [option] =  Keyword.keys([opt]) 
    msg = "exocco: invalid option -- '#{option}'\nTry 'exocco --help' for more information."
    {:exit, {msg, 2}}
    {options, arguments, []} -> {:ok, get_params(options, arguments)}
  end
  end #parse_cmd_line
  
  # Get parameters for Exocco.document/2 from command line arguments.
  defp get_params(options, arguments) do
    opts = Keyword.new 

    if is_bitstring(options[:css]) do 
    if FileUtils.is_file(options[:css]) do
      opts = Keyword.put(opts, :css, options[:css])
    else
      if String.length(options[:css]) > 0 do
        IO.puts "Warning: could not find file named '#{options[:css]}'. Using default stylesheet."
      end
    end
    end

    if is_bitstring(options[:output]) do
      opts = Keyword.put(opts, :output_dir, options[:output] <> "/")
    end

    if options[:preserve_paths] do
      opts = Keyword.put(opts, :preserve_paths, true)
    end

    files = cond do
      options[:recursive] -> FileUtils.list_files_r(arguments)
      true -> FileUtils.list_files(arguments)
    end 
    |> Enum.uniq

    {files, opts} 
  end #get_params

  defp exit_prog({message, exitStatus}) do
    IO.puts(message)
    System.halt(exitStatus)
  end #exit_prog

  defp help_msg() do
    usage_msg <>  """
    Generate a linked HTML documentation page for each of the named source files
    (or files in the named directory), saving it into a 'docs' folder by default.
    """
  end #help_msg

  defp usage_msg() do
    """
    Usage: exocco [-h] [-c <file>] [-o <path>] [-p] [-r] FILE... DIR...

      -h, --help                display this help and exit
      -c, --css                 use a custom css file
      -o, --output              output to a given folder [default: 'docs/']
      -p, --preserve-paths      preserve path structure of original files
      -r, --recursive           apply command recursively to files in
                                directories and subdirectories

      FILE                      FILE(s) to process
      DIR                       DIR(s) to process

    """
  end #usage_msg
end #defmodule ExoccoMain
