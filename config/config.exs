use Mix.Config

config :lurcher,
  bot_token:            {:system, "BOT_TOKEN"},
  gateway_host:         {:system, "GATEWAY_HOST"},
  shards_total:         {:system, :integer, "SHARDS_TOTAL"},
  shard_to_use:         {:system, :integer, "SHARD_TO_USE"},
  large_threshold:      {:system, :integer, "LARGE_THRESHOLD", 100},
  playing_status:       {:system, "PLAYING_STATUS", "[REDACTED]"},
  amqp_path:            {:system, "AMQP_PATH", "amqp://guest:guest@localhost"},
  amqp_exchange:        {:system, "AMQP_EXCHANGE", "topic"},
  amqp_queue_producing: {:system, "AMQP_QUEUE_PRODUCING", "raw"},
  amqp_key_producing:   {:system, "AMQP_KEY_PRODUCING", "raw"}

config :logger, :console,
  level: :info,
  format: "$date $time $metadata[$level] $levelpad$message\n"
