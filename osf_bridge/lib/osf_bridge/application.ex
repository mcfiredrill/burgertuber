defmodule OsfBridge.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      OsfBridgeWeb.Telemetry,
      # OsfBridge.Repo,
      {DNSCluster, query: Application.get_env(:osf_bridge, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: OsfBridge.PubSub},
      {OsfBridge.UdpListener, port: 12000},
      # {OsfBridge.WebSocket, []},
      # Start a worker by calling: OsfBridge.Worker.start_link(arg)
      # {OsfBridge.Worker, arg},
      # Start to serve requests, typically the last entry
      OsfBridgeWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: OsfBridge.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    OsfBridgeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
