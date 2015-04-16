defmodule PastelliTest do
  use ExUnit.Case

  import Pastelli

  test "build arguments for elli:start_link" do
    assert build_elli_options(:http, __MODULE__, :plug_options,
      [some: :custom_options]) == [
        some: :custom_options,
        callback_args: {__MODULE__, :plug_options},
        port: 4000,
        callback: Pastelli.Handler,
      ]
  end
end
