begin
    require 'rubygems'
rescue LoadError
end

require 'talkfilters'

class DBot
    class RandomText
        attr_reader   :filename
        attr_accessor :lines

        def initialize(filename="shaks12.txt")
            @filename = filename
            @lines = File.open(filename).readlines.collect { |x| x.strip.chomp }
            @lines.delete_if { |x| x.empty? }
        end

        def fetch(extra_lines=1)
            lineno = rand(@lines.length - extra_lines)
            return @lines[lineno..(lineno+extra_lines)].collect { |x| x.strip } 
        end

        def filter(filter_name)
            if !filter_name.kind_of? Array
                filter_name = [ filter_name ]
            end

            filter_name = filter_name[0..3]

            output = fetch
            filter_name.each do |filter|
                if TalkFilters.list_filters.include? filter
                    output.collect! do |line|
                        TalkFilters.translate(filter, line).strip
                    end
                end
            end

            return output
        end

        def filter_list
            return TalkFilters.list_filters
        end
    end
end

class DBot
    module Feature
        class Snack < DBot::FeatureSet
            def initialize(commands_obj)
                @commands_obj = commands_obj

                @rt = RandomText.new

                table = DBot::CommandTable.new do |table|
                    table.add("snack", "Monkeys writing shakespeare?", method(:snack))
                    table.add("tastysnack", "Like snack, but it's specific! !tastysnack <snack>.", method(:tastysnack))
                    table.add("listsnacks", "List the types of snacks you can feed!", method(:listsnacks))
                end

                super(table)
            end

            def snack(event)
                event.reply(@rt.fetch)
            end

            def tastysnack(event)
                if event.command_args.empty?
                    event.reply("Please provide me with a snack type. See !listsnacks")
                else
                    event.reply(@rt.filter(event.command_args))
                end
            end

            def listsnacks(event)
                event.reply("I have these snacks: "+@rt.filter_list.join(" "))
            end
        end
    end
end

DBot::Features.register_commandset(DBot::Feature::Snack)
