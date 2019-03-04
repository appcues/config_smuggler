defmodule ConfigSmuggler.MixProject do
  use Mix.Project

  @github_repo "https://github.com/appcues/config_smuggler"

  def project do
    [
      app: :config_smuggler,
      version: "0.7.1",
      description:
        "ConfigSmuggler converts Elixir-style configuration statements to and from string-encoded key/value pairs.",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      dialyzer: [plt_add_apps: [:mix, :jason, :poison]],
      aliases: [docs: "docs --source-url #{@github_repo}"],
    ]
  end

  def package do
    [
      licenses: ["MIT"],
      maintainers: ["pete gamache <pete@appcues.com>"],
      links: %{github: @github_repo},
    ]
  end

  def application do
    [
      extra_applications: [:logger],
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.0", optional: true},
      {:poison, "~> 1.5 or ~> 2.0 or ~> 3.0", optional: true},
      {:freedom_formatter, "~> 1.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0.0-rc.4", only: :dev, runtime: false},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
    ]
  end
end
