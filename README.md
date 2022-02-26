# RailsFiltersTracer

[![CI](https://github.com/kudojp/rails_filters_tracer/workflows/CI/badge.svg?branch=main)](https://github.com/kudojp/rails_filters_tracer/actions?query=workflow%3ACI+branch%3Amain)
[![codecov](https://codecov.io/gh/kudojp/rails_filters_tracer/branch/main/graph/badge.svg?token=KSQO6HIAUH)](https://codecov.io/gh/kudojp/rails_filters_tracer)
[![Gem Version](https://badge.fury.io/rb/rails_filters_tracer.svg)](https://badge.fury.io/rb/rails_filters_tracer)
[![License](https://img.shields.io/github/license/kudojp/rails_filters_tracer)](./LICENSE)

RailsFiltersTracer helps you find performance bottlenecks in [filters](https://guides.rubyonrails.org/action_controller_overview.html#filters) of Rails Controllers. This gem works harmoniously with [newrelic_rpm](https://rubygems.org/gems/newrelic_rpm) gem.

## Usage

Imagine you are working on performance tuning of Rails application, and find that the response from an endpoint associated with `UsersControllers#update_avatar` is quite slow.

Your next step would probably be breaking down the execution time by an action itself and filters registered to the action.

With `newrelic_rpm` gem, you could trace each of them by calling `add_method_tracer` iteratively as below. This is bothersome (especially when the controller inherits another controller, in which case you also have to take care of inherited filters). 😢😢😢

```rb
class UsersController < ApplicationController
  include ::NewRelic::Agent::MethodTracer

  before_action :authenticate_user!, only: [:update_avatar]
  after_action :update_access_log, only: [:update_avatar]
  def update_avatar; end

  # call add_method_tracer class method again and again
  add_method_tracer :update_avatar
  add_method_tracer :authenticate_user!
  add_method_tracer :update_access_log
end
```

This gem eliminates this hassle. Just register `UsersController` to `FiltersTracer`'s configuration, and that's it. All the performance of all the filters are reported to New Relic server. 🎉🎉🎉

```rb
FiltersTracer.configure do |config|
  config.register_controller UsersController
end
```

⚠️ Currently, filters which are defined as blocks (not functions) are not be traced. This feature would be added in the future version.

## How to install and configure

Add this line to your application's Gemfile:

```ruby
gem 'rails_filters_tracer'
```

And then execute:

```
$ bundle install
```

Add `config/initializers/filters_tracer.rb` file in your Rails applications, and configure as below:

```rb
Rails.application.config.after_initialize do
  FiltersTracer.configure do |config|
    # Specify a logger with which registration status of the controller is logged.
    # Default is `Rails.logger || Logger.new(STDOUT)`
    config.logger = YourCustomLogger.new

    # Specify a controller class which includes an action of your concern.
    # You can register multiple controllers.
    config.register_controller UsersController
    config.register_controller PostsController

    # Specify a controller whose self and subclasses should be monitored.
    # Registering duplicated controllers with the previous step are allowed.
    # [Tip] Specifying ApplicationController would typically monitor all the filters in your app.
    config.register_all_subcontrollers ApplicationController
  end
end
```

⚠️ Please do not forget to set up New Relic agent in your application.

## Dependencies

This gem depends on `rails (>= 6.0.3, <7)` and `newrelic_rpm (>= 6.12, < 9)`.
(This does not mean previous or later versions do not work with this gem. Compatibilities have not been investigated.)

For `rails`, the compatibility has to be investigated in a strict manner. This is because FilterTracer monkey patches ActionController objects internally, thus even the difference of minor version of rails may result in the crush.

For `newrelic_rpm` gem, it is required that `add_method_tracer` is included in `NewRelic::Agent::MethodTracer` module.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kudojp/rails_filters_tracer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/kudojp/rails_filters_tracer/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the RailsFiltersTracer project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/rails_filters_tracer/blob/master/CODE_OF_CONDUCT.md).
