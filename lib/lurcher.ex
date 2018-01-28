defmodule Lurcher do
  require Logger
  use Application

  def start(_type, _args) do
    Logger.info "Starting lurcher application"
    Confex.resolve_env!(:lurcher)

    import Supervisor.Spec, warn: false
    sup_children = [
      worker(Lurcher.MQ, []),
      worker(Lurcher.SocketClient, [])
    ]
    sup_opts = [strategy: :one_for_one, name: Lurcher.Supervisor]
    Supervisor.start_link(sup_children, sup_opts)
  end

end
