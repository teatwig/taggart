import Config

if config_env() == :dev do
  config :mix_test_watch,
    tasks: [
      "test",
      # "dialyzer",
      # "credo",
    ]
end
