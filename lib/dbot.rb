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

$:.shift

class DBot
    def initialize(config_path)
        DBot::Config.load_file(config_path)
        load_features
    end

    def load_features
        features = DBot::Config.features || []

        # FIXME this should probably change to "."
        $:.unshift(File.dirname(File.expand_path(__FILE__)))
        features.each do |feature|
            require feature
        end
        $:.shift
    end

    def run
        @bot = DBot::BaseBot.new

        if DBot::Config.daemonize
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
        @bot.irc_loop
    end
end

