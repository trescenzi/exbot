defmodule EXBot do use GenServer

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    state = %{state | :socket => Socket.TCP.connect!(state.host, state.port, packet: :line)}
    {:ok, state, 1}
  end

  def connect(pid) do
    GenServer.call(pid, :connect)
  end

  def handle_info(:timeout, state) do
    IO.puts('handeling shit')
    state |> join_channel |> listen
    {:noreply, state}
  end

  def handle_call(:connect, _from, state) do
    IO.puts("doing stuff #{state.nick}")
    join_channel(state)
    {:noreply, state, 0}
  end

  defp join_channel(%{:socket => socket} = state) do
    IO.puts("JOINING")
    socket |> Socket.Stream.send!("NICK #{state.nick}\r\n")
    socket |> Socket.Stream.send!("USER  #{state.nick} #{state.host} #{state.nick} Sir#{state.nick}\r\n")
    socket |> Socket.Stream.send!("JOIN #{state.chan}\r\n")
    state
  end

  defp listen(%{:socket => socket} = state) do
    case state.socket |> Socket.Stream.recv! do
      data when is_binary(data) ->
        IO.puts('got something!')
        IO.puts(data)
        parse_message(data) |> generate_response(socket)
      _ ->
        IO.puts('nothin')
    end
    listen(state)
  end

  defp parse_message(message) do
    message |> String.split
  end

  defp generate_response(["PONG", host], socket) do
    socket |> Socket.Stream.send! "PING #{host}\r\n"
  end

  defp generate_response([who, "PRIVMSG", channel | message], socket) do
    if Regex.match?(~r/.*[Dd][Rr](\s+|.?$).*$/, message |> Enum.intersperse(" ") |> List.to_string) do
      socket |> Socket.Stream.send! "PRIVMSG #bunghawks Why hello there fine weather isn't it\r\n"
    else
      IO.puts('OH NO')
    end
  end

  defp generate_response(message, socket) do
    IO.puts(message)
  end
end
