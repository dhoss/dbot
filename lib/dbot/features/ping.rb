class DBot
    module Feature
        class Ping < DBot::CommandSet

            def initialize(config, commands_obj)
                table = DBot::CommandTable.new
                table.add("ping", "Ping the bot to see if it's still listening", method(:ping))

                super(config, table)
            end

            def ping(command)
                command.irc.msg(command.out, "Johnny five is alive!")
            end
        end
    end
end

DBot::Commands.register_commandset(DBot::Feature::Ping)
