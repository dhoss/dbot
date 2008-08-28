class DBot
    module Feature
        class Ping < DBot::CommandSet

            def initialize(config)
                super(config, { "ping" => [ :ping, "Ping the bot to see if it's still listening" ] })
            end

            def ping(irc, out, tokens, event_args)
                irc.msg(out, "Johnny five is alive!")
            end
        end
    end
end

DBot::Commands.register_commandset(DBot::Feature::Ping)
