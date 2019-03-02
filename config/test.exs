use Mix.Config

## Used by the ConfigSmuggler.encode_file/1 test in
## test/config_smuggler_test.exs

config :config_smuggler, some_key: :some_value

config :config_smuggler, other_key: "other value"

config :config_smuggler, ConfigSmuggler,
  omg: :lol,
  timeout: 5000,
  kwlist: [yes: true, no: false]
