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
            @irc        = IRC.new(@me, @server, @port, @realname)
            
            IRCEvent.add_callback('endofmotd') { |event| STDERR.puts "here"; DBot::Config["channels"].each { |channel| @irc.add_channel(channel) } }
            add_custom_handlers
        end

        def add_custom_handlers
            @features = DBot::Features.new(@irc)
            @features.init_eventsets
            @features.init_commandsets

            IRCEvent.add_callback('privmsg', &method(:handle_incoming_msg))
#             IRCEvent.add_callback('kick',    &method(:handle_incoming_kick))
#             IRCEvent.add_callback('part',    &method(:handle_incoming_part))
#             IRCEvent.add_callback('mode',    &method(:handle_incoming_mode))
#             IRCEvent.add_callback('ctcp',    &method(:handle_incoming_ctcp))
#             IRCEvent.add_callback('mode',    &method(:handle_incoming_mode))
#             IRCEvent.add_callback('quit',    &method(:handle_incoming_quit))

#             @irc.prepend_handler :incoming_msg,  method(:handle_incoming_msg)
#             @irc.prepend_handler :incoming_mode, method(:handle_incoming_mode)
#             @irc.prepend_handler :incoming_part, method(:handle_incoming_part)
#             @irc.prepend_handler :incoming_kick, method(:handle_incoming_kick)
#             @irc.prepend_handler :incoming_quit, method(:handle_incoming_quit)
#             @irc.prepend_handler :incoming_ctcp, method(:handle_incoming_ctcp)
#             @irc.prepend_handler :incoming_any,  method(:handle_incoming)
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

        def handle_incoming_msg(event)
            event = DBot::Event::Command.new(self, event.hostmask, event.from, event.channel, event.message)
            @features.handle_command(event)
        end

        def handle_incoming_ctcp(hostinfo, nick, target, name)
            if name == "VERSION"
                @irc.ctcpreply(nick, "irssi v0.8.12 - running on Linux x86_64")
            end
        end

        def handle_incoming(line)
            @features.handle_event(DBot::Event::Raw.new(@irc, line))
            return true
        end
    end
end
