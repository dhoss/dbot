begin
    require 'rubygems'
    gem 'www-delicious'
rescue LoadError
end

require 'www/delicious'
require 'uri'

class DBot
    module Feature
        class Delicious < DBot::CommandSet

            #--
            #
            # Command code
            #
            #++

            COMMANDS = {
                "account" => [:account, "Display the account where the URLs are stored"],
                "delete"  => [:delete, "Delete a URL"],
                "tag"     => [:tag, "Tag a url (tags separated by spaces). Syntax: !tag <url> <tags>"],
                "title"   => [:title, "Set the title of the url. Syntax: !title <url> <title>"],
                "lasturl" => [:lasturl, "Show the last stored URL."],
                "recent"  => [:recent, "Show the 5 most recent stored URLs. If given a tag, will constraint to it."],
            }

            def account(irc, out, tokens, event_args)
                irc.msg(out, "Visit http://delicious.com/#{@account} to see links that have been stored.")
            end

            def delete(irc, out, tokens, event_args)
                if tokens.length < 1
                    irc.msg(out, "usage: !delete <url>")
                else
                    begin
                        get_url(tokens[0]) do |post|
                            begin
                                @del.posts_delete(post.url)
                                irc.msg(out, "done, #{event_args[:nick]}")
                            rescue URI::InvalidURIError
                            end
                        end
                    rescue StandardError => e
                        irc.msg(out, e.message)
                    end
                end
            rescue WWW::Delicious::Error
                irc.msg(out, "error deleting #{tokens[0]}")
            end

            def tag(irc, out, tokens, event_args)
                if tokens.length < 2
                    msg(out, "usage: !tag <url> <list of tags>")
                else
                    url = tokens.shift
                    tags = tokens.collect { |part| part.sub(/,*$/, '') }
                    begin
                        get_url(url) do |post|
                            post.tags.push(*tags)
                            write_post(irc, out, event_args[:nick], post, "tagging")
                        end
                    rescue StandardError => e
                        irc.msg(out, e.message)
                    end
                end
            end

            def title(irc, out, tokens, event_args)
                if tokens.length < 2
                    msg(out, "usage: !title <url> <title>")
                else
                    url = tokens[0]
                    title = tokens[1..-1].join(" ")
                   
                    begin
                        get_url(url) do |post|
                            post.title = title
                            write_post(irc, out, event_args[:nick], post, "retitling")
                        end
                    rescue StandardError => e
                        irc.msg(out, e.message)
                    end
                end
            end
            
            def recent(irc, out, tokens, event_args)
                tag = tokens[0]

                get_recent_urls(tag, 5) do |posts|
                    posts.each do |post|
                        irc.msg(out, post.url.to_s)
                    end
                end
            rescue WWW::Delicious::Error
            end

            def lasturl(irc, out, tokens, event_args)
                tag = tokens[0]

                get_recent_urls(tag, 1) do |posts|
                    unless posts.empty?
                        irc.msg(out, posts[0].url.to_s)
                    end
                end
            rescue WWW::Delicious::Error
            end

            #--
            #
            # Support code
            #
            #++

            def initialize(config)
                @del = WWW::Delicious.new(config.delicious_username, config.delicious_password)
                @account = config.delicious_username
                @handle_everything = true
                super(config, methodize_commands(COMMANDS))
            end

            # we need a special 'handle' method since we have @handle_everything turned on.
            def handle(irc, command_str, out, tokens, event_args)
                if @valid_commands[command_str]
                    self.send(command_str, irc, out, tokens, event_args)
                else
                    # handle urls
                    begin
                        urls = URI.extract(event_args[:text], @config.delicious_schemes || %w(http))
                        unless urls.empty?
                            store_urls(out, event_args[:nick], urls)
                        end
                    rescue Exception
                    end
                end
            end

            protected

            def store_urls(out, nick, urls)
                urls.each do |url| 
                    begin
                        @del.posts_add(:url => url, :title => url, :replace => true, :tags => [nick]) 
                    rescue WWW::Delicious::Error => e
                        msg(out, "error storing: #{urls.join(', ')}. sorry, bub.")
                    end
                end
            end

            def get_recent_urls(tag, count)
                posts = []

                if tag
                    posts = @del.posts_recent(:tag => tag, :count => count)
                else
                    posts = @del.posts_recent(:count => count)
                end

                yield posts
            end

            def get_url(url)
                posts = @del.posts_get(:url => url)
                if posts.empty?
                    raise "no such url: #{url}"
                else
                    # XXX hack around a WWW::Delicious bug
                    post = posts[0]
                    post.url = post.url.to_s
                    yield post
                end
            rescue WWW::Delicious::Error, URI::InvalidURIError
                raise "error handling url: #{url}"
            end

            def write_post(irc, out, nick, post, action)
                # XXX hack around a WWW::Delicious bug
                @del.posts_delete(post.url)
                @del.posts_add(post)
                irc.msg(out, "done, #{nick}.") 
            rescue WWW::Delicious::Error
                irc.msg(out, "error #{action} #{post.url}")
            end

            def methodize_commands(commands)
                new_commands = { }
                commands.each do |key, value|
                    new_commands[key] = [method(value[0]), value[1]]
                end

                return new_commands
            end
        end
    end
end

DBot::Commands.register_commandset(DBot::Feature::Delicious)
