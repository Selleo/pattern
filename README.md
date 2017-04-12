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
