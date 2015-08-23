require 'sinatra'
require 'nokogiri'
require 'open-uri'

# configure :development do
#   set :bind, '0.0.0.0'
#   set :port, 3000
# end

#################$
## PAGE ROUTES #$
###############$

# before do
#   @username = session['user']  if session['user']
# end

#!!TODO 
# Finish stackexchange/core
# Add indeed, dice, Linkedin (login req), angelist (login req)
#1ppw5u+5x6c1m1avtqbo@sharklasers.com #testpass

get '/' do
  erb :index
end


get '/:content_source/:city/:range/:keyword' do 
  @cs = params[:content_source]
  @city = params[:city].gsub(' ', '+')
  @range = params[:range]
  @keyword = params[:keyword].gsub(' ', '+')
  @tags = {}
  
  if @cs == "stack" || "all"
    @stack_url = "http://careers.stackoverflow.com/jobs?searchTerm=#{@keyword}&location=#{@city}&range=#{@range}&distanceUnits=Miles&sort=p"
    fetch = Nokogiri::HTML(open(@stack_url))
    @stack_info = fetch.css('span.description').first.text.gsub('â', '')

    #Go through each page
    @pages = []
    fetch.css('div.pagination').children.each { |pp| @pages <<  pp.text if pp.text.strip != "" && pp.text.strip != "next"  }
    if @pages.count == 0
      @tags = strip_tags(fetch.css('a.post-tag')) 
    else 
      taglist = []
      @pages.each do |page_num|
        #http://careers.stackoverflow.com/jobs?searchTerm=software+engineer&location=seattle&range=20&distanceUnits=Miles&sort=p&pg=2
        #fetch = Nokogiri::HTML(open("http://careers.stackoverflow.com/jobs?location=#{@city}&range=#{@range}&distanceUnits=Miles"))
        fetch = Nokogiri::HTML(open("http://careers.stackoverflow.com/jobs?searchTerm=#{@keyword.strip}&location=#{@city}&range=#{@range}&distanceUnits=Miles&sort=p&pg=#{page_num}"))
        @tags = sort_by_occurance((taglist << strip_tags(fetch.css('a.post-tag'))).flatten!)
      end
    end
  end

  
  if @cs == "indeed" || "all"
    @indeed_url = "http://www.indeed.com/jobs?q=#{@keyword}&l=#{@city}&radius=#{@range}&sort=date"
    fetch = Nokogiri::HTML(open(@indeed_url))
    @indeed_info = "#{fetch.css('div#searchCount').text.split(' ').last} jobs found"
  end
  
  if @cs == "dice" || "all"
    @dice_url = "https://www.dice.com/jobs/q-#{@keyword}-l-#{@city}-radius-#{@range}-jobs.html"
    fetch = Nokogiri::HTML(open(@dice_url))
    if fetch.css('h4.posiCount').children.count > 0
      @dice_info = "#{fetch.css('h4.posiCount').children[2].text} jobs found"
    else 
      @dice_info = "0 Jobs found"
    end
    
  end
  
  erb :index
end



post '/results' do 
  redirect to("/all/#{params[:city].gsub(/[^0-9a-z]/i, '+')}/#{params[:range].gsub(/\D/, "")}/#{params[:keyword].gsub(/[^0-9a-z]/i, '+')}")
end



############
# Helpers #
##########

#Strip all tag test from a nodeset of elements (used for stackoverflow page)
def strip_tags(tag_nodeset)
  ret = []
  tag_nodeset.each { |node| ret << node.text}
  return ret
  #return sort_by_occurance(ret)
end

#Sort tagset(Array) by highest occurance
def sort_by_occurance(tagset)
  ret = {}
  tagset.group_by(&:itself).values.each {|sk| ret[sk.first] = sk.count }
  return ret.sort_by {|_key, value| value}.reverse.to_h
end
