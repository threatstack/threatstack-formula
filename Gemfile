source 'https://rubygems.org'

source ENV['GEM_SOURCE'] || 'https://rubygems.org'

group :development, :unit_tests do
  gem 'rake',                        :require => false
end
group :system_tests do
  gem 'serverspec',      :require => false
  gem 'test-kitchen',    :require => false
  gem 'kitchen-salt',  :require => false
  gem 'kitchen-vagrant', :require => false
end

# vim:ft=ruby
