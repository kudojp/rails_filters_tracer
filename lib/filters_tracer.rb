# frozen_string_literal: true

require 'newrelic_rpm'
require 'active_support/all'
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
      if controller.class != Class
        logger.error "===== [Failure] Could not register #{controller}(#{controller.class}) ====="
        return
      end

      unless controller.method_defined?(:_process_action_callbacks)
        logger.error "===== [Failure] #{controller} is not a traceable controller ====="
        logger.error "===== This is probably because either #{controller} is not a Rails controller or because the current version of Rails is not compatible with 'rails_filters_tracer' gem."
        return
      end

      begin
        controller.class_eval do
          self.include ::NewRelic::Agent::MethodTracer
          self._process_action_callbacks().send(:chain).each do |callback|
            case callback.raw_filter
            when Symbol
              self.add_method_tracer callback.raw_filter
            end
          end
        end
      rescue
        logger.error "===== [Failure] Filters of actions in #{controller_str} would not be traced properly.  ====="
        logger.error "===== This is probably because either the current version of Rails or NewRelic::Agent is not compatible with 'rails_filters_tracer' gem."
        return
      end

      logger.info "===== [Success] Filters of all actions in #{controller} will be reported to the New Relic server ====="
    end

    def register_all_subcontrollers(controller)
      if controller.class != Class
        logger.error "===== [Failure] Could not register #{controller}(#{controller.class}) ====="
        return
      end

      self.register_controller(controller)
      controller.descendants.each do |sub_controller|
        self.register_controller(sub_controller)
      end
    end
  end
end
