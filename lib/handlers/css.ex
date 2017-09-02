defmodule MpdClient.Handlers.Css do
  def init(_type, req, []) do
    {:ok, req, :no_state}
  end

  def handle(request, state) do
    # Logger.debug "#{IO.inspect(state)}"

    method = :cowboy_req.method(request) |> elem(0)
    param = :cowboy_req.binding(:css, request) |> elem(0)
    {:ok, reply} = html_example(method, param, request)
    {:ok, reply, state}
  end

  def html_example("GET", :undefined, req) do
    headers = {"content-type", "text/css"}
    body = ""
    :cowboy_req.reply(404, [headers], body, req)
  end

  def html_example("GET", param, req) do
    headers = {"content-type", "text/css"}
    {:ok, body} = File.read(System.cwd! <> "/priv/static/css/#{param}")
    :cowboy_req.reply(200,[headers], body, req)
  end

  def terminate(reason, request, state) do
    # Logger.debug "Terminate for reason: #{inspect(reason)}"
    # Logger.debug "Terminate after request: #{inspect(request)}"
    # Logger.debug "Ternimating with state: #{inspect(state)}"
    :ok
  end
end

