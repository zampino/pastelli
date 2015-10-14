# Pastelli ![travis](https://travis-ci.org/zampino/pastelli.svg)

![alt](logo.png)

Pastelli is a colorful Plug adapter for [Elli](//github.com/knutin/elli)
with a focus on streaming chunked
connections (read `EventSource`).

For the moment, this is quite alpha and
it implements just a subset (see below) of the `Plug.Conn` api.

## Usage
As you would do with your beloved `Plug.Adapters.Cowboy`,
you'll type:

```elixir
Pastelli.http MyPlug.Router, [], [port: 4001]
```
Now setup your router (or plug) as usual.
Pastelli changes the semantics of EventSource chunked responses,
in which it doesn't block your router dispatch:

```elixir
defmodule MyPlug.Router do
  use Plug.Router
  plug :match
  plug :dispatch

  def init(_options), do: []

  get "/connections/:id" do
    put_resp_content_type(conn, "text/event-stream")
    |> assign(:init_chunk,
      "retry: 6000\nid: #{id}\nevent: handshake\ndata: connected #{id}\n\n")
    # you can setup an initial chunk to be sent with the first connection
    |> send_chunked(200)
    |> register_stream(id)
    # with pastelli this dispatch won't block execution
    # but rather enter a receive loop just afterwards,
    # waiting for chunks
  end

  defp register_stream(conn, id) do
    {:ok, pid} = MyPlug.Connections.register id, conn
    # usually a :simple_one_for_one supervised
    # event manager registered into a hashdict of processes

    Process.link pid
    # we link the process to the streaming manager!
    # once the chunk is complete (client closes socket or crashes)
    # pastelli handler will send a shutdown exit to the connection process
    # it is your responsability to monitor the event manager and
    # do the necessary cleanup
    conn
  end
end
```

## Examples
Event Source based [remote control](https://github.com/zampino/plug_rc) backend
for slides.

## Web Sockets
Pastelli upgrades to Web Sockets thanks to mmzeeman's [elli_websockets](https://github.com/mmzeeman/elli_websocket).

Pass an elli_websocket
[handler](https://github.com/mmzeeman/elli_websocket#callback-module) in the private
map of your connection. This will receive the current connection as option argument.

```elixir
  get "/ws" do
    put_private(conn, :upgrade, {:websocket, WebSocketHandler})
  end

  defmodule WebSocketHandler do
    def websocket_init(request, conn: %Plug.Conn{} = conn) do
      # ...
    end
    def websocket_handle() # handle callback
    def websocket_info() # info callback
  end
```

## Pastelli and Phoenix

In this contrived [experiment](https://github.com/zampino/phoenix-on-pastelli)
you can see Pastelli in action,
replacing Cowboy from the heart of [Phoenix (v1.0.0)](htts://phoenixframework.org) in favour of Elli,
for both HTTP and WebSocket communication.

## Pastelli tries to help!

The current built-in Plug cowboy adapter does not notify the
connection owner process of the EventSource client
closing the socket (or just crashing).
More precisely, Pastelli tries to address this [issue](https://github.com/elixir-lang/plug/issues/228).

## `Plug.Conn.Adapter` behaviour currently covered by pastelli

- [x] send_resp
- [x] send_file
- [x] send_chunked
- [x] chunk
- [x] read_req_body
- [ ] parse_req_multipart

## `Plug.Conn.Adapter` extensions

- initial chunk
- close chunk

## Agenda

- [x] run http
- [ ] run https
- [x] websocket upgrade via mmzeeman/elli_websocket
- [ ] Plug.Conn extensions
- [ ] hex package
