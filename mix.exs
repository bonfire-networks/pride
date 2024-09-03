defmodule Pride.MixProject do
  use Mix.Project

  def project do
    [
      app: :pride,
      version: "0.0.1",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      description: "Provides a prefixed UUIDv7 data type for Ecto, and related helpers",
      homepage_url: "https://github.com/bonfire-networks/pride",
      source_url: "https://github.com/bonfire-networks/pride",
      package: [
        licenses: ["MIT"],
        links: %{
          "Repository" => "https://github.com/bonfire-networks/pride",
          "Hexdocs" => "https://hexdocs.pm/pride"
        }
      ],
      docs: [
        # The first page to display from the docs
        main: "readme",
        # extra pages to include
        extras: ["README.md"]
      ],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  defp deps do
    [
      {:untangle, "~> 0.3"},
      # for UUID support
      {:uniq, "~> 0.6"},
      {:ecto, "~> 3.12"},
      # you might just want it for in-memory use
      {:ecto_sql, "~> 3.8", optional: true},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false}
    ]
  end
end
