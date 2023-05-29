defmodule ConfigSmuggler.MixProject do
  use Mix.Project

  @github_repo "https://github.com/appcues/config_smuggler"

  def project do
    [
      app: :config_smuggler,
      version: "0.8.7",
      description:
        "ConfigSmuggler converts Elixir-style configuration statements to and from string-encoded key/value pairs.",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      dialyzer: [plt_add_apps: [:mix, :jason, :poison]],
      aliases: [docs: "docs --source-url #{@github_repo}"]
    ]
  end

  def package do
    [
      licenses: ["MIT"],
      maintainers: ["pete gamache <pete@appcues.com>"],
      links: %{github: @github_repo}
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.0", optional: true},
      {:poison, "~> 5.0", optional: true},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false},
      {:ex_doc, "~> 0.26", only: :dev, runtime: false}
    ]
  end
end
