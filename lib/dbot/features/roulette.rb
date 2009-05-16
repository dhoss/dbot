class DBot
    module Feature
        class Roulette < DBot::FeatureSet
            class Gun
                PASS     = 0
                KICK     = 1
                KICK_ALL = 2
                TIMEOUT  = 600

                attr_accessor :barrel

                def initialize(barrel_size=15, super_kick_seed=4)
                    @barrel_size = barrel_size
                    @barrel  = [ ]

                    self.load
                end

                def load
                    @last_pull = Time.now
                    @barrel = [0] * rand(@barrel_size).floor
                    @barrel[rand(@barrel.length)] = 1
                end

                def pull!

                    if Time.now - TIMEOUT > @last_pull
                        self.load
                    end

                    if @barrel.shift == 1
                        self.load
                        return KICK
                    elsif @barrel.length == 0
                        self.load
                        return KICK
                    else
                        return PASS
                    end
                end
            end

            def initialize(commands_obj)
                table = DBot::CommandTable.new
                table.add("rr", "Spin the barrel and be a man", method(:rr))

                @gun = Gun.new

                super(table)
            end

            def rr(event)
                if DBot::UserState.state?(event.out, event.dbot.me, :op)
                    case @gun.pull!
                    when Gun::KICK
                        event.irc.kick(event.out, event.from, "*BLAM*")
                    when Gun::PASS
                        event.reply("#{event.from}: click.")
                    end
                else
                    p "here"
                    event.reply("This command only works when I'm opped.")
                end
            end
        end
    end
end

DBot::Features.register_commandset(DBot::Feature::Roulette)
