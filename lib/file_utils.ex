defmodule FileUtils do

  # List files at the first level of a directory (or a list of directories).
  @spec list_files(path :: String.t | [String.t]) :: [String.t]

  def list_files(path) when is_bitstring(path), do: list_files([path])
  def list_files(pathList) when is_list(pathList), do: list_files(pathList, []) |> remove_dirs 

  defp list_files([], acc), do: Enum.sort acc
  defp list_files([path|next], acc) do
      cond do
        is_dir(path) ->  {:ok, files}  = File.ls(path)
        # Filter out hidden files and prepend filenames with their relative path.
        files = Enum.filter(files, fn filename -> !String.starts_with?(filename, ".") end)
                |> Enum.map(fn filename ->  Path.join(path, filename) end)
        list_files(next, acc ++ files)
        is_file(path) -> list_files(next, [path | acc])
        true -> list_files(next, acc)
      end
  end #list_files


  # Recursively list files in a directory and its subdirectories.
  @spec list_files_r(path :: String.t | [String.t]) :: [String.t]

  def list_files_r(path) when is_bitstring(path), do: list_files_r([path])
  def list_files_r(pathList) when is_list(pathList), do: list_files_r(pathList, []) |> remove_dirs 

  defp list_files_r([], acc), do: Enum.sort acc
  defp list_files_r([path|next], acc) do
    cond do
      is_dir(path) -> files = list_files([path], [])
      list_files_r(next ++ files , acc)
      is_file(path) -> list_files_r(next, [path | acc])
      true ->  list_files_r(next, acc)
    end
  end #list_files_r

  # Helper functions
  #-----------------------

  # 
  def is_file(filepath), do: File.regular?(filepath)
  def is_dir(path), do: File.dir?(path)
  defp remove_dirs(pathList), do: Enum.filter(pathList, fn path -> is_file(path) end)
end #defmodule FileUtils
