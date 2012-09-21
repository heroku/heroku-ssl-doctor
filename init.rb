require 'rbconfig'
%w[ json rest-client ].each do |gem_name|
  begin
    require gem_name
  rescue LoadError
    Heroku::Helpers.error("Install the #{gem_name} gem to use certs commands:\n#{Config::CONFIG["bindir"]}/gem install #{gem_name}")
  end
end

require 'heroku/command/extended/certs'
