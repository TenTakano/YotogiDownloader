defmodule YotogiDownloader do
  require Logger

  @base_url       "http://easy2life.sakura.ne.jp"
  @export_path    "articles/"
  @retry_interval 5000

  alias YotogiDownloader.HttpClient, as: YH

  def download_spawn(collection_number) do
    pid = self()
    fetch_article_pathes(collection_number, pid)
    |> Enum.each(&fetch_and_export_article(&1, pid, collection_number))
  end

  def fetch_article_pathes(collection_number, pid) do
    {child, _} =
      spawn_monitor(fn ->
        url = @base_url <> "/yotogi2/index.php/#{collection_number}"
        %{body: body} = HTTPoison.get!(url, [], [recv_timeout: 10000])

        article_pathes =
          body
          |> String.split("<tr")
          |> Enum.map(&Regex.run(~r/<h2><a href=\"(.*)\">.*<\/a><\/h2>/, &1))
          |> Enum.reject(&is_nil/1)
          |> Enum.map(&Enum.at(&1, 1))

        exit({:ok, url, article_pathes})
      end)

    receive do
      {:DOWN, _ref, :process, ^child, {:ok, fetched_url, article_pathes}} ->
        Logger.info("success to fetch: #{fetched_url}")
        article_pathes
      {:DOWN, _ref, :process, ^child, reason} ->
        Logger.info("error: #{inspect(reason)}")
        :timer.sleep(@retry_interval)
        fetch_article_pathes(collection_number, pid)
      error ->
        Logger.info("unexpected error: #{inspect(error)}")
    end
  end

  def fetch_and_export_article(path, pid, collection_number) do
    url = @base_url <> path

    {child, _} =
      spawn_monitor(fn ->
        %{body: body} = HTTPoison.get!(url, [], [recv_timeout: 10000])

        [_, title, author] = Regex.run(~r/<title>(.*)\t\t\t\t\t作者:(.*)<\/title>/, body)
        file_name = @export_path <> "作品集#{collection_number}_#{title}_#{author}.html"
        File.write(file_name, body)
      end)

    receive do
      {:DOWN, _ref, :process, ^child, :normal} ->
        Logger.info("success to fetch and export: #{url}")
      {:DOWN, _ref, :process, ^child, reason} ->
        Logger.info("error: #{inspect(reason)}")
        :timer.sleep(@retry_interval)
        fetch_and_export_article(path, pid, collection_number)
      error ->
        Logger.info("unexpected error: #{inspect(error)}")
    end
  end
end
