defmodule Lurcher.SocketClient do
  require Logger
  use WebSockex
  alias Lurcher.Message
  alias Lurcher.MQ

  @discord_api_version "6"

  def start_link do
    Logger.info "Starting new websocket client"

    gateway_host = Application.get_env(:lurcher, :gateway_host)
    url = "wss://#{gateway_host}/?v=#{@discord_api_version}&encoding=json"
    connect_opts = [
      socket_connect_timeout: 10000,
      socket_recv_timeout:    60000,
      extra_headers:          [{"Accept-Encoding", "zlib"}]
    ]

    initial_state = %{sequence:           0,
                      trace:              [],
                      heartbeat_interval: 30000}

    Logger.info "Connecting to #{url}"
    WebSockex.start_link(url, __MODULE__, initial_state, connect_opts)
  end

  def handle_connect(conn, state) do
    Logger.info "Connected"
    schedule(state[:heartbeat_interval])
    {:ok, state}
  end

  def handle_frame({:text, msg}, state) do
    {:ok, decoded} = Poison.Parser.parse(msg, keys: :atoms)
    sequental_state = %{state | sequence: decoded[:s]}
    
    MQ.produce(msg, Message.pushable(decoded))

    case Message.process(decoded, sequental_state) do
      {:noreply, new_state} -> {:ok, new_state}
      {reply, new_state}    -> {:reply, {:text, reply}, new_state}
    end
  end

  def handle_disconnect(%{reason: {:local, reason}}, state) do
    Logger.info "Local close with reason: #{inspect reason}"
    {:ok, state}
  end
  def handle_disconnect(disconnect_map, state) do
    Logger.info "#{inspect disconnect_map}"
    Logger.info "Disconnected"
    super(disconnect_map, state)
  end

  def handle_info(:heartbeat, state) do
    msg = Message.generate_heartbeat(state[:sequence])
    schedule(state[:heartbeat_interval])
    {:reply, {:text, msg}, state}
  end

  defp schedule(heartbeat_interval) do
    Process.send_after(self(), :heartbeat, heartbeat_interval)
  end
  
end
