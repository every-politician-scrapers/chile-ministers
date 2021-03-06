#!/bin/env ruby
# frozen_string_literal: true

require 'every_politician_scraper/scraper_data'
require 'pry'
require 'wikidata_ids_decorator'

class RemoveReferences < Scraped::Response::Decorator
  def body
    Nokogiri::HTML(super).tap do |doc|
      doc.css('sup.reference').remove
    end.to_s
  end
end

class UnspanInfoTables < Scraped::Response::Decorator
  def body
    Nokogiri::HTML(super).tap do |doc|
      doc.css('table.infobox').each do |table|
        unspanned_table = TableUnspanner::UnspannedTable.new(table)
        table.children = unspanned_table.nokogiri_node.children
      end
    end.to_s
  end
end

class RemoveEmptyRows < Scraped::Response::Decorator
  def body
    Nokogiri::HTML(super).tap do |doc|
      doc.css('.mw-empty-elt').remove
    end.to_s
  end
end


class MemberList
  class Members
    decorator RemoveReferences
    decorator RemoveEmptyRows
    decorator UnspanInfoTables
    decorator WikidataIdsDecorator::Links

    def members
      super.reject { |row| row[:name].to_s.empty? }
    end

    def member_container
      noko.xpath('//table[.//th[contains(.,"Piñera Cabinet")]][last()]//tr[td[3]]')
    end
  end

  class Member
    field :wdid do
      tds[1].css('a/@wikidata').map(&:text).first
    end

    field :name do
      tds[1].css('a').map(&:text).map(&:tidy).first || tds[1].text.tidy
    end

    field :position do
      tds[0].text.tidy
    end

    field :startDate do
      term_dates[0]
    end

    field :endDate do
      term_dates[1]
    end

    private

    def tds
      noko.css('td,th')
    end

    def term_dates
      tds[3].text.split('–').map { |str| Date.parse(str).to_s }
    end
  end
end

url = ARGV.first
puts EveryPoliticianScraper::ScraperData.new(url).csv
