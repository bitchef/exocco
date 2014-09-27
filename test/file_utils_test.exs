defmodule FileUtilsTest do
  use ExUnit.Case, async: true

  import DirHelpers
  import PathHelpers
  import :hamcrest, only: [ assert_that: 2 ]
  import :hamcrest_matchers

  setup_all do
    :ok = setupDirTree(fixture_path)
    on_exit fn -> deleteDirTree(fixture_path) end
    :ok
  end

  test "FileUtils.list_files/1 returns an empty list if given a non-existant file or directory name" do
    result = FileUtils.list_files( "dummy" )
    
    assert_that  result, is []
  end
  test "FileUtils.list_files/1 returns an empty list if given the name of an empty directory" do
    result = FileUtils.list_files( fixture_path("dir1") )
    
    assert_that  result, is []
  end
  test "FileUtils.list_files/1 returns back the filename for a given file" do
    result = FileUtils.list_files( fixture_path("file1.ex") )

    assert_that  result, is [fixture_path("file1.ex")]
  end
  test "FileUtils.list_files/1 returns a list of files contained in a given directory" do
    result = FileUtils.list_files( fixture_path )

    assert_that  result , has_length 2 
    assert_that  result, contains_member fixture_path("file1.ex") 
    assert_that  result, contains_member fixture_path("file2.ex") 
  end

  test "FileUtils.list_files_r/1 returns an empty list if given a non-existant file or directory name" do
    result = FileUtils.list_files_r( ["dummy"] )
    
    assert_that  result, is []
  end
  test "FileUtils.list_files_r/1 returns an empty list if given the name of an empty directory" do
    result = FileUtils.list_files_r( fixture_path("dir1") )
    
    assert_that  result, is []
  end
  test "FileUtils.list_files_r/1 returns back the filename of a given file" do
    result = FileUtils.list_files_r( fixture_path("file1.ex") )

    assert_that  result, is [fixture_path("file1.ex")]
  end
  test "FileUtils.list_files_r/1 returns a list of files contained in a given directory and its subdirectories" do
    result = FileUtils.list_files_r( fixture_path )

    assert_that  result , has_length 5 
    assert_that  result, contains_member fixture_path("file1.ex") 
    assert_that  result, contains_member fixture_path("file2.ex") 
    assert_that  result, contains_member fixture_path("dir2/file3.ex") 
    assert_that  result, contains_member fixture_path("dir2/file4.ex") 
    assert_that  result, contains_member fixture_path("dir2/subdir1/file5.ex") 
  end
end
