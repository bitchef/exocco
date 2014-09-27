Code.ensure_loaded?(Hex) and Hex.start

defmodule Exocco.Mixfile do
  use Mix.Project

  def project do
    [ app: :exocco,
      version: "0.1.0",
      elixir: "~> 1.0.0",
      deps: deps(Mix.env),
      escript: escript ]
  end

  # Configuration for the OTP application
  def application do
    [ ]
  end

  def escript do
    [main_module: ExoccoMain]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, git: "https://github.com/elixir-lang/foobar.git", tag: "0.1" }
  #
  # To specify particular versions, regardless of the tag, do:
  # { :barbat, "~> 0.1", github: "elixir-lang/barbat" }
  defp deps(:prod) do
    [
      { :markdown, "~>0.1", branch: "next", github: "erlware/erlmarkdown", compile: "make compile" }
    ]
  end
  defp deps(:test) do
    deps(:prod) ++ [
      { :hamcrest, "~>0.1", github: "hyperthunk/hamcrest-erlang" },
    ]
  end
  defp deps(_), do: deps(:prod)
end
