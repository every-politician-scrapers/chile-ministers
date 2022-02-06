#!/bin/env ruby
# frozen_string_literal: true

require 'every_politician_scraper/scraper_data'
require 'pry'

# Spanish dates
class SpanishExtd < WikipediaDate
  REMAP = {
    'A la fecha' => '',
    'enero'      => 'January',
    'febrero'    => 'February',
    'marzo'      => 'March',
    'abril'      => 'April',
    'mayo'       => 'May',
    'junio'      => 'June',
    'julio'      => 'July',
    'agosto'     => 'August',
    'septiembre' => 'September',
    'octubre'    => 'October',
    'noviembre'  => 'November',
    'diciembre'  => 'December',
  }.freeze

  def date_en
    super.gsub(' de ', ' ').tidy
  end

  def remap
    super.merge(REMAP)
  end
end

class OfficeholderList < OfficeholderListBase
  decorator RemoveReferences
  decorator UnspanAllTables
  decorator WikidataIdsDecorator::Links

  def header_column
    'Periodo'
  end

  class Officeholder < OfficeholderBase
    def columns
      %w[img name dates].freeze
    end

    def date_class
      SpanishExtd
    end

    def tds
      noko.css('td,th')
    end
  end
end

url = ARGV.first
puts EveryPoliticianScraper::ScraperData.new(url, klass: OfficeholderList).csv
