begin
    require 'rubygems'
    gem 'net-yail'
rescue LoadError => e
end

require 'net/yail'

$:.unshift(File.dirname(File.expand_path(__FILE__)))

require 'dbot/config'
require 'dbot/command'
require 'dbot/event'
require 'dbot/basebot'


class DBot
    def initialize(config_path)
        @config = DBot::Config.new(config_path)
        load_features
    end

    def load_features
        features = @config.features || []

        features.each do |feature|
            require feature
        end
    end

    def run
        @bot = DBot::BaseBot.new(@config)

        if @config.daemonize
            fork do
                $stdout.reopen('/dev/null')
                $stderr.reopen('/dev/null')
                $stdin.reopen('/dev/null')

                Process.setsid

                bot_loop
            end
        else
            bot_loop
        end
    end

    def bot_loop
        @bot.connect_socket
        @bot.start_listening
        @bot.irc_loop
    end
end

