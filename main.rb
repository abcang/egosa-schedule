# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv'
require 'twitter'
require_relative './lib/slack_poster'

module EgosaSchedule
  class << self
    def run(envfile)
      Dotenv.load(envfile) if envfile

      lack_env = check_env(ENV.keys)
      unless lack_env.empty?
        STDERR.puts 'Not enough vnvironment variable'
        lack_env.each do |env|
          STDERR.puts "  #{env}"
        end
        exit 1
      end

      start_egosa
    end

    private

    def check_env(env_list)
      target_env = %w(
        CONSUMER_KEY
        CONSUMER_SECRET
        OAUTH_TOKEN
        OAUTH_TOKEN_SECRET
        WEBHOOK_URL
      )
      target_env - env_list
    end

    def client
      @client ||= Twitter::REST::Client.new do |config|
        config.consumer_key        = ENV['CONSUMER_KEY']
        config.consumer_secret     = ENV['CONSUMER_SECRET']
        config.access_token        = ENV['OAUTH_TOKEN']
        config.access_token_secret = ENV['OAUTH_TOKEN_SECRET']
      end
    end

    def poster
      @poster ||= SlackPoster.new(ENV['WEBHOOK_URL'])
    end

    def match?(status)
      return false if status.retweet?

      text = CGI.unescapeHTML(status.full_text).tr('０-９ａ-ｚＡ-Ｚ：', '0-9a-zA-Z:')
      text.match?(%r!(\d:\d\d)|(\d/\d{1,2})|(\d[時じ日(にち)])|(配信)|(延期)!)
    end

    def start_egosa
      loop do
        sleep 30 if @since_id

        options = { count: 100 }
        options[:since_id] = @since_id if @since_id
        statuses = client.list_timeline('abcang1015', 'egosa-schedule', options)
        next if statuses.empty?

        puts "[#{Time.now.localtime('+09:00').strftime('%F %T')}]new statuses: #{statuses.size}"

        before_since_id = @since_id
        @since_id = statuses.first.id
        next unless before_since_id

        statuses.each do |status|
          poster.post_status(status) if match?(status)
        end
      end
    end
  end
end

EgosaSchedule.run ARGV[0]
