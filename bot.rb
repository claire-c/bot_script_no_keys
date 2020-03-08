require 'twitter'
require 'nokogiri'
require 'open-uri'

GOOD_AIR_QUALITY_TWEETS = [
    "At #{Time.now.strftime("%k:%M")}, I looked at air pollution monitoring sites across Edinburgh. Good news! Air pollution levels are low across the city so you can breathe easy.",
    "Looks like air quality is good, I just checked Edinburgh's monitoring stations at #{Time.now.strftime("%k:%M")} and all of them are returning a low level of air pollution.",
    "Edinburgh's air gets the all clear. At #{Time.now.strftime("%k:%M")}, all of the city's air quality monitoring stations are telling me that the air pollution levels are low.",
    "I am just a bot, but I can tell you that Edinburgh's air quality is good. I've checked the monitoring stations across the city at #{Time.now.strftime("%k:%M")} and they are giving me low air pollution levels.",
    "At #{Time.now.strftime("%k:%M")}, Edinburgh's air pollution index is currently LOW. This means that the air quality is not hazardous and your lungs can breathe a sigh of relief.",
    "Air pollution levels across Edinburgh are currently low. I checked at #{Time.now.strftime("%k:%M")} and will look again in an hour."
]

config = {
    consumer_key:        'consumer key here',
    consumer_secret:     'consumer secret here',
    access_token:        'access token here',
    access_token_secret: 'access token secret here'
}
twitter = Twitter::REST::Client.new(config)

class Scraper
    def perform
      scrape_urls(query_strings)
    end

    private

    def scrape_urls(query_strings)
      scraper_results = []
      query_strings.each do |string|
        doc = Nokogiri::HTML(open(
                               "http://www.scottishairquality.scot/latest/site-info?site_id=ED#{string}"
                             ))
        location = doc.xpath('//h1').text
        rating = doc.xpath('//span')[3].text

        scraper_results << [location, rating]
      end
      scraper_results
    end

    def query_strings
      %w[012 10 11 1 3 5 8 9 NS]
    end
end

class PrepareTweets
    def perform(results)
        tweet_content(results)
    end

    private

    def tweet_content(results)
        tweets = []
        results.each do |result|
          tweets << "Heads up! #{result[0]} air pollution levels are #{result[1]}, which is not great news for your lungs. Avoid if you can. I checked this measurement at #{Time.now.strftime("%k:%M")}" if ["MODERATE", "HIGH", "VERY HIGH"].include?(result[1])
        end
        format_tweets(tweets)
    end

    def format_tweets(tweets)
        tweets.empty? ? tweets << GOOD_AIR_QUALITY_TWEETS.sample : tweets
    end
end

class PostToTwitter
    def perform(client)
      results = scrape
      tweets = format(results)
      send_tweets(tweets, client)
    end

    private

    def scrape
      job = Scraper.new
      job.perform
    end

    def format(results)
      job = PrepareTweets.new
      job.perform(results)
    end

    def send_tweets(tweets, client)
      puts "sending these tweets:"
      puts tweets
      tweets.each do |tweet|
        client.update(tweet)
      end
    end
end

post = PostToTwitter.new
post.perform(twitter)
