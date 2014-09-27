defmodule LanguageTest do
  use ExUnit.Case

  import :hamcrest, only: [ assert_that: 2 ]
  import :hamcrest_matchers

  test "Language.from_file_ext/1 returns nil for an unknown file extension" do
    result = Language.from_file_ext(".dummy")
    
    assert_that  result, is nil
  end
  test "Language.from_file_ext/1 gets a Language map for a known file extension" do
    result = Language.from_file_ext(".ex")
    
    expected = %Language{name: "elixir", symbol: "#", dividerText: "\n#DIVIDER\n",
          commentMatcher: Regex.compile!("^\s*#+\s?"),
          dividerHtml: Regex.compile!("\n*<span class=\"c1?\">#DIVIDER</span>\n*")}

    assert_that result, is expected
  end
end
