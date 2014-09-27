defmodule ExoccoTest do
  use ExUnit.Case

  import DirHelpers
  import :hamcrest, only: [ assert_that: 2 ]
  import :hamcrest_matchers

  setup_all do
    on_exit fn -> deleteDirTree("test/tmp") end
    :ok
  end

  test "Exocco.document/1 does not document an empty list of files" do
    assert_that Exocco.document([]), is :ok
  end
  test "Exocco.document/2 documents a file" do
    Exocco.document(["test/fixture_files/exocco.ex"], [ output_dir: "test/tmp" ])
    { :ok, result } = File.read( "test/tmp/exocco.ex.html") 
    { :ok, expected } = File.read( "test/fixture_files/exocco.ex.html" )

    assert_that result, is expected
  end
  test "Exocco.document/2 documents a list of files" do
    Exocco.document(["test/fixture_files/exocco.ex", "test/fixture_files/file_utils.ex"], [ output_dir: "test/tmp" ])
    { :ok, result } = File.read( "test/tmp/file_utils.ex.html" )
    { :ok, expected } = File.read( "test/fixture_files/file_utils.ex.html" )

    assert_that result, is expected
  end
  test "Exocco.document/2 documents a list of files and preserves filepaths" do
    Exocco.document(["test/fixture_files/exocco.ex", "test/fixture_files/language.ex"], [ output_dir: "test/tmp", preserve_paths: true ])
    { :ok, result } = File.read( "test/tmp/test/fixture_files/language.ex.html" )
    { :ok, expected } = File.read( "test/fixture_files/language.ex.html" )

    assert_that result, is expected
  end
end
