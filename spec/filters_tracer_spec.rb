# frozen_string_literal: true

require "pry-byebug"
require "rails"

RSpec.describe FiltersTracer do
  class Foo; end

  it "has a version number" do
    expect(FiltersTracer::VERSION).not_to be nil
  end

  describe ".register_controller" do
    let(:logger){ Logger.new(STDOUT) }
    before do
      FiltersTracer.configure do |config|
        config.logger = logger
      end
    end

    context "when an Integer is registered" do
      it "just logs the failure of the registration" do
        expect(logger).to receive(:error).with("===== [Failure] Could not register 12(Integer) =====").once
        FiltersTracer.register_controller(12)
      end
    end

    context "when a class which is not a Controller is given" do
      it "just logs the failure of the registration" do
        expect(logger).to receive(:error).with("===== [Failure] Foo is not a traceable controller =====").once
        expect(logger).to receive(:error).with("===== This is probably because either Foo is not a Rails controller or because the current version of Rails is not compatible with 'rails_filters_tracer' gem.").once
        FiltersTracer.register_controller(Foo)
      end
    end

    context "when a controller with multiple actions is registered" do
      it "traces all filters in all actions in the controller, and logs the success of the registration" do
        # filters of ChildController#some_action_child, ChildController#some_action2_child
        expect(ChildController).not_to receive(:add_method_tracer)

        # filters of ParentController#some_action_parent
        expect(ParentController).not_to receive(:add_method_tracer).with(:before_action_method__child)
        expect(ParentController).not_to receive(:add_method_tracer).with(:after_action_method__child)
        expect(ParentController).to receive(:add_method_tracer).with(:before_action_method__parent).once
        expect(ParentController).to receive(:add_method_tracer).with(:after_action_method__parent).once

        expect(logger).to receive(:info).with("===== [Success] Filters of all actions in ParentController will be reported to the New Relic server =====").once

        FiltersTracer.register_controller(ParentController)
      end
    end

    context "when a controller, some of whose filters are defined in a parent controller class, is registered" do
      it "traces all filters of the controller, and logs the success of the registration" do
        # filters of ChildController#some_action_child
        expect(ChildController).to receive(:add_method_tracer).with(:before_action_method__child).once
        expect(ChildController).to receive(:add_method_tracer).with(:after_action_method__child).once
        expect(ChildController).to receive(:add_method_tracer).with(:before_action_method__parent).once
        expect(ChildController).to receive(:add_method_tracer).with(:after_action_method__parent).once

        # filters of ChildController#some_action2_child
        expect(ChildController).to receive(:add_method_tracer).with(:after_action_method2__child).once

        # filters of ParentController#some_action_parent
        expect(ParentController).not_to receive(:add_method_tracer)

        expect(logger).to receive(:info).with("===== [Success] Filters of all actions in ChildController will be reported to the New Relic server =====").once

        FiltersTracer.register_controller(ChildController)
      end
    end
  end

  describe ".register_all_controllers" do
    let(:logger){ Logger.new(STDOUT) }
    before do
      FiltersTracer.configure do |config|
        config.logger = logger
      end
    end

    context "when an Integer is registered" do
      it "just logs the failure of the registration" do
        expect(logger).to receive(:error).with("===== [Failure] Could not register 12(Integer) =====").once
        FiltersTracer.register_all_subcontrollers(12)
      end
    end

    context "when a class which is not a Controller is given" do
      it "just logs the failure of the registration" do
        expect(logger).to receive(:error).with("===== [Failure] Foo is not a traceable controller =====").once
        expect(logger).to receive(:error).with("===== This is probably because either Foo is not a Rails controller or because the current version of Rails is not compatible with 'rails_filters_tracer' gem.").once
        FiltersTracer.register_all_subcontrollers(Foo)
      end
    end

    context "when ParentController is registered" do
      it "registers all of ParentController, ChildController, GrandChildController, and logs the success of the registrations" do
        expect(FiltersTracer).to receive(:register_controller).with(ParentController).once
        expect(FiltersTracer).to receive(:register_controller).with(ChildController).once
        expect(FiltersTracer).to receive(:register_controller).with(GrandChildController).once

        FiltersTracer.register_all_subcontrollers(ParentController)
      end
    end
  end
end
