class DBot
    module Feature
        class Help < DBot::CommandSet
            def initialize(config, commands_obj)
                @config = config
                @commands_obj = commands_obj
                super(config, { "help" => [ method(:show_help), "" ] })
            end

            def show_help(irc, out, tokens, event_args)
                nick = event_args[:nick]

                if tokens.empty?
                    irc.msg(nick, "I am a dbot. I support these features:")
                    @commands_obj.commandsets.each do |commandset|
                        irc.msg(nick, [commandset.commandset_name, commandset.commands.collect { |x| (@config.leader) + x }].join(": "))
                    end
                    irc.msg(nick, "say, '#{@config.leader}help <command>' for more information on specific commands.")
                else
                    command = tokens[0].sub(/^#{Regexp.quote(@config.leader)}/, '')
                    @commands_obj.commandsets.each do |commandset|
                        if commandset.handles?(command)
                            irc.msg(nick, [commandset.commandset_name, tokens[0], commandset.help(command)].join(": "))
                        end
                    end
                end
            end
        end
    end
end

DBot::Commands.register_commandset(DBot::Feature::Help)
