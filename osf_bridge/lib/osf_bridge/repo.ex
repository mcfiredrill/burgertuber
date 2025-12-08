defmodule OsfBridge.Repo do
  use Ecto.Repo,
    otp_app: :osf_bridge,
    adapter: Ecto.Adapters.Postgres
end
