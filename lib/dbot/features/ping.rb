class DBot
    module Feature
        class Ping < DBot::FeatureSet

            def initialize(commands_obj)
                table = DBot::CommandTable.new
                table.add("ping", "Ping the bot to see if it's still listening", method(:ping))

                super(table)
            end

            def ping(command)
                command.irc.msg(command.out, "Johnny five is alive!")
            end
        end
    end
end

DBot::Features.register_commandset(DBot::Feature::Ping)
