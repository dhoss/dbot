begin
    require 'rubygems'
    gem 'Ruby-IRC'
rescue LoadError
end

require 'IRC'
require 'IRCEvent'

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

    class BaseBot 

        attr_reader :irc
        attr_reader :me
        attr_reader :server
        attr_reader :port
        attr_reader :realname

        def initialize
            @me         = DBot::Config["nicknames"][0]
            @server     = DBot::Config["server"]
            @port       = DBot::Config["port"] || "6667"
            @realname   = DBot::Config["realname"]
            @channels   = DBot::Config["channels"]
            @irc        = IRC.new(@me, @server, @port, @realname)
            
            add_custom_handlers
        end

        def add_custom_handlers
            @features = DBot::Features.new(@irc)
            @features.init_eventsets
            @features.init_commandsets

            IRCEvent.add_callback('endofmotd') do |event| 
                nickserv_identify
                @channels.each { |channel| @irc.add_channel(channel) } 
                welcome
            end

            IRCEvent.add_callback('privmsg', &method(:handle_incoming_msg))
            IRCEvent.add_callback('kick',    &method(:handle_incoming_kick))
            IRCEvent.add_callback('part',    &method(:handle_incoming_part))
            IRCEvent.add_callback('mode',    &method(:handle_incoming_mode))
            IRCEvent.add_callback('quit',    &method(:handle_incoming_quit))
        end

        private

        def handle_incoming_quit(event)
            UserState.delete_nick(event.from)
        end

        def handle_incoming_kick(event)
            if event.target == @me
                UserState.delete_channel(event.channel)
            else
                UserState.delete_nick_from_channel(event.channel, event.target)
            end
        end

        def handle_incoming_part(event)
            UserState.delete_nick_from_channel(event.channel, event.from)
        end

        def handle_incoming_mode(event)

            return unless event.target

            # FIXME for now, the event API can't handle this
            # just try to keep track of what users have what.
            
            targets = event.target.split(/\s/)
            op = true # true means "add", false means "remove"

            event.mode.each_char do |c|
                case c
                when "+"
                    op = true
                when "-"
                    op = false
                when "o"
                    UserState.set_state(event.channel, targets.shift, :op, op)
                when "h"
                    UserState.set_state(event.channel, targets.shift, :halfop, op)
                when "v"
                    UserState.set_state(event.channel, targets.shift, :voice, op)
                when "b"
                    UserState.set_state(event.channel, targets.shift, :banned, op)
                end
            end
        end

        def handle_incoming_msg(event)
            if event.message[0] == 1
                handle_incoming_ctcp(event)
            end

            dbot_event = DBot::Event::Command.new(self, event.hostmask, event.from, event.channel, event.message)
            @features.handle_command(dbot_event)
        end

        def handle_incoming_ctcp(event)
            message = event.message[1..-2]
            if message == "VERSION"
                @irc.send_ctcpreply(event.from, "VERSION", "irssi v0.8.12 - running on Linux x86_64")
            end
        end

        def handle_incoming(line)
            @features.handle_event(DBot::Event::Raw.new(@irc, line))
            return true
        end

        def nickserv_identify
            if DBot::Config.nickserv_password
                @irc.send_message("NickServ", "identify #{DBot::Config.nickserv_password}")
            end
        end

        def welcome
            welcome_text = DBot::Config.welcome_text

            @channels.each do |channel|
                @irc.send_message(channel, welcome_text) if welcome_text
            end

        end
    end
end
