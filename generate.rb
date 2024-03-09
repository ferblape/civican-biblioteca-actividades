require "nokogiri"
require "open-uri"
require "openssl"
require "rss"
require "pry"

URL = "https://www.bibliotecaspublicas.es/civican/Nuestras-Actividades/Agenda.html"

activities = []
SSL_OPTIONS = {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}

def extract_description(url)
  doc = Nokogiri::HTML(URI.open(url, SSL_OPTIONS))
  doc.css("div.detalle").text.strip
end

rss = RSS::Maker.make("atom") do |maker|
  maker.channel.author = "Fernando Blat"
  maker.channel.updated = Time.now.to_s
  maker.channel.about = "https://www.bibliotecaspublicas.es/civican/Nuestras-Actividades/Agenda.html"
  maker.channel.title = "Actividades Biblioteca Civican Pamplona"

  doc = Nokogiri::HTML(URI.open(URL, SSL_OPTIONS))

  doc.css("div.actividades").each do |activity_html|
    maker.items.new_item do |item|
      date = activity_html.css(".fecha h4").children.last.text
      time = activity_html.css(".hora").text.match(/\d{2}:\d{2}/).to_s
      title_html = activity_html.css(".row a")
      title_url = title_html.attr("href").value
      full_url = URL.split("/")[0..2].join("/") + title_url
      title = title_html.text
      description = extract_description(full_url)

      item.link = full_url
      item.title = "#{title} - #{date} - #{time}"
      item.updated = Time.now.to_s
      item.summary = description
    end
  end
end

File.write("output/feed.atom", rss.to_s)
