require "action_controller"

class ParentController < ActionController::Base
  before_action :before_action_method__parent, only: [:some_action__parent]
  after_action :after_action_method__parent, only: [:some_action__parent]

  def before_action_method__parent; end
  def after_action_method__parent; end

  def some_action__parent; end
end
