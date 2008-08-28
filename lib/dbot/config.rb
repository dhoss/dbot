require 'yaml'
require 'delegate'

class DBot
    class Config < DelegateClass(Hash)
        def initialize(filename)
            @config = YAML.load_file(filename)

            if @config.nil? 
                raise "Invalid config: couldn't load file #{filename}."
            elsif !@config.kind_of?(Hash)
                raise "Invalid config: not a hash"
            end

            super(@config)
        end

        # just an override to prefer #duping the result.
        def [](x)
            @config[x].dup rescue @config[x]
        end

        # produces the args needed by Net::YAIL's constructor.
        def yail_args
            {
                :irc_network => self["server"],
                :channels => self["channels"],
                :username => self["username"],
                :realname => self["realname"],
                :nicknames => self["nicknames"],
                :loud => self["loud"],
            }
        end

        # read-only struct-like behavior.
        def method_missing(method, *args)
            self[method.to_s]
        end
    end
end
