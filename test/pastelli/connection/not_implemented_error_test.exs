defmodule Pastelli.Connection.NotImplementedErrorTest do
  use ExUnit.Case
  require Logger

  test "send_file is not implemented yet" do
    Pastelli.Connection.send_file(1, 2, 3, 4, 5, 6)
  rescue
    exception ->
      assert exception == %Pastelli.Connection.NotImplementedError{message: "'send_file' is not supported by Pastelli.Connection yet"}
  end

  test "parse_req_multipart is not implemented yet" do
    Pastelli.Connection.parse_req_multipart(1, 2, 3)
  rescue
    exception ->
      assert exception == %Pastelli.Connection.NotImplementedError{message: "'parse_req_multipart' is not supported by Pastelli.Connection yet"}
  end
end
