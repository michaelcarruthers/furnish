require 'bundler/setup'

if ENV["COVERAGE"]
  require 'simplecov'
  SimpleCov.start do
    add_filter '/test/'
  end
end

require 'minitest/unit'
require 'tempfile'
require 'furnish'
require 'mt_cases'

require 'minitest/autorun'
