defmodule Cldr.Calendar.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :ex_cldr_calendars,
      version: @version,
      elixir: "~> 1.5",
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      name: "Cldr Calendars",
      source_url: "https://github.com/kipcole9/cldr_calendars",
      docs: docs(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env()),
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore_warnings",
        plt_add_apps: ~w(gettext inets jason mix plug)a
      ],
      compilers: Mix.compilers()
    ]
  end

  defp description do
    """
    Common Locale Data Repository (CLDR) calendar functions
    """
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      maintainers: ["Kip Cole"],
      licenses: ["Apache 2.0"],
      links: links(),
      files: [
        "lib",
        "config",
        "mix.exs",
        "README*",
        "CHANGELOG*",
        "FEATURE*",
        "LICENSE*"
      ]
    ]
  end

  defp deps do
    [
      # {:ex_cldr, "~> 2.4"},
      {:ex_cldr, path: "../cldr", override: true},
      {:jason, "~> 1.0"},
      {:ex_cldr_print, "~> 0.1", runtime: false, only: :dev},
      {:benchee, "~> 0.14", only: [:dev, :test]}
    ]
  end

  def links do
    %{
      "GitHub" => "https://github.com/kipcole9/cldr_calendars",
      "Readme" => "https://github.com/kipcole9/cldr_calendars/blob/v#{@version}/README.md",
      "Changelog" => "https://github.com/kipcole9/cldr_calendars/blob/v#{@version}/CHANGELOG.md"
    }
  end

  def docs do
    [
      source_ref: "v#{@version}",
      main: "readme",
      logo: "logo.png",
      extras: [
        "README.md",
        "LICENSE.md",
        "CHANGELOG.md"
      ],
      skip_undefined_reference_warnings_on: ["changelog"]
    ]
  end

  def aliases do
    []
  end

  defp elixirc_paths(:test), do: ["lib", "mix", "src", "test"]
  defp elixirc_paths(:dev), do: ["lib", "mix", "src", "bench"]
  defp elixirc_paths(_), do: ["lib", "src"]
end
