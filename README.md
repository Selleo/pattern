# Pattern

A collection of lightweight, standardized, rails-oriented patterns.

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
  scope :recenty_activated, RecentlyActivatedUsersQuery
end
```

## Service

### When to use it

Service objects are commonly used to mitigate problems with model callbacks that interact with external classes ([read more...](http://samuelmullen.com/2013/05/the-problem-with-rails-callbacks/)).
Service objects are also useful for handling processes involving multiple steps. E.g. a controller that performs more than one operation on its subject (usually a model instance) is a possible candidate for Extract ServiceObject (or Extract FormObject) refactoring.

### Assumptions and rules

* Service objects are always used by calling class-level `.call` method
* Service objects have to implement `#call` method
* Calling service object's `.call` method executes `#call` and returns service object instance
* A result of `#call` method is accessible through `#result` method
* It is recommended for `#call` method to be the only public method of service object (besides state readers)
* It is recommended to name service object classes after commands (e.g. `ActivateUser` instead of `UserActivation`)

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
    transform_values{ |event| event.public_send(options.fetch(:label_method, "description")) }
  end
end
```

#### Usage

```ruby
ColorsCollection.new
CustomerEventsCollection.for(customer)
CustomerEventsCollection.for(customer, label_method: "name")
```

## Further reading

* [7 ways to decompose fat active record models](http://blog.codeclimate.com/blog/2012/10/17/7-ways-to-decompose-fat-activerecord-models/)
