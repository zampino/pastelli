# Pastelli

Pastelli is a Plug adapter for [Elli](//github.com/knutin/elli) 
with a focus on dealing with `EventSource`
connections. For the moment,
it implements just a subset of the `Plug.Conn` api.

> why?

The current built-in cowboy does not notify the
connection owner process of the EventSource client
closing the socket (or just crashing).

More details in [this](https://github.com/elixir-lang/issues/xxx) issue.


## Examples
