class DBot
    module Feature
        class Help < DBot::CommandSet
            def initialize(commands_obj)
                @commands_obj = commands_obj
                table = DBot::CommandTable.new
                table.add("help", "You really should know by now.", method(:show_help))

                super(table)
            end

            def show_help(event)
                nick = event.from

                if event.command_args.empty?
                    event.irc.msg(nick, "I am a dbot. I support these features:")
                    @commands_obj.commandsets.each do |commandset|
                        event.irc.msg(nick, [commandset.commandset_name, commandset.commands.collect { |x| (DBot::Config.leader) + x }.join(", ")].join(": "))
                    end
                    event.irc.msg(nick, "say, '#{DBot::Config.leader}help <command>' for more information on specific commands.")
                else
                    command = event.command_args[0].sub(/^#{Regexp.quote(DBot::Config.leader)}/, '')
                    @commands_obj.commandsets.each do |commandset|
                        if commandset.handles_command?(command)
                            event.irc.msg(nick, [commandset.commandset_name, DBot::Config.leader + command, commandset.help(command)].join(": "))
                        end
                    end
                end
            end
        end
    end
end

DBot::Commands.register_commandset(DBot::Feature::Help)
