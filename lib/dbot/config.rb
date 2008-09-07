require 'yaml'

class DBot
    class Config
        def self.load_file(filename)
            @@config = YAML.load_file(filename)

            if @@config.nil? 
                raise "Invalid config: couldn't load file #{filename}."
            elsif !@@config.kind_of?(Hash)
                raise "Invalid config: not a hash"
            end
        end

        # just an override to prefer #duping the result.
        def self.[](x)
            @@config[x].dup rescue @@config[x]
        end

        # produces the args needed by Net::YAIL's constructor.
        def self.yail_args
            {
                :irc_network => self["server"],
                :channels => self["channels"],
                :username => self["username"],
                :realname => self["realname"],
                :nicknames => self["nicknames"],
                :loud => self["loud"],
            }
        end

        def self.leader
            self["leader"] || "!"
        end

        # read-only struct-like behavior.
        def self.method_missing(method, *args)
            self[method.to_s]
        end
    end
end
