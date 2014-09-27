ExUnit.start

defmodule PathHelpers do
  def fixture_path do
    "tmp"
  end

  def fixture_path(extra) do
    Path.join fixture_path, extra
  end
end

defmodule DirHelpers do
  def setupDirTree(basePath) do
    try do
      File.mkdir_p! Path.join( basePath, "dir1" )
      File.mkdir_p! Path.join( basePath, "dir2" )
      File.mkdir_p! Path.join( basePath, "dir2/subdir1" )
      File.touch! Path.join( basePath, "file1.ex" )
      File.touch! Path.join( basePath, "file2.ex" )
      File.touch! Path.join( basePath, "dir2/file3.ex" )
      File.touch! Path.join( basePath, "dir2/file4.ex" )
      File.touch! Path.join( basePath, "dir2/subdir1/file5.ex" )
      :ok
    rescue
      _ -> deleteDirTree basePath
      :error
    end
  end

  def deleteDirTree(basePath) do
    if File.exists? basePath do
      File.rm_rf basePath
      File.rmdir basePath
    end
    :ok
  end
end
