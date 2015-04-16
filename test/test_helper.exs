ExUnit.start()
{:ok, _} = Application.ensure_all_started(:hackney)
Logger.configure_backend(:console, colors: [enabled: true], metadata: [:request_id])
