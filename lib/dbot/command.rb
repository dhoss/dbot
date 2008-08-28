class DBot
    class Commands

        @@commandset_classes = []

        def initialize(config, irc)
            @commandsets = []
            @config = config
            @irc = irc
        end

        def self.register_commandset(commandset)
            @@commandset_classes.push(commandset)
        end

        def handle_command(command_str, *args)
            leader = Regexp.quote(@config.leader || '!')

            command_found = false

            if command_str =~ /^#{leader}/
                command_str.sub!(/^#{leader}/, '')
                command_found = true
            end
            
            if command_found
                @commandsets.collect do |commandset|
                    if commandset.handles? command_str
                        commandset.handle(@irc, command_str, *args)
                    else
                        nil
                    end
                end
            else
                @commandsets.find_all { |c| c.handle_everything }.collect do |commandset|
                    commandset.handle(@irc, :text, *args)
                end
            end.compact # XXX yes, i'm evil.
        end

        def init_commandsets
            @@commandset_classes.each do |commandset|
                @commandsets.push(commandset.new(@config))
            end
        end
    end
    
    class CommandSet

        attr_reader :handle_everything

        def initialize(config, valid_commands=[])
            @config = config
            @valid_commands = valid_commands
            @handle_everything ||= false
        end

        def handles?(string)
            @valid_commands.has_key?(string)
        end

        def help(string)
            @valid_commands[string][1]
        end

        def handle(irc, command_str, *args)
            raise "This command does not handle #{command_str}" unless self.handles?(command_str)
            self.send(command_str, irc, *args)
        end
    end
end
