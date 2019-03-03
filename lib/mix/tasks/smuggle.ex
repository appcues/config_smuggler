defmodule Mix.Tasks.Smuggle do
  @moduledoc ~S"""
  ConfigSmuggler provides the `mix smuggle` task, which encodes
  `config.exs`-style files into JSON-formatted key/value pairs.

  Usage: `mix smuggle encode <filename.exs>`
  """
  use Mix.Task

  @impl true
  @shortdoc "Encodes a config.exs-style file into JSON keys and values"
  def run(["encode", filename]) do
    with {:ok, encoded_config_map} <- ConfigSmuggler.encode_file(filename) do
      IO.puts("{")

      encoded_config_map
      |> Enum.map(fn {k,v} -> "  #{inspect(k)}: #{inspect(v)}" end)
      |> Enum.join(",\n")
      |> IO.puts

      IO.puts("}")
    else
      {:error, reason} ->
        Mix.shell.error("Error: #{inspect(reason)}")
        System.halt(1)
    end
  end

  def run(_args) do
    Mix.shell.error("Usage: mix smuggle encode <filename.exs>")
    System.halt(1)
  end
end
