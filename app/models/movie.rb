require 'netflix'
require 'tmdb'

class Movie < Mingo
  property :title
  property :original_title
  property :year
  property :plot
  property :poster_small_url
  property :poster_medium_url
  
  property :tmdb_id
  property :tmdb_url

  property :runtime
  # property :language
  property :countries
  property :homepage

  property :directors
  # key :cast, Array
  
  def self.tmdb_search(term)
    result = Tmdb.search(term)
    
    if result.class == String then result
    else    
      result.movies.map { |movie|
        find_or_create_from_tmdb(movie)
      }
    end
  end
  
  def self.find_or_create_from_tmdb(movie)
    first(:tmdb_id => movie.id) || create(
      :title => movie.name,
      :original_title => movie.original_name,
      # :language => movie.language,
      :year => movie.year,
      :poster_small_url => movie.poster_thumb,
      :poster_medium_url => movie.poster_cover,
      :plot => movie.synopsis,
      :tmdb_id => movie.id,
      :tmdb_url => movie.url
    )
  end
  
  EXTENDED = [:runtime, :countries, :directors, :homepage]
  
  def ensure_extended_info
    if extended_info_missing? and self.tmdb_id
      tmdb_movie = Tmdb.movie_details(self.tmdb_id)
      self.runtime = tmdb_movie.runtime
      # self.language = tmdb_movie.language
      self.countries = tmdb_movie.countries
      self.directors = tmdb_movie.directors
      self.homepage = tmdb_movie.homepage
      self.save
    end
  end
  
  def extended_info_missing?
    EXTENDED.any? { |property| self[property].nil? }
  end
  
  def self.netflix_search(term, page = 1)
    page ||= 1
    catalog = Netflix.search(term, page)
    
    WillPaginate::Collection.create(page, catalog.per_page, catalog.total_entries) do |collection|
      collection.replace catalog.titles.map { |title|
        find_or_create_from_netflix(title)
      }
    end
  end
  
  def self.find_or_create_from_netflix(title)
    first(:netflix_id => title.id) || create(
      :title => title.name,
      :year => title.year,
      :poster_small_url => title.poster_medium,
      :poster_medium_url => title.poster_large,
      :runtime => title.runtime,
      :plot => title.synopsis,
      :directors => title.directors,
      :cast => title.cast,
      :netflix_id => title.id,
      :netflix_url => title.netflix_url,
      :official_website => title.official_url
    )
  end

end
