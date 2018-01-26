require 'most_ots/version'
require 'logger'
require 'most_ots/service'


module MostOts
  ROOT = File.expand_path('..', File.dirname(__dir__))

  # @!attribute [rw] logger
  # @return [Logger] The logger.
  def self.logger
    @logger ||= rails_logger || default_logger
  end

  class << self
    attr_writer :logger
  end

  # Create and configure a logger
  # @return [Logger]
  def self.default_logger
    logger = Logger.new($stdout)
    logger.level = Logger::WARN
    logger
  end

  # Check to see if client is being used in a Rails environment and get the logger if present.
  # Setting the ENV variable 'MOST_OTS' to false will force the client
  # to use its own logger.
  #
  # @return [Logger]
  def self.rails_logger
    if ENV.fetch('MOST_OTS', 'true') == 'true' &&
       defined?(::Rails) &&
       ::Rails.respond_to?(:logger) &&
       !::Rails.logger.nil?
      ::Rails.logger
    end
  end
end
