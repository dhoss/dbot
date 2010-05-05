class DBot
    module Feature
        class Convert < DBot::FeatureSet
            def initialize(commands_obj)
                @commands_obj = commands_obj

                table = DBot::CommandTable.new do |table|
                    table.add("ftoc", "fahrenheit to celsius", method(:ftoc))
                    table.add("ctof", "celsius to fahrenheit", method(:ctof))
                end

                super(table)
            end

            def ftoc(event)
                temp = event.command_args.first
                temp = temp.sub(/\s*F\s*$/, '').to_f
                event.reply("#{temp}F = #{((5.0/9.0) * (temp - 32)).to_s}C")
            end
            
            def ctof(event)
                temp = event.command_args.first
                temp = temp.sub(/\s*C\s*$/, '').to_f
                event.reply("#{temp}C = #{(((9.0/5.0) * temp) + 32).to_s}F")
            end
        end
    end
end

DBot::Features.register_commandset(DBot::Feature::Convert)
