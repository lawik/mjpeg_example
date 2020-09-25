defmodule MjpegExample do
  use GenServer
  import Mogrify
  require Logger

  @keepalive_interval 1000
  @keepalive_update_seconds 5

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, nil, opts ++ [name: __MODULE__])
  end

  @impl GenServer
  def init(_) do
    Process.send_after(self(), :update, 1)
    keep_alive()
    {:ok, {nil, nil, %{}}}
  end

  def connect(_conn, _opts) do
    id = GenServer.call(__MODULE__, :connect)

    %{
      error_callback: fn ->
        Logger.info("Error callback from Plug: #{id}")
        GenServer.cast(__MODULE__, {:disconnect, id})
      end
    }
  end

  @impl GenServer
  def handle_call(:connect, {pid, _ref} = _from, {last_frame, last_update, connections}) do
    id = :erlang.unique_integer()
    Logger.info("Connect from #{inspect(pid)}: #{id}")
    connections = Map.put(connections, id, pid)

    # For some reason, need to send two frames to actually get an instant result
    Process.send_after(self(), :update, 1)
    Process.send_after(self(), :update, 2)
    {:reply, id, {last_frame, last_update, connections}}
  end

  @impl GenServer
  def handle_cast({:disconnect, id}, {last_frame, connections}) do
    Logger.info("Disconnect: #{id}")
    connections = Map.delete(connections, id)
    {:noreply, {last_frame, connections}}
  end

  @impl GenServer
  def handle_info(:keepalive, {_, last_update, _} = state) do
    diff = DateTime.diff(DateTime.now!("Etc/UTC"), last_update)
    Logger.info("keepalive check: #{diff}")

    if diff >= @keepalive_update_seconds do
      Logger.info("keepalive updating")
      Process.send(self(), :update, [:nosuspend])
    end

    keep_alive()

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:update, {_last_frame, _last_update, connections}) do
    Logger.info("Updating...")
    frame = create_frame(connections)

    connections =
      Enum.reduce(connections, connections, fn {id, pid}, connections ->
        Logger.info("Checking: #{id}")

        if Process.alive?(pid) do
          Logger.info("Alive: #{id}")

          case send_frame(pid, frame) do
            :ok ->
              Logger.info("Sent: #{inspect(pid)} #{id}")
              connections

            :nosuspend ->
              Logger.info("No suspend: #{id}")
              connections
          end
        else
          Logger.info("Deleted: #{id}")
          Map.delete(connections, id)
        end
      end)

    Logger.info("Update complete")

    {:noreply, {frame, DateTime.now!("Etc/UTC"), connections}}
  end

  def wait_callback(_context) do
    receive do
      {:frame, frame} ->
        Logger.info("Received at #{inspect(self())}")
        frame
    end
  end

  defp keep_alive do
    Process.send_after(self(), :keepalive, @keepalive_interval)
  end

  defp create_frame(connections) do
    count = Enum.count(connections)
    Logger.info("Connection count: #{count}")

    %Mogrify.Image{path: "frame.jpg", ext: "jpg"}
    |> quality(100)
    |> custom("background", "#000000")
    |> custom("gravity", "center")
    |> custom("fill", "white")
    |> custom("font", "DejaVu-Sans-Mono-Bold")
    |> custom(
      "pango",
      ~s(<span foreground="#00ffff">Currently <span foreground="#ff00ff">#{count}</span> site readers</span>)
    )
    |> create(path: ".")

    File.read!("frame.jpg")
  end

  defp send_frame(pid, last_frame) do
    Process.send(pid, {:frame, last_frame}, [:nosuspend])
  end
end
