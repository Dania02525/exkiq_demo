defmodule ExkiqDemo.JobsChannel do
  use ExkiqDemo.Web, :channel

  def join("jobs:stats", _payload, socket) do
    update_stats()
    {:ok, socket}
  end

  def handle_in("ping", _payload, socket) do
    payload = %{ "topic" => "",
                 "event" => "pong",
                 "payload" => %{"message" => "pong"},
                 "ref" => ""
               }
    {:reply, {:ok, payload}, socket}
  end

  def handle_in("update", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  def handle_in("message", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  def handle_in("queue_job", payload, socket) do
    function =
      case payload["message"] do
        "" -> fn -> "none" end
        msg ->
          {result, _ } = Code.eval_string(msg)
          result
      end
    DefaultWorker.perform_async(self(), function)
    {:reply, {:ok, stat}, socket}
  end

  def handle_out(event, payload, socket) do
    push socket, event, payload
    {:noreply, socket}
  end

  def handle_info(:get_stats, socket) do
    push socket, "update", stat
    update_stats()
    {:noreply, socket}
  end

  def handle_info({:message, message}, socket) do
    push socket, "message", %{message: message}
    {:noreply, socket}
  end

  defp update_stats do
    Process.send_after(self(), :get_stats, 1000)
  end

  defp stat do
    stats = Exkiq.stats()
    %{
      default: stats.default,
      running: stats.running,
      retry: stats.retry,
      succeeded: stats.succeeded,
      failed: stats.failed,
      producer: "#{inspect :global.whereis_name(Exkiq.JobAggregator)}",
      consumer: "#{inspect Process.whereis(Exkiq.JobSupervisor)}",
      role: "#{role()}",
      node: "#{inspect Node.self()}"
    }
  end

  defp role do
    cond do
      Exkiq.master? -> "master"
      true -> "slave"
    end
  end
end
