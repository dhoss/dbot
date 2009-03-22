class DBot
    class Event
        attr_reader :hostinfo
        attr_reader :from
        attr_reader :target
        attr_reader :text
        attr_reader :irc
        attr_reader :config
        attr_reader :return_path

        def initialize(*args)
            args.collect! { |x| x.dup }
            args.each { |x| x.freeze }
            @irc, @hostinfo, @from, @target, @text = args

            @return_path = case @target
                           when @irc.me
                               @from
                           else
                               @target
                           end
        end

        def tokens
            @text.split(/\s+/)
        end

        def reply(string)
            @irc.msg(@return_path, string)
        end

        alias out return_path
    end

    class Event::Raw 
        attr_reader :text
        attr_reader :irc
        
        def initialize(irc, text)
            @irc  = irc
            @text = text
            @text.freeze
        end
    end

    class Event::Command < Event
        attr_reader :command_args
        attr_reader :command

        def initialize(*args)
            super(*args)

            toks = self.tokens

            command_str = toks[0]
            command_found = false

            leader = Regexp.quote(DBot::Config.leader)

            if command_str =~ /^#{leader}/
                command_str.sub!(/^#{leader}/, '')
                command_found = true
                @command = command_str
                @command.freeze
                toks.shift
            else
                @command = nil
            end

            @command_found = command_found

            @command_args = toks

            @command_args.freeze
            @command_args.each { |x| x.freeze }
        end

        def has_command?
            @command_found
        end
    end
end
