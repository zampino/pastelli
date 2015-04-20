# Pastelli ![travis](https://travis-ci.org/zampino/pastelli.svg)

![alt](logo.png)

Pastelli is a colorful Plug adapter for [Elli](//github.com/knutin/elli)
with a focus on streaming chunked
connections (read `EventSource`).

For the moment,
it implements just a subset (see below) of the `Plug.Conn` api.

## Usage
As you would do with your beloved `Plug.Adapters.Cowboy`,
you'll type:

```elixir
Pastelli.http MyPlug, [], [port: 4001]
```

Now setup your router (or plug) as usual
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

```

## Examples
For a working example, have a look [here](https://github.com/zampino/plug_rc).

## Pastelli tries to help!

The current built-in Plug cowboy adapter does not notify the
connection owner process of the EventSource client
closing the socket (or just crashing).
More precisely, Pastelli tries to address this [issue](https://github.com/elixir-lang/plug/issues/228).

## `Plug.Conn` API covered by pastelli
- read_req_body
- chunk
- send_chunked
- send_resp

## `Plug.Conn` api extensions
- initial chunk
- close chunk

## Roadmap

- [x] run http
- [ ] run https
- [x] shutdown reference
- [ ] docs
- [ ] hex package
