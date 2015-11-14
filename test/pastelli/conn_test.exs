defmodule Pastelli.ConnTest do
  use ExUnit.Case
  import Mock
  require Plug.Conn

  test_with_mock "Pastelli.Conn.event/2", Plug.Conn, [
    chunk: fn(conn, data) ->
      %{conn | assigns: Map.put(conn.assigns, :just_chunked, data) }
    end] do
    conn = %Plug.Conn{state: :chunked} |> Pastelli.Conn.event("some data")

    %Plug.Conn{ assigns: %{just_chunked: data} } = conn
    assert data == "data: some data\n\n"
  end

  test_with_mock "Pastelli.Conn.event/2 with map", Plug.Conn, [
    chunk: fn(conn, data) ->
      %{conn | assigns: Map.put(conn.assigns, :just_chunked, data) }
    end] do
    conn = %Plug.Conn{state: :chunked} |> Pastelli.Conn.event(%{foo: "bar"})

    %Plug.Conn{ assigns: %{just_chunked: data} } = conn
    assert data == "data: {\"foo\":\"bar\"}\n\n"
  end

  test_with_mock "Pastelli.Conn.event/2 with map and (filtered) options", Plug.Conn, [
    chunk: fn(conn, data) ->
      %{conn | assigns: Map.put(conn.assigns, :just_chunked, data) }
    end] do
    conn = %Plug.Conn{state: :chunked}
    |> Pastelli.Conn.event([%{foo: 3}], id: 1234, event: "handshake", fake: "param")

    %Plug.Conn{ assigns: %{just_chunked: data} } = conn
    assert data == "event: handshake\nid: 1234\ndata: [{\"foo\":3}]\n\n"
  end

  test "Plug.Conn.init_chunk/2" do
    conn = %Plug.Conn{state: :chunked, private: %{}}
    %Plug.Conn{private: private} = Pastelli.Conn.init_chunk(conn, [%{foo: 3}, 1], event: :handshake)
    assert private.init_chunk == "event: handshake\ndata: [{\"foo\":3},1]\n\n"
  end

end
