begin
    require 'rubygems'
    gem 'net-yail'
rescue LoadError
end

require 'net/yail'
require 'net/yail/IRCBot'

class DBot
    class UserState 
        @@state = { }

        def self.set_state(channel, nick, state, value)
            @@state[channel] ||= { }

            this_target = @@state[channel][nick] ||= { }
            this_target[state] = value
        end

        def self.delete_channel(channel)
            @@state.delete(channel)
        end

        def self.delete_nick(nick)
            @@state.each_key do |key|
                @@state[key].delete(nick)
            end
        end

        def self.delete_nick_from_channel(channel, nick)
            @@state[channel] ||= []
            @@state[channel].delete(nick)
        end

        def self.state?(channel, nick, state)
            return nil unless (
                @@state[channel] and
                @@state[channel][nick] and
                @@state[channel][nick].has_key?(state)
            )

            return @@state[channel][nick][state]
        end

        # mostly a debugging tool - dump the channel states
        def self.channel_state(channel)
            return @@state[channel] || { }
        end
    end

    class BaseBot < IRCBot
        def initialize
            super(DBot::Config.yail_args)
        end

        def add_custom_handlers
            @commands = DBot::Features.new(@irc)
            @commands.init_commandsets
            @irc.prepend_handler :incoming_msg, method(:handle_incoming)
            @irc.prepend_handler :incoming_mode, method(:handle_incoming_mode)
            @irc.prepend_handler :incoming_part, method(:handle_incoming_part)
            @irc.prepend_handler :incoming_kick, method(:handle_incoming_kick)
            @irc.prepend_handler :incoming_quit, method(:handle_incoming_quit)
        end

        private

        def handle_incoming_quit(hostinfo, quitter, quit_text)
            UserState.delete_nick(quitter)
        end

        def handle_incoming_kick(hostinfo, kicker, channel, nick, text)
            if nick == @irc.me
                UserState.delete_channel(channel)
            else
                UserState.delete_nick_from_channel(channel, nick)
            end
        end

        def handle_incoming_part(hostinfo, nick, _,  channel)
            UserState.delete_nick_from_channel(channel, nick)
        end

        def handle_incoming_mode(hostinfo, setter, channel, modes, target)

            return unless target

            # FIXME for now, the event API can't handle this
            # just try to keep track of what users have what.
            
            targets = target.split(/\s/)
            op = true # true means "add", false means "remove"

            modes.each_char do |c|
                case c
                when "+"
                    op = true
                when "-"
                    op = false
                when "o"
                    UserState.set_state(channel, targets.shift, :op, op)
                when "h"
                    UserState.set_state(channel, targets.shift, :halfop, op)
                when "v"
                    UserState.set_state(channel, targets.shift, :voice, op)
                when "b"
                    UserState.set_state(channel, targets.shift, :banned, op)
                end
            end
        end

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
