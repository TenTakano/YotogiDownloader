defmodule YotogiDownloader do
  require Logger

  alias YotogiDownloader.HttpClient, as: YH

  def download(from, to) do
    Enum.each(from..to, &download/1)
  end
  def download(page_number) do
    case get_index_page(page_number) do
      {:ok, index_page} ->
        index_page
        |> get_article_pathes()
        |> Enum.each(&execute_download(&1, page_number))
      error ->
        inspect(error)
    end
  end

  def get_index_page(page_number) do
    YH.get_page("/yotogi2/index.php/#{page_number}")
  end

  def get_article_pathes(body) do
    body
    |> String.split("<tr")
    |> Enum.map(&Regex.run(~r/<h2><a href=\"(.*)\">.*<\/a><\/h2>/, &1))
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&Enum.at(&1, 1))
  end

  def execute_download(path, page_number) do
    case get_article(path) do
      {:ok, article} -> to_file(article, page_number)
      {:error, _} -> Logger.info("failed to get article")
    end
  end

  def get_article(path) do
    YH.get_page(path)
  end

  def to_file(article, page_number) do
    [_, title, author] = Regex.run(~r/<title>(.*)\t\t\t\t\t作者:(.*)<\/title>/, article)
    file_name = "articles/作品集#{page_number}_#{title}_#{author}.html"
    File.write(file_name, article)
  end
end
