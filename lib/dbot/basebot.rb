begin
    require 'rubygems'
    gem 'net-yail'
rescue LoadError
end

require 'net/yail'
require 'net/yail/IRCBot'

class DBot
    class BaseBot < IRCBot
        def initialize(config)
            raise "Cannot construct bot; invalid args" if config.nil?
            @config = config
            
            super(@config.yail_args)
        end

        def add_custom_handlers
            @commands = DBot::Commands.new(@config, @irc)
            @commands.init_commandsets
            @irc.prepend_handler :incoming_msg, method(:handle_incoming)
        end

        private

        def handle_incoming(hostinfo, nick, channel, text)
            out = case channel
                  when @irc.me
                      nick
                  else
                      channel 
                  end

            tokens = text.split(/\s+/)
            command = tokens.shift

            @commands.handle_command(
                command, 
                out, 
                tokens, 
                { 
                    :hostinfo => hostinfo,
                    :nick     => nick,
                    :channel  => channel,
                    :text     => text
                }
            )
        end

        def welcome(text, args)
            welcome_text = @config.welcome_text

            @channels.each do |channel|
                @irc.join(channel)
                msg(channel, welcome_text) if welcome_text
            end
        end
    end
end
