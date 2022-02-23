# frozen_string_literal: true

require_relative "rails_filters_tracer/version"

module FiltersTracer
  class Configuration
    # @!attribute logger
    #   @return [Logger]
    attr_accessor :logger

    def initialize
      self.logger = defined?(::Rails) ? Rails.logger : Logger.new(STDOUT)
    end

    class << self
      # @example
      #   FiltersTracer.configure do |c|
      #     self.logger = MyCustomLogger.new
      #   end
      # @yield [c]
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
        controller =
          case controller
          when Class
          when String, Symbol
            begin
              controller_klass = controller_str.constantize
            rescue NameError
              logger.error "===== [Failure] Controller: '#{controller_str}' has not been found ====="
              next
            end
          else
            logger.error "===== [Failure] Could not identify a controller from #{controller}(#{controller.class}) ====="
          end

        unless controller_klass.method_defined?(:_process_action_callbacks)
          Rails.logger.error "===== [Failure] #{controller_klass} is not a traceable controller ====="
          Rails.logger.error "===== This is probably because either #{controller_klass} is not a Rails controller or because the current version of Rails is not compatible with 'rails_filters_tracer' gem."
          next
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
            Rails.logger.error "===== This is probably because either the current version of Rails or NewRelic::Agent is not compatible with 'rails_filters_tracer' gem."
          end
        end

        Rails.logger.info "===== [Success] Filters of all actions in #{controller_klass} will be reported to the New Relic server ====="
      end

      def register_all_controllers()
        # TODO
      end
    end
  end
end
