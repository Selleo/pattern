# Pattern

A collection of lightweight, standardized, rails-oriented patterns used by [RubyOnRails Developers @ Selleo](https://selleo.com/ruby-on-rails)

- [Query - complex querying on active record relation](#query)
- [Service - useful for handling processes involving multiple steps](#service)
- [Collection - when in need to add a method that relates to the collection as whole](#collection)
- [Form - when you need a place for callbacks, want to replace strong parameters or handle virtual/composite resources](#form)
- [Calculation - when you need a place for calculating a simple value (numeric, array, hash) and/or cache it](#calculation)

## Installation

```ruby
# Gemfile

#...
gem "rails-patterns"
#...
```

Then `bundle install`

## Query
 
### When to use it

One should consider using query objects pattern when in need to perform complex querying on active record relation. 
Usually one should avoid using scopes for such purpose. 
As a rule of thumb, if scope interacts with more than one column and/or joins in other tables, it should be moved to query object.
Also whenever a chain of scopes is to be used, one should consider using query object too.
Some more information on using query objects can be found in [this article](https://medium.com/@blazejkosmowski/essential-rubyonrails-patterns-part-2-query-objects-4b253f4f4539).

### Assumptions and rules

* Query objects are always used by calling class-level `.call` method
* Query objects require `ActiveRecord::Relation` or `ActiveRecord::Base` as constructor argument
* Default relation (see above) can be defined by using `queries` macro
* Query objects have to implement `#query` method that returns `ActiveRecord::Relation`
* Query objects provide access to consecutive keyword arguments using `#options` hash

### Other

Because of the fact, that QueryObject implements `.call` method, those can be used to construct scopes if required. ([read more...](http://craftingruby.com/posts/2015/06/29/query-objects-through-scopes.html))

### Examples

#### Declaration

```ruby
class RecentlyActivatedUsersQuery < Patterns::Query
  queries User

  private

  def query
    relation.active.where(activated_at: date_range)
  end

  def date_range
    options.fetch(:date_range, default_date_range)
  end

  def default_date_range
    Date.yesterday.beginning_of_day..Date.today.end_of_day
  end
end
```

#### Usage

```ruby
RecentlyActivatedUsersQuery.call
RecentlyActivatedUsersQuery.call(User.without_test_users)
RecentlyActivatedUsersQuery.call(date_range: Date.today.beginning_of_day..Date.today.end_of_day)
RecentlyActivatedUsersQuery.call(User.without_test_users, date_range: Date.today.beginning_of_day..Date.today.end_of_day)

class User < ApplicationRecord
  scope :recently_activated, RecentlyActivatedUsersQuery
end
```

## Service

### When to use it

Service objects are commonly used to mitigate problems with model callbacks that interact with external classes ([read more...](http://samuelmullen.com/2013/05/the-problem-with-rails-callbacks/)).
Service objects are also useful for handling processes involving multiple steps. E.g. a controller that performs more than one operation on its subject (usually a model instance) is a possible candidate for Extract ServiceObject (or Extract FormObject) refactoring. In many cases service object can be used as scaffolding for [replace method with object refactoring](https://sourcemaking.com/refactoring/replace-method-with-method-object). Some more information on using services can be found in [this article](https://medium.com/selleo/essential-rubyonrails-patterns-part-1-service-objects-1af9f9573ca1).

### Assumptions and rules

* Service objects are always used by calling class-level `.call` method
* Service objects have to implement `#call` method
* Calling service object's `.call` method executes `#call` and returns service object instance
* A result of `#call` method is accessible through `#result` method
* It is recommended for `#call` method to be the only public method of service object (besides state readers)
* It is recommended to name service object classes after commands (e.g. `ActivateUser` instead of `UserActivation`)

### Other 

A bit higher level of abstraction is provided by [business_process gem](https://github.com/Selleo/business_process). 

### Examples

#### Declaration

```ruby
class ActivateUser < Patterns::Service
  def initialize(user)
    @user = user
  end

  def call
    user.activate!
    NotificationsMailer.user_activation_notification(user).deliver_now
    user
  end

  private

  attr_reader :user
end
```

#### Usage

```ruby
  user_activation = ActivateUser.call(user)
  user_activation.result # <User id: 5803143, email: "tony@patterns.dev ...
```

## Collection

### When to use it

One should consider using collection pattern when in need to add a method that relates to the collection a whole.
Popular example for such situation is for paginated collections, where for instance `#current_page` getter makes sense only in collection context.
Also collections can be used as a container for mapping or grouping logic (especially if the mapping is not 1-1 in terms of size).
Collection might also act as a replacement for models not inheriting from ActiveRecord::Base (e.g. `StatusesCollection`, `ColorsCollection` etc.).
What is more, collections can be used if we need to encapsulate "flagging" logic - for instance if we need to render a separator element between collection elements based on some specific logic, we can move this logic from view layer to collection and yield an additional flag to control rendering in view.

### Assumptions and rules

* Collections include `Enumerable`
* Collections can be initialized using `.new`, `.from` and `.for` (aliases)
* Collections have to implement `#collection` method that returns object responding to `#each`
* Collections provide access to consecutive keyword arguments using `#options` hash
* Collections provide access to first argument using `#subject`

### Examples

#### Declaration

```ruby
class ColorsCollection < Patterns::Collection
  AVAILABLE_COLORS = { red: "#FF0000", green: "#00FF00", blue: "#0000FF" }

  private

  def collection
    AVAILABLE_COLORS
  end
end

class CustomerEventsByTypeCollection < Patterns::Collection
  private

  def collection
    subject.
    events.
    group_by(&:type).
    transform_values{ |events| events.map{ |e| e.public_send(options.fetch(:label_method, "description")) }}
  end
end
```

#### Usage

```ruby
ColorsCollection.new
CustomerEventsByTypeCollection.for(customer)
CustomerEventsByTypeCollection.for(customer, label_method: "name")
```

## Form

### When to use it

Form objects, just like service objects, are commonly used to mitigate problems with model callbacks that interact with external classes ([read more...](http://samuelmullen.com/2013/05/the-problem-with-rails-callbacks/)).
Form objects can also be used as replacement for `ActionController::StrongParameters` strategy, as all writable attributes are re-defined within each form.
Finally form objects can be used as wrappers for virtual (with no model representation) or composite (saving multiple models at once) resources.
In the latter case this may act as replacement for `ActiveRecord::NestedAttributes`.
In some cases FormObject can be used as scaffolding for [replace method with object refactoring](https://sourcemaking.com/refactoring/replace-method-with-method-object). Some more information on using form objects can be found in [this article](https://medium.com/selleo/essential-rubyonrails-patterns-form-objects-b199aada6ec9).

### Assumptions and rules

* Forms include `ActiveModel::Validations` to support validation.
* Forms include `Virtus.model` to support `attribute` static method with all [corresponding capabilities](https://github.com/solnic/virtus).
* Forms can be initialized using `.new`.
* Forms accept optional resource object as first constructor argument.
* Forms accept optional attributes hash as latter constructor argument.
* Forms have to implement `#persist` method that returns falsey (if failed) or truthy (if succeeded) value.
* Forms provide access to first constructor argument using `#resource`.
* Forms are saved using their `#save` or `#save!` methods.
* Forms will attempt to pre-populate their fields using `resource#attributes` and public getters for `resource`
* Form's fields are populated with passed-in attributes hash reverse-merged with pre-populated attributes if possible.
* Forms provide `#as` builder method that populates internal `@form_owner` variable (can be used to store current user).
* Forms allow defining/overriding their `#param_key` method result by using `.param_key` static method. This defaults to `#resource#model_name#param_key`.
* Forms delegate `#persisted?` method to `#resource` if possible.
* Forms do handle `ActionController::Parameters` as attributes hash (using `to_unsafe_h`)
* It is recommended to wrap `#persist` method in transaction if possible and if multiple model are affected.

### Examples

#### Declaration

```ruby
class UserForm < Patterns::Form
  param_key "person"

  attribute :first_name, String
  attribute :last_name, String
  attribute :age, Integer
  attribute :full_address, String
  attribute :skip_notification, Boolean

  validate :first_name, :last_name, presence: true

  private

  def persist
    update_user and
      update_address and
      deliver_notification
  end

  def update_user
    resource.update_attributes(attributes.except(:full_address, :skip_notification))
  end

  def update_address
    resource.address.update_attributes(full_address: full_address)
  end

  def deliver_notification
    skip_notification || UserNotifier.user_update_notification(user, form_owner).deliver
  end
end

class ReportConfigurationForm < Patterns::Form
  param_key "report"

  attribute :include_extra_data, Boolean
  attribute :dump_as_csv, Boolean
  attribute :comma_separated_column_names, String
  attribute :date_start, Date
  attribute :date_end, Date

  private

  def persist
    SendReport.call(attributes)
  end
end
```

#### Usage

```ruby
form = UserForm.new(User.find(1), params[:person])
form.save

form = UserForm.new(User.new, params[:person]).as(current_user)
form.save!

ReportConfigurationForm.new
ReportConfigurationForm.new({ include_extra_data: true, dump_as_csv: true })
```

## Calculation

### When to use it

Calculation objects provide a place to calculate simple values (i.e. numeric, arrays, hashes), especially when calculations require interacting with multiple classes, and thus do not fit into any particular one.
Calculation objects also provide simple abstraction for caching their results.

### Assumptions and rules

* Calculations have to implement `#result` method that returns any value (result of calculation).
* Calculations do provide `.set_cache_expiry_every` method, that allows defining caching period.
* When `.set_cache_expiry_every` is not used, result is not being cached.
* Calculations return result by calling any of following methods: `.calculate`, `.result_for` or `.result`.
* First argument passed to calculation is accessible by `#subject` private method.
* Arguments hash passed to calculation is accessible by `#options` private method.
* Caching takes into account arguments passed when building cache key.
* To build cache key, `#cache_key` of each argument value is used if possible.
* By default `Rails.cache` is used as cache store.

### Examples

#### Declaration

```ruby
class AverageHotelDailyRevenue < Patterns::Calculation
  set_cache_expiry_every 1.day

  private

  def result
    reservations.sum(:price) / days_in_year
  end

  def reservations
    Reservation.where(
      date: (beginning_of_year..end_of_year),
      hotel_id: subject.id
    )
  end

  def days_in_year
    end_of_year.yday
  end

  def year
    options.fetch(:year, Date.current.year)
  end

  def beginning_of_year
    Date.new(year).beginning_of_year
  end

  def end_of_year
    Date.new(year).end_of_year
  end
end
```

#### Usage

```ruby
hotel = Hotel.find(123)
AverageHotelDailyRevenue.result_for(hotel)
AverageHotelDailyRevenue.result_for(hotel, year: 2015)

TotalCurrentRevenue.calculate
AverageDailyRevenue.result
```

## Further reading

* [7 ways to decompose fat active record models](http://blog.codeclimate.com/blog/2012/10/17/7-ways-to-decompose-fat-activerecord-models/)
