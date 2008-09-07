begin
    require 'rubygems'
    gem 'net-yail'
rescue LoadError
end

require 'net/yail'
require 'net/yail/IRCBot'

class DBot
    class BaseBot < IRCBot
        def initialize
            super(DBot::Config.yail_args)
        end

        def add_custom_handlers
            @commands = DBot::Features.new(@irc)
            @commands.init_commandsets
            @irc.prepend_handler :incoming_msg, method(:handle_incoming)
        end

        private

        def handle_incoming(hostinfo, nick, channel, text)
            event = DBot::Event::Command.new(@irc, hostinfo, nick, channel, text)
            @commands.handle_command(event)
        end

        def welcome(text, args)
            welcome_text = DBot::Config.welcome_text

            @channels.each do |channel|
                @irc.join(channel)
                msg(channel, welcome_text) if welcome_text
            end
        end
    end
end
