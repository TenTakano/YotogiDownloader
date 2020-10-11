defmodule YotogiDownloader.HttpClient do
  require Logger

  @base_url       "http://easy2life.sakura.ne.jp"
  @wait_count     1000
  @trial_limit    5
  @error_log_path "error.log"

  def get_page(path, trials \\ 0) do
    :timer.sleep(@wait_count)

    case HTTPoison.get(@base_url <> path, timeout: :infinity) do
      {:ok, %{body: body}} ->
        Logger.info("success to fetch: #{path}")
        {:ok, body}
      {:error, _} ->
        if trials == @trial_limit do
          Logger.info("reach to trial limit")
          write_error_log(path)
          {:error, :reach_to_limit}
        else
          Logger.info("request timeout: trial #{trials}/#{@trial_limit}")
          get_page(path, trials + 1)
        end
    end
  end

  def write_error_log(path) do
    File.write(@error_log_path, path <> "\n", [:append])
  end
end
