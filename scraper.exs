defmodule Scrape
    def scraper(url, element // "body") do
        fn () ->
            HTTPotion.get(url)
            |> Map.fetch(:body)
            |> elem(1)
            |> Floki.find(element)
            |> Floki.text
        end
    end
end

Scrape.scraper