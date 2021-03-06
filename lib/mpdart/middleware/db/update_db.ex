defmodule Mpdart.Middleware.DB.UpdateDB do
  @moduledoc """
  The module update music data on Redis, from music directory.
  """
  use GenServer
  import Logger

  def update_db do
    Logger.debug fn -> "Mpdart.Middleware.DB.UpdateDB update_db" end

    host = Application.get_env(:mpdart, :redis_host)
    port = Application.get_env(:mpdart, :redis_port)
    {:ok, conn} = Redix.start_link(host: host, port: port)

    :util
    |> GenServer.call({:list_all, "/"})
    |> Enum.filter(&(&1.type == "file"))
    |> Enum.each(fn(path) ->
      {:ok, t} =
        (Application.get_env(:mpdart, :musicdir) <> path.data)
        |> Taglib.new()
      t |> store_data(path.data, conn)
    end)
  end

  def is_none(""), do: "Unknown"
  def is_none(str), do: str

  def store_data(tag, path, conn) do
    song_key = ["Song:", path] |> Enum.join()

    album = tag |> Taglib.album() |> is_none
    artist = tag |> Taglib.artist() |> is_none
    album_key = ["Album:", album, ":", artist] |> Enum.join()
    songs_key = ["Songs:", album, ":", artist] |> Enum.join()

    if conn |> Redix.command!(["EXISTS", album_key]) == 0 do
      conn |> Redix.command(["HSET", album_key, "album", album])
      conn |> Redix.command(["HSET", album_key, "artist", artist])
      conn |> Redix.command(["HSET", album_key, "albumdir", path |> Path.dirname])
    end

    conn |> Redix.command(["HSET", song_key, "artist", artist])
    conn |> Redix.command(["HSET", song_key, "album", album])

    conn |> Redix.command(["HSET", album_key, "coverart", "/priv/static/images/no_image.png"])
    conn |> Redix.command(["SADD", songs_key, path])

    [
      fn(tag) -> {"compilation", tag |> Taglib.compilation()} end,
      fn(tag) -> {"disc",        tag |> Taglib.disc()} end,
      fn(tag) -> {"duration",    tag |> Taglib.duration()} end,
      fn(tag) -> {"genre",       tag |> Taglib.genre()} end,
      fn(tag) -> {"title",       tag |> Taglib.title()} end,
      fn(tag) -> {"track",       tag |> Taglib.track()} end,
      fn(tag) -> {"year",        tag |> Taglib.year()} end,
    ] |> Enum.each(fn(func) ->
      Task.async(fn ->
        {id, key} = tag |> func.()
        conn |> Redix.command(["HSET", path, id, key |> is_none()])
      end)
    end)
    :ok
  end
end
