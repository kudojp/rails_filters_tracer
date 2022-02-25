# frozen_string_literal: true

require 'newrelic_rpm'
require_relative "filters_tracer/version"

module FiltersTracer
  class Configuration
    # @!attribute logger
    #   @return [Logger]
    attr_accessor :logger

    def initialize
      self.logger = defined?(::Rails) ? Rails.logger : Logger.new(STDOUT)
    end
  end

  class << self
    # @example
    #   FiltersTracer.configure do |config|
    #     config.logger = MyCustomLogger.new
    #   end
    # @yield [config]
    # @yieldparam [FiltersTracer::Configuration] config
    # @return [void]
    def configure
      yield configuration
    end

    # @return [FiltersTracer::Configuration]
    def configuration
      @configuration ||= Configuration.new
    end

    # @return [Logger]
    def logger
      configuration.logger
    end

    def register_controller(controller)
      controller_klass = self.class_from(controller) || return

      unless controller_klass.method_defined?(:_process_action_callbacks)
        logger.error "===== [Failure] #{controller_klass} is not a traceable controller ====="
        logger.error "===== This is probably because either #{controller_klass} is not a Rails controller or because the current version of Rails is not compatible with 'rails_filters_tracer' gem."
        return
      end

      controller_klass.class_eval do
        self.include ::NewRelic::Agent::MethodTracer
        begin
          self._process_action_callbacks().send(:chain).each do |callback|
            case callback.raw_filter
            when Symbol
              self.add_method_tracer callback.raw_filter
            end
          end
        rescue
          logger.error "===== [Failure] Filters of actions in #{controller_str} would not be traced properly.  ====="
          logger.error "===== This is probably because either the current version of Rails or NewRelic::Agent is not compatible with 'rails_filters_tracer' gem."
        end
      end

      logger.info "===== [Success] Filters of all actions in #{controller_klass} will be reported to the New Relic server ====="
    end

    def register_all_subcontrollers(controller)
      controller_klass = self.controller_class_from(controller) || return

      controller_klass.descendants.each do |controller|
        self.register_controller(controller)
      end
    end

    private

    def class_from(identifier)
      case identifier
      when Class
        return identifier
      when String, Symbol
        begin
          return identifier.to_s.constantize
        rescue NameError
          logger.error "===== [Failure] Class: '#{identifier}' has not been found ====="
        end
      else
        logger.error "===== [Failure] Could not identify a class from #{identifier}(#{identifier.class}) ====="
      end

      nil
    end
  end
end
