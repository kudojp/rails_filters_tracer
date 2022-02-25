require "support/parent_controller"

class ChildController < ParentController
  before_action :before_action_method__child, only: :some_action__child
  before_action :before_action_method__parent, only: :some_action__child
  after_action :after_action_method__child, only: :some_action__child
  after_action :after_action_method__parent, only: :some_action__child

  def before_action_method__child; end
  def after_action_method__child; end

  def some_action__child; end
end
