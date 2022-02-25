# frozen_string_literal: true
require "pry-byebug"
require "rails"
require "support/child_controller.rb"

RSpec.describe FiltersTracer do
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

    context "when ChildController is registered" do
      it "registers controller, and logs the success of the registration" do
        expect(ChildController).to receive(:add_method_tracer).with(:before_action_method__child).once
        expect(ChildController).to receive(:add_method_tracer).with(:after_action_method__child).once
        expect(ChildController).to receive(:add_method_tracer).with(:before_action_method__parent).once
        expect(ChildController).to receive(:add_method_tracer).with(:after_action_method__parent).once
        expect(ParentController).not_to receive(:add_method_tracer)

        expect(logger).to receive(:info).with("===== [Success] Filters of all actions in ChildController will be reported to the New Relic server =====")

        FiltersTracer.register_controller(ChildController)
      end
    end

    context "when ParentController is registered" do
      it "registers controller, and logs the success of the registration" do
        expect(ChildController).not_to receive(:add_method_tracer)
        expect(ParentController).not_to receive(:add_method_tracer).with(:before_action_method__child)
        expect(ParentController).not_to receive(:add_method_tracer).with(:after_action_method__child)
        expect(ParentController).to receive(:add_method_tracer).with(:before_action_method__parent).once
        expect(ParentController).to receive(:add_method_tracer).with(:after_action_method__parent).once

        expect(logger).to receive(:info).with("===== [Success] Filters of all actions in ParentController will be reported to the New Relic server =====")

        FiltersTracer.register_controller(ParentController)
      end
    end
  end

  describe ".class_from" do
    class Foo; end
    let(:logger){ Logger.new(nil) }
    let(:foo_class){ Foo }
    let(:foo_symbol){ :Foo }
    let(:bar_string){ 'Bar' }
    let(:foo_symbol){ :Bar }

    before do
      FiltersTracer.configure do |config|
        config.logger = logger
      end
    end

    context "when a class is given" do
      it "returns the given class" do
        expect(logger).not_to receive(:info)
        expect(logger).not_to receive(:error)
        expect(FiltersTracer.send(:class_from, foo_class)).to eq(foo_class)
      end
    end

    context "when a Symbol object is given" do
      context "when a class whose name is that symbol is defined" do
        let(:foo_symbol){ :Foo }
        it "returns the class with the same name" do
          expect(logger).not_to receive(:info)
          expect(logger).not_to receive(:error)
          expect(FiltersTracer.send(:class_from, foo_symbol)).to eq(foo_class)
        end
      end

      context "when a class whose name is that symbol is not defined" do
        let(:bar_symbol){ :Bar }
        it "returns nil" do
          expect(logger).not_to receive(:info)
          expect(logger).to receive(:error).with("===== [Failure] Class: 'Bar' has not been found =====").once
          expect(FiltersTracer.send(:class_from, foo_symbol)).to be_nil
        end
      end
    end

    context "when a String is given" do
      context "when a class whose name is that string is defined" do
        let(:foo_string){ 'Foo' }
        it "returns the class with the same name" do
          expect(FiltersTracer.send(:class_from, foo_string)).to eq(foo_class)
          expect(logger).not_to receive(:info)
          expect(logger).not_to receive(:error)
        end
      end

      context "when a class whose name is that string is not defined" do
        let(:bar_string){ 'Bar' }
        it "returns nil" do
          expect(logger).not_to receive(:info)
          expect(logger).to receive(:error).with("===== [Failure] Class: 'Bar' has not been found =====").once
          expect(FiltersTracer.send(:class_from, bar_string)).to be_nil
        end
      end
    end

    context "when an Integer is given" do
      let(:some_int){ 111 }
      it "returns nil" do
        expect(logger).not_to receive(:info)
        expect(logger).to receive(:error).once.with("===== [Failure] Could not identify a class from 111(Integer) =====")
        expect(FiltersTracer.send(:class_from, 111)).to be_nil
      end
    end
  end
end
