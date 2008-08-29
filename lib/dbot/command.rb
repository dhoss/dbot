require 'delegate'

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

        def commandsets
            @commandsets.dup
        end

        def handle_command(event) 
            @commandsets.collect do |commandset| 
                if commandset.handles? event 
                    commandset.handle event
                else
                    nil
                end
            end
        end

        def init_commandsets
            @@commandset_classes.each do |commandset|
                @commandsets.push(commandset.new(@config, self))
            end
        end
    end
    
    class CommandSet

        attr_reader :handle_everything

        def initialize(config, valid_commands=DBot::CommandTable.new)
            @config = config
            @valid_commands = valid_commands
            @handle_everything ||= false
        end

        def handles_command?(string_or_event)
            case string_or_event
            when String
                @valid_commands.has_key?(string_or_event)
            when DBot::Event::Command
                string_or_event.has_command? ?
                    @valid_commands.has_key?(string_or_event.command) :
                    false
            end
        end

        def handles?(string_or_event)
            return handles_command?(string_or_event) || @handle_everything
        end

        def commandset_name
            self.class.name.sub(/^DBot::Feature::/, '')
        end

        def commands
            @valid_commands.keys
        end

        def help(string)
            @valid_commands[string].help
        end

        def handle(event)
            raise "This command does not handle #{event.command}" unless self.handles?(event)
            @valid_commands.call(event)
        end
    end

    class Command
        attr :method, true
        attr_reader :help

        def initialize(help_text, my_method=nil, &block)
            if my_method
                @method = my_method
            elsif block_given?
                @method = block.to_proc
            else
                raise "No method"
            end

            self.help = help_text
        end

        def call(*args)
            self.method.call(*args)
        end

        def help=(help_text)
            @help = help_text
            @help.freeze
        end

        def bind(klass)
            unless self.method.respond_to?(:call)
                self.method = klass.method(method)
            end
        end
    end

    class CommandTable < DelegateClass(Hash)
        def initialize
            @table = { }
            super(@table)
            yield self if block_given?
        end

        def add(command, help_text, method = nil, &block)
            if block_given?
                @table[command] = Command.new(help_text, block.to_proc)
            elsif method
                @table[command] = Command.new(help_text, method)
            else
                raise "No method to execute"
            end
        end

        def call(event)
            if event.has_command?
                self[event.command].call(event)
            else
                raise "No command for event"
            end
        end

        def bind(klass)
            @table.values.each do |x|
                x.bind(klass)
            end
        end
    end
end
