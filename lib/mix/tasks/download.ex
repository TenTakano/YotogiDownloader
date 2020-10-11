defmodule Mix.Tasks.Download do
  use Mix.Task
  require Logger

  def run(args) do
    with(
      [from_str, to_str] <- args,
      {from, ""} <- Integer.parse(from_str),
      {to, ""} <- Integer.parse(to_str),
      true <- from < to
    ) do
      Logger.info("start to download collection #{from} to #{to}")
      YotogiDownloader.download(from, to)
    else
      _ -> IO.puts("command usage: mix download {from} {to} ('to' must be larger than 'from')")
    end
  end
end
