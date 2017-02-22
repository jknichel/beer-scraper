require 'rubygems'
require 'bundler/setup'

require 'httparty'
require 'nokogiri'
require 'json' 
require 'byebug'
require 'csv'
require 'similar_text'

def get_ba_top_250_array
    page = HTTParty.get('https://www.beeradvocate.com/lists/top/')
    table_entries = Nokogiri::HTML(page).css('#ba-content').css('tr')[2..-1]

    #assert_equals 250, table_entries.count, "BA Top 250 not loaded properly."

    entries_array = table_entries.inject([]) do |array, entry|
        beer_name = entry.css('td')[1].css('a').css('b').text.rstrip
        brewery = entry.css('td').css('#extendedInfo').css('a').first.text.rstrip
        style = entry.css('td').css('#extendedInfo').css('a')[1].text.rstrip
        array.push({ name: beer_name, brewery: brewery, style: translate_style(style) })
        array
    end 
    return entries_array
end

def get_hunas_list_array
    page = HTTParty.get('http://hunahpusday.com/beer-list/')
    entries = Nokogiri::HTML(page).css('.breweries')

    array = entries.inject([]) do |array, entry|
        brewery = entry.css('.article-header').css('a').text.rstrip
        beers = entry.css('li/a > text()').map { |tag| tag.text.rstrip }
        styles = entry.css('li/a/span').map { |tag| tag.text.rstrip }
        beers.each { |beer| array.push({ name: beer, brewery: brewery }) }
        array
    end

    array
end

def translate_style(style)
    style
end

def string_difference_percentage(a, b)
    longer = [a.size, b.size].max
    same = a.each_char.zip(b.each_char).select { |a,b| a == b }.size
    (longer - same) / a.size.to_f
end

def compare_beer(ba_array, hunas_array)
    matches = []
    hunas_array.each do |beer|
        ba_array.each do |top|
            name_similarity = beer[:name].similar(top[:name])
            brewery_similarity = beer[:brewery].similar(top[:brewery])
            matches << [top, beer] if (name_similarity > 70 && brewery_similarity > 70)
        end
    end
    byebug
    matches
end

compare_beer(get_ba_top_250_array, get_hunas_list_array)
