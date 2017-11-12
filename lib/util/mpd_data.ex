defmodule Mpdart.MpdData do
  @moduledoc """
  Add document
  """
  defstruct [:type, :data]
  def new(type, data) do
    %Mpdart.MpdData {
      type: type,
      data: data,
    }
  end
  def to_json(mpd_data) do
    mpd_data
    |> Enum.map(fn(data) ->
      {data.type, data.data}
    end)
    |> Map.new
    |> Poison.encode!
  end
  def get(mpd_data) do
    mpd_data.data
  end
end
