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
  
  # if @cs == "51job"
  #   @fiftyone_url = "http://search.51job.com/jobsearch/search_result.php?fromJs=1&jobarea=010000%2C030200%2C020000%2C040000%2C01&funtype=0000&industrytype=00&keyword=software%20engineer&keywordtype=1&lang=e&stype=1&postchannel=0000&fromType=1"
  #   #url_parse = open(@fiftyone_url)
  #   open("temp_51.txt", "wb") do |file|
  #     open(@fiftyone_url) do |uri|
  #       file.write(uri.read)
  #     end
  #   end
    
  #   data = File.read('temp_51.txt')
  #   fetch = Nokogiri::HTML(data)
  #   @job_count = fetch.at_css("input[name='jobid_count']")['value']
    
  #   #jobs_on_page = fetch.css('.jobname')
  #   num_pages = fetch.at_css('.searchPageNav').children.children.count - 2
    
  #   @job_links = []
    
  #   num_pages.times do |inum|
      
  #     page_num = inum + 1
  #     page_url = "http://search.51job.com/jobsearch/search_result.php?fromJs=1&jobarea=010000%2C030200%2C020000%2C040000%2C01&district=000000&funtype=0000&industrytype=00&issuedate=9&providesalary=99&keyword=software%20engineer&keywordtype=1&curr_page=#{page_num}&lang=e&stype=1&postchannel=0000&workyear=99&cotype=99&degreefrom=99&jobterm=01&companysize=99&lonlat=0%2C0&radius=-1&ord_field=0&list_type=0&fromType=14&dibiaoid=-1"
  #     open("temp_51.txt", "wb") do |file|
  #       open(page_url) do |uri|
  #         file.write(uri.read)
  #       end
  #     end
      
  #     data = File.read('temp_51.txt')
  #     fetch = Nokogiri::HTML(data)
  #     @job_links << jobs_on_page = fetch.css('.jobname')
      
  #   end
    
  # end
  
  erb :index
end

get '/china' do 
  @cs = 'china'
  erb :index
end

get '/china/:keyword' do 
  @cs = 'china'
  keyword = params[:keyword].gsub(' ', '%20').gsub('+','%20')
  @keyword = keyword.gsub('%20', ' ')
  @fiftyone_url = "http://search.51job.com/jobsearch/search_result.php?fromJs=1&jobarea=010000%2C030200%2C020000%2C040000%2C01&funtype=0000&industrytype=00&keyword=#{keyword}&keywordtype=1&lang=e&stype=1&postchannel=0000&fromType=1"
    #url_parse = open(@fiftyone_url)
    open("temp_51.txt", "wb") do |file|
      open(@fiftyone_url) do |uri|
         file.write(uri.read)
      end
    end
    
    data = File.read('temp_51.txt')
    fetch = Nokogiri::HTML(data)
    @job_count = fetch.at_css("input[name='jobid_count']")['value']
    
    #jobs_on_page = fetch.css('.jobname')
    num_pages = fetch.at_css('.searchPageNav').children.children.count - 2
    
    @job_links = []
    
    num_pages.times do |inum|
      
      page_num = inum + 1
      page_url = "http://search.51job.com/jobsearch/search_result.php?fromJs=1&jobarea=010000%2C030200%2C020000%2C040000%2C01&district=000000&funtype=0000&industrytype=00&issuedate=9&providesalary=99&keyword=software%20engineer&keywordtype=1&curr_page=#{page_num}&lang=e&stype=1&postchannel=0000&workyear=99&cotype=99&degreefrom=99&jobterm=01&companysize=99&lonlat=0%2C0&radius=-1&ord_field=0&list_type=0&fromType=14&dibiaoid=-1"
      open("temp_51.txt", "wb") do |file|
        open(page_url) do |uri|
           file.write(uri.read)
        end
      end
      
      data = File.read('temp_51.txt')
      fetch = Nokogiri::HTML(data)
      jobs_on_page = fetch.css('.jobname')
      jobs_on_page.each { |job| @job_links << job['title'] if job['title'] }
      
    end
    
    erb :index
end


post '/results' do 
  puts "!!!!!"
  puts params[:city]
  if params[:city] == 'china'
    redirect to("/china/#{params[:keyword].gsub(/[^0-9a-z]/i, '+')}")
  else 
    redirect to("/all/#{params[:city].gsub(/[^0-9a-z]/i, '+')}/#{params[:range].gsub(/\D/, "")}/#{params[:keyword].gsub(/[^0-9a-z]/i, '+')}")
  end

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
