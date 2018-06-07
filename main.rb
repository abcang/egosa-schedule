# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv'
require 'twitter'
require_relative './lib/slack_poster'

STDOUT.sync = true

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

    def filtered_full_text(status)
      original_full_text = status.attrs[:full_text]
      unescaped_full_text = ''
      start_position = 0

      (status.media + status.uris + status.user_mentions + status.hashtags).map(&:indices).uniq.sort_by { |s, _| s }.each do |s, e|
        unescaped_full_text = unescaped_full_text + original_full_text[start_position...s]
        start_position = e
      end
      unescaped_full_text = unescaped_full_text + original_full_text[start_position...original_full_text.length]

      CGI.unescapeHTML(unescaped_full_text)
    end

    def regexp
      @regexp ||= Regexp.new(%w[
        (?<!\d)\d{4}(\s|に|から|〜|$)
        \d:\d\d
        \d/\d\d?
        \d(時|じ|日|にち|分|ふん)(?!間)
        延期
        中止
        (休|やす)み(?!なさい)
        変更
        ゲリラ
      ].join('|'))
    end

    def match?(status)
      return false if status.retweet?

      text = filtered_full_text(status).tr('０-９ａ-ｚＡ-Ｚ：　', '0-9a-zA-Z: ')
      text.match?(regexp)
    end

    def start_egosa
      loop do
        sleep 30 if @since_id

        options = { count: 100, tweet_mode: 'extended' }
        options[:since_id] = @since_id if @since_id
        statuses = client.list_timeline(ENV.fetch('LIST_USER'), ENV.fetch('LIST_NAME'), options)
        next if statuses.empty?

        puts "[#{Time.now.localtime('+09:00').strftime('%F %T')}]new statuses: #{statuses.size}"

        before_since_id = @since_id
        @since_id = statuses.first.id
        next unless before_since_id

        statuses.reverse_each do |status|
          poster.post_status(status) if match?(status)
        end
      end
    end
  end
end

EgosaSchedule.run ARGV[0]
