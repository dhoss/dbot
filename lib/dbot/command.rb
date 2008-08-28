class DBot
    module Commands
        @commands = []

        def self.register_commandset(commandset)
            @commandsets.push(commandset)
        end

        def self.handle_command(irc, command_str, *args)
            @commands.collect do |commandset|
                if commandset.handles? command_str
                    commandset.handle(irc, command_str, *args)
                else
                    nil
                end
            end.reject { |x| x.nil? }
        end
    end
    
    class CommandSet
        def initialize(valid_commands, leader="!")
            @valid_commands = valid_commands || []
            @leader = leader
        end

        def handles?(string)
            @valid_commands.include?(strip_leader(string))
        end

        def handle(irc, command_str, *args)
            raise "This command does not handle #{command_str}" unless self.handles?(command_str)
            self.send(strip_leader(string).to_sym, *args)
        end

        protected

        def strip_leader(string)
            if string[0..(@leader.length-1)] == @leader
                string[1..-1]
            else
                string.dup
            end
        end
    end
end
