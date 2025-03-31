defmodule ConfigSmuggler.MixProject do
  use Mix.Project

  @github_repo "https://github.com/appcues/config_smuggler"

  def project do
    [
      app: :config_smuggler,
      version: "1.1.0",
      description:
        "ConfigSmuggler converts Elixir-style configuration statements to and from string-encoded key/value pairs.",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      dialyzer: [plt_add_apps: [:mix]],
      aliases: [docs: "docs --source-url #{@github_repo}"]
    ]
  end

  def package do
    [
      licenses: ["MIT"],
      maintainers: ["Appcues <dev@appcues.com>"],
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
      {:dialyxir, "~> 1.1", only: :dev, runtime: false},
      {:ex_doc, "~> 0.26", only: :dev, runtime: false}
    ]
  end
end
