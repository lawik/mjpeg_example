defmodule MjpegExample.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      MjpegExample,
      {Plug.Cowboy,
       scheme: :http,
       plug:
         {Mjpeg,
          connect_callback: &MjpegExample.connect/2, wait_callback: &MjpegExample.wait_callback/1},
       options: [
         port: 4001,
         protocol_options: [idle_timeout: :infinity]
       ]}
      # Starts a worker by calling: MjpegExample.Worker.start_link(arg)
      # {MjpegExample.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MjpegExample.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
