class DBot
    module Feature
        class RequestJoin < DBot::FeatureSet

            def initialize(commands_obj)
                table = DBot::CommandTable.new
                table.add("join", "Request the bot join a channel.", method(:join))

                super(table)
            end

            def join(event)
                channel = event.tokens[1]

                if !channel or channel =~ /^\w/
                    event.reply("I'm afraid I can't do that, dave.")
                else
                    event.irc.join(channel)
                end
            end
        end
    end
end

DBot::Features.register_commandset(DBot::Feature::RequestJoin)
