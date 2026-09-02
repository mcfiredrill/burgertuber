ExUnit.start()

if Process.whereis(OsfBridge.Repo) do
  Ecto.Adapters.SQL.Sandbox.mode(OsfBridge.Repo, :manual)
end
