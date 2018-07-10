source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 5.1.4'
gem 'sqlite3'
gem 'puma', '~> 3.7'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'jbuilder', '~> 2.5'

group :development, :test do
  gem 'pry-rails'
end

group :test do
  gem 'rspec-tapas', '~> 0.2.0'
  gem 'capybara', '~> 3.3', '>= 3.3.1'
  gem 'database_cleaner'
  gem 'factory_bot_rails'
  gem 'rspec-rails'
  gem 'simplecov', require: false
  gem 'vcr'
  gem 'webmock'
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end
