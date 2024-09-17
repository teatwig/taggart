defmodule Taggart.Mixfile do
  use Mix.Project

  @version "0.1.5"
  @source_url "https://github.com/ijcd/taggart"
  @description "Tag-based markup in Elixir. Supports standard HTML tags as well as custom tag definitions."

  def project do
    [
      app: :taggart,
      version: @version,
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript(),

      # docs
      description: @description,
      name: "Taggart",
      source_url: @source_url,
      package: package(),
      dialyzer: [flags: "--fullpath"],
      docs: [
        main: "readme",
        source_ref: "v#{@version}",
        source_url: @source_url,
        extras: [
          "README.md"
        ]
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_html, "~> 4.1"},
      {:phoenix_html_helpers, "~> 1.0"},

      # docs
      {:ex_doc, "~> 0.34.2", only: :dev, runtime: false},
      {:earmark, "~> 1.4", only: :dev, runtime: false},

      # converters
      {:floki, "~> 0.36", optional: true},

      # dev/test
      {:phoenix, "~> 1.7", only: [:dev, :test], runtime: false},
      {:phoenix_view, "~> 2.0", only: [:dev, :test], runtime: false},
      {:benchee, "~> 1.3.1", only: [:dev, :test], runtime: false},
      {:exprof, "~> 0.2.4", only: [:dev, :test], runtime: false},
      {:eflame,
       github: "ijcd/eflame", compile: "rebar3 compile", only: [:dev, :test], runtime: false},
      {:mix_test_watch, "~> 1.2", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:stream_data, "~> 1.1.1", only: [:dev, :test], runtime: false}
      # {:mex, "~> 0.0.6", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      description: @description,
      files: ["lib", "config", "mix.exs", "README*"],
      maintainers: ["Ian Duggan"],
      licenses: ["Apache 2.0"],
      links: %{GitHub: @source_url}
    ]
  end

  defp escript do
    [
      main_module: Taggart.CLI,
      embed_elixir: true
      # emu_args: "-noinput -ansi_enabled true"
    ]
  end
end
