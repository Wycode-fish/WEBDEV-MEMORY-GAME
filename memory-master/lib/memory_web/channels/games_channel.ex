defmodule MemoryWeb.GamesChannel do
  use MemoryWeb, :channel

  alias Memory.Game

  def join("games:"<>name, payload, socket) do
    if authorized?(payload) do
      game = Memory.GameBackup.load(name) || Game.new()
      socket = socket
      |>assign(:name, name)
      |>assign(:game, game);
      {:ok, %{"join"=>name, "game"=>Game.serverToClientState(game)}, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end



  def handle_in("restart", payload, socket) do
    game = Game.new();
    Memory.GameBackup.save(socket.assigns[:name], game);
    
    clientState = game|>Game.serverToClientState;
    socket = socket
    |>assign(:game, game);
    {:reply, {:ok, %{"game" => clientState}}, socket};
  end

  def handle_in("guess", %{"tile_id"=>tid}, socket) do
    serverGame = socket.assigns[:game];
    serverGameNext = Game.onTileSelected(serverGame, tid);
    Memory.GameBackup.save(socket.assigns[:name], serverGameNext);
    socket = socket|>assign(:game, serverGameNext);

    clientState = serverGameNext|>Game.serverToClientState;
    {:reply, {:ok, %{"game" => clientState}}, socket};
  end

  def handle_in("timeout", payload, socket) do
    serverGame = socket.assigns[:game];
    serverGameNext = Game.onTimeout(serverGame);
    Memory.GameBackup.save(socket.assigns[:name], serverGameNext);
    socket = socket|>assign(:game, serverGameNext);

    clientState = serverGameNext|>Game.serverToClientState;
    {:reply, {:ok, %{"game" => clientState}}, socket};
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (games:lobby).
  def handle_in("shout", payload, socket) do
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
