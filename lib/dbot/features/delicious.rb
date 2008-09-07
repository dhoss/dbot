begin
    require 'rubygems'
    gem 'www-delicious'
rescue LoadError
end

require 'www/delicious'
require 'uri'

class DBot
    module Feature
        class Delicious < DBot::FeatureSet

            #--
            #
            # Command code
            #
            #++

            COMMANDS = DBot::CommandTable.new do |table|
                table.add("account", "Display the account where the URLs are stored", :account)
                table.add("delete", "Delete a URL", :delete)
                table.add("tag", "Tag a url (tags separated by spaces). Syntax: !tag <url> <tags>", :tag)
                table.add("title", "Set the title of the url. Syntax: !title <url> <title>", :title)
                table.add("lasturl", "Show the last stored URL, optionally filtered by tag.", :lasturl)
                table.add("recent", "Show the 5 most recent stored URLs, optionally filtered by tag.", :recent)
            end

            def account(event)
                event.reply("Visit http://delicious.com/#{@account} to see links that have been stored.")
            end

            def delete(event)
                if event.command_args.length < 1
                    event.reply("usage: !delete <url>")
                else
                    begin
                        get_url(event.command_args[0]) do |post|
                            begin
                                @del.posts_delete(post.url)
                                event.reply("done, #{event.from}.")
                            rescue URI::InvalidURIError
                            end
                        end
                    rescue StandardError => e
                        event.reply(e.message)
                    end
                end
            rescue WWW::Delicious::Error
                event.reply("error deleting #{event.command_args[0]}")
            end

            def tag(event)
                tokens = event.command_args
                if tokens.length < 2
                    msg(out, "usage: !tag <url> <list of tags>")
                else
                    url = tokens[0]
                    tags = tokens[1..-1].collect { |part| part.sub(/,*$/, '') }
                    begin
                        get_url(url) do |post|
                            post.tags.push(*tags)
                            write_post(event, post, "tagging")
                        end
                    rescue StandardError => e
                        event.reply(e.message)
                    end
                end
            end

            def title(event)
                tokens = event.command_args

                if tokens.length < 2
                    msg(out, "usage: !title <url> <title>")
                else
                    url = tokens[0]
                    title = tokens[1..-1].join(" ")
                   
                    begin
                        get_url(url) do |post|
                            post.title = title
                            write_post(event, post, "retitling")
                        end
                    rescue StandardError => e
                        event.reply(e.message)
                    end
                end
            end
            
            def recent(event)
                tag = event.command_args[0]

                get_recent_urls(tag, 5) do |posts|
                    posts.each do |post|
                        event.reply(post.url.to_s)
                    end
                end
            rescue WWW::Delicious::Error
            end

            def lasturl(event)
                tag = event.command_args[0]

                get_recent_urls(tag, 1) do |posts|
                    unless posts.empty?
                        event.reply(posts[0].url.to_s)
                    end
                end
            rescue WWW::Delicious::Error
            end

            #--
            #
            # Support code
            #
            #++

            def initialize(commands_obj)
                @del = WWW::Delicious.new(DBot::Config.delicious_username, DBot::Config.delicious_password)
                @account = DBot::Config.delicious_username
                @handle_everything = true
                @commands = COMMANDS.dup
                @commands.bind(self)
                super(@commands)
            end

            # we need a special 'handle' method since we have @handle_everything turned on.
            def handle(event)
                if event.has_command? and @valid_commands[event.command]
                    @valid_commands.call(event)
                else
                    # handle urls
                    begin
                        urls = URI.extract(event.text, DBot::Config.delicious_schemes || %w(http))
                        unless urls.empty?
                            store_urls(event, urls)
                        end
                    rescue Exception => e
                        event.reply(e.message)
                    end
                end
            end

            protected

            def store_urls(event, urls)
                urls.each do |url| 
                    begin
                        @del.posts_add(:url => url, :title => url, :replace => true, :tags => [event.from]) 
                    rescue WWW::Delicious::Error => e
                        event.reply("error storing: #{urls.join(', ')}. sorry, bub.")
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

            def write_post(event, post, action)
                # XXX hack around a WWW::Delicious bug
                @del.posts_delete(post.url)
                @del.posts_add(post)
                event.reply("done, #{event.from}.")
            rescue WWW::Delicious::Error
                event.reply("error #{action} #{post.url}")
            end
        end
    end
end

DBot::Features.register_commandset(DBot::Feature::Delicious)
