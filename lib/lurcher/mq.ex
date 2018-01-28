defmodule Lurcher.MQ do
  require Logger
  use GenServer
  use AMQP

  def produce(msg, true) do
    GenServer.cast(Lurcher.MQ, {:produce, msg})
  end
  def produce(_, false) do
    :ok
  end

  def start_link do
    GenServer.start_link(__MODULE__, [], name: Lurcher.MQ)
  end

  def init(_) do
    {:ok, chan, key, exchange} = mq_connect
    state = %{
      chan:     chan,
      key:      key,
      exchange: exchange,
    }
    {:ok, state}
  end

  def handle_cast({:produce, msg}, state) do
    Basic.publish(state[:chan], state[:exchange], state[:key], msg)
    {:noreply, state}
  end

  def handle_info({:DOWN, _, :process, _pid, _reason}, state) do
    {:ok, chan, key, exchange} = mq_connect
    {:noreply, %{state | chan:     chan,
                         key:      key,
                         exchange: exchange}}
  end
  def handle_info(_, state) do
    {:noreply, state}
  end

  defp generate_mq_vars do
    mq_path = Application.get_env(:lurcher, :amqp_path)
    cfg_exchange = Application.get_env(:lurcher, :amqp_exchange)
    cfg_queue_prod = Application.get_env(:lurcher, :amqp_queue_producing)
    cfg_key = Application.get_env(:lurcher, :amqp_key_producing)

    exchange = "auriga.#{cfg_exchange}"
    queue = "#{exchange}.#{cfg_queue_prod}"
    queue_error = "#{exchange}.error"
    key = "auriga.#{cfg_key}"

    {:ok, mq_path, queue, queue_error, key, exchange}
  end

  defp mq_connect do
    {:ok, mq_path, queue, queue_error, key, exchange} = generate_mq_vars
    mq_path_censored = Regex.replace(~r/:[^\/].+@/, mq_path, ":[REDACTED]@")
    Logger.info("Connecting to AMQP server at #{mq_path_censored}")

    case Connection.open(mq_path) do
      {:ok, conn} ->
        Process.monitor(conn.pid)
        {:ok, chan} = Channel.open(conn)
        setup_queue(chan, queue, queue_error, key, exchange)
        Basic.qos(chan, prefetch_count: 10)
        Logger.info("Connected")
        {:ok, chan, key, exchange}
      {:error, error} ->
        Logger.error("AMQP connection problem: #{inspect error}")
        :timer.sleep(5000)
        mq_connect
    end
  end

  defp setup_queue(chan, queue, queue_error, key, exchange) do
    Queue.declare(chan, queue_error, durable: true)
    # Messages that cannot be delivered to any consumer in the main queue will be routed to the error queue
    Queue.declare(chan, queue, durable: true,
                               routing_key: key,
                               arguments: [{"x-dead-letter-exchange", :longstr, ""},
                                           {"x-dead-letter-routing-key", :longstr, queue_error}])
    Exchange.topic(chan, exchange, durable: true)
    Queue.bind(chan, queue, exchange, routing_key: key)
  end

end
