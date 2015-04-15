# Pastelli
![alt](logo.png)

Pastelli is a colorful Plug adapter for [Elli](//github.com/knutin/elli)
with a focus on streaming chunked
connections (read `EventSource`).

For the moment,
it implements just a subset (see below) of the `Plug.Conn` api.

> why?

The current built-in Plug cowboy adapter does not notify the
connection owner process of the EventSource client
closing the socket (or just crashing).
Pastelli tries to address this issue.

More details in [this](https://github.com/elixir-lang/issues/xxx) issue.

## Usage
As you would do with your beloved `Plug.Adapters.Cowboy`,
you'll type:

```elixir
Pastelli.http MyPlug, [], [port: 4001]
```

## `Plug.Conn` API covered by pastelli
- read_req_body
- chunk
- send_chunked
- send_resp

## Roadmap

- [x] run http
- [ ] run https
- [ ] shutdown reference
- [ ] docs
- [ ] hex package
