defmodule DefaultWorker do
  use Exkiq.Worker

  def perform(pid, function) do
    :timer.sleep(3000)
    send pid, {:message, function.()}
  end
end
