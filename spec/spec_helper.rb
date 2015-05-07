if ENV["COVERAGE"]
  # Run Coverage report
  require 'simplecov'
  SimpleCov.start do
    add_group 'Libraries', 'lib'
  end
end


RSpec.configure do |config|
  config.color = true
  config.mock_with :rspec
  config.raise_errors_for_deprecations!

  config.use_transactional_fixtures = false

  config.fail_fast = ENV['FAIL_FAST'] || false
end
