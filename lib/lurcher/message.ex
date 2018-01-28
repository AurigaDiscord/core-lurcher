defmodule Lurcher.Message do
  require Logger

  # constants of API operations IDs
  @op_dispatch              0
  @op_heartbeat             1
  @op_identify              2
  @op_status_update         3
  @op_voice_state_update    4
  @op_voice_server_ping     5
  @op_resume                6
  @op_reconnect             7
  @op_request_guild_members 8
  @op_invalid_session       9
  @op_hello                 10
  @op_heartbeat_ack         11
  
  def process(%{:op => @op_hello} = message, state) do
    token = Application.get_env(:lurcher, :bot_token)
    threshold = Application.get_env(:lurcher, :large_threshold)
    shards_total = Application.get_env(:lurcher, :shards_total)
    shard_to_use = Application.get_env(:lurcher, :shard_to_use)
    {_, os} = :os.type
    hello_data = %{:token => token,
                   :compress => false,
                   :large_threshold => threshold,
                   :shard => [shard_to_use, shards_total],
                   :presence => generate_presence(:online),
                   :properties => %{"$os" => os,
                                    "$browser" => "auriga",
                                    "$device" => "auriga"}}
    {:ok, reply} = Poison.encode(%{:op => @op_identify,
                                   :d => hello_data})

    {:ok, hello_data_exposed} = Poison.encode(%{hello_data | :token => "[REDACTED]"})
    Logger.info("Sending identify information: #{hello_data_exposed}")

    new_state = %{state | :heartbeat_interval => message[:d][:heartbeat_interval],
                          :trace => message[:d][:_trace]}

    {reply, new_state}
  end

  def process(_, state) do
    {:noreply, state}
  end

  def generate_heartbeat(sequence) do
    message = %{:op => @op_heartbeat,
                :d => sequence}
    {:ok, encoded} = Poison.encode(message)
    encoded
  end

  def pushable(message) do
    case message[:op] do
      @op_heartbeat     -> false
      @op_heartbeat_ack -> false
      _                 -> true
    end
  end

  defp generate_presence(status) do
    game_name = Application.get_env(:lurcher, :playing_status)
    %{:status => status,
      :afk => false,
      :game => %{:name => game_name,
                 :type => 0}}
  end

end
