# ActiveREST

A simple ActiveRecord-looking ORM for Rails which interfaces with [ST9](http://github.com/sunnygleason/st9-proto-service).

## Features

* Supports ActiveModel-style validations, callbacks and naming, making it compatible with Rails.
* Supports foreign-key relationships, both on the host (has_many) and target side.
* Introduces an abstracted results collection (EnumerableResults) to leverage the flexibility of ST9's two-query architecture.

## Installation

Include ActiveRest in your Gemfile

```ruby
gem 'active_rest', git: 'https://github.com/sunnygleason/active_rest.git'
```

and run `bundle install`.

You must then install ST9. All you have to do is run a rake task:

```bash
rake db:setup
```

This will install the ST9 service, start the server and migrate the database.

## Configuration

Configuration of ActiveRest is handled in `database.yml`.

Because ActiveRecord is not used, make sure that you don't require it in your application to avoid errors. Instead of the usual `require rails/all` in your `application.rb`, replace it with the following:

```ruby
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'sprockets/railtie' # Rails 3.1+ only
```

### Options

`host`: Location of the ST9 service. Examples: `localhost`, `st9.example.com`
`port`: The port on which ST9 resides.
`version`: The version of ST9 that is used.
`db_type`: Two allowable settings here. The first is `h2` which uses an in-memory store and used mainly in development. The second is `mysql` which uses mysql as its store and is used mainly for production.
`allow_nuke`: Boolean value which tells whether to use the `nuke!` utility.
`allow_cascades`: Boolean value which will allow or disallow cascading operations.
`pid_file`: Location of the pid file used for ST9.

### Example

This is an example of a typical configuration:

```yaml
development: &development
  version: 0.10.1
  db_type: h2
  host: localhost
  port: 8080
  allow_nuke: true
  allow_cascades: true

test:
  <<: *development
  port: 7331
  pid_file: st9.test.pid

production:
  version: 0.10.1
  db_type: mysql
  host: st9.example.com
  port: 8080
  pid_file: st9.production.pid
  allow_nuke: false
  allow_cascades: true
```

## Fields

Once you create a model and inherit from `ActiveRest::Base`, you can add some fields.

### Types
* __i32__ - 32-bit signed integer
* __boolean__ - true or false (also, 1 or 0)
* __utf8\_smallstring__ - 250 UTF-8 characters
* __utf8\_text__ - Greater than 4KB but less than...
* __enum__ - Attribute must be one of the given values
* __utc\_date\_secs__ - UTC compatible datetime

__utf8\_smallstring__ and __utf8\_text__ have a _serialized_ option that converts the attribute value to JSON and vice-versa.
Fields are specified using their type - for example, utf8_smallstring :name and i32 :number_of_ponies.

## Relationships


### Has One (foreign keys)

```ruby
has_one :blah, kind: "Blah"
```

### Has Many (foreign key finders)

```ruby
has_many :relation_name, foreign_key: "foreign_key_id"
```

Does not support cascade operations. Queries will return an EnumerableResults object.

## Indexes

Indexes are specified using index

```ruby
"index_name", [:field1, :field2], :sort => :desc
```

Foreign keys are implicitly indexed.

## Querying

### Model.find

Queries models based on id(s) or sequence(s). Examples:

```ruby
Pony.find("@pony:a3d531206b42fe47")
Pony.find("a3d531206b42fe47")
Pony.find(3)
Pony.find(["a3d531206b42fe47", "c6eb033b3aa5466a", "6deaf51b82df50ca"])
Pony.find([1, 2, 3])
```

### Model.find!

Same as `Model.find`, but raises an exception if there's a problem.

### Model.find_with_index

Queries a specified index as well as attributes to match.

```ruby
Pony.find_with_index("name_and_breed", {:name => "galaxy", :breed = "magical"}, {:size => 5})
```

will return the first 5 magical ponies named galaxy.

### Model.find_unique

Queries an index but returns only one object.

### Model.exists?

Returns true if any records in the database match and false if no match is found.

```ruby
Pony.exists?("name_and_breed", {:name => "galaxy", :breed = "magical"})
# => true
```

### Model.all

Finds all records for a specific model.

## Counters

`nullable` option must be set to false for fields to be used by counters.

Counters are specified using:

```ruby
counter "counter_name", [:field1, :field2], :sort => :desc
```

This is essentially a count using "group by" based on the specified attributes.

Counters are queried using count() on the model:

```ruby
Pony.count("counter_name", {:field1 => "ONE", :field2 = 1970}, {:size => 5}).counts
```

will return the count of ponies matching the specified criteria.

A subset of counter attributes may be queried as long as they satisfy left-to-right ordering, for example:

```ruby
Pony.count("counter_name", {:field1 => "ONE"}).counts
```

## Callbacks

All callbacks supported by ActiveModel are included.

## Validations

All callbacks supported by ActiveModel are included, with the addition of `validates_uniqueness_of`.

## Timestamps

If you want ActiveRecord timestamps for your models (i.e. `created_at`, `updated_at`), just include the following in your model:

```ruby
include ActiveRest::Timestamps
```

## Rake Tasks

ActiveRest comes with the following rake tasks:

`db:install`: Downloads and installs ST9.

`db:start`: Start an instance of ST9.

`db:stop`: Stop ST9.

`db:restart`: Runs `db:stop`, then `db:start`.

`db:schema`: Load the schema for classes inheriting from ActiveRest::Base. Options: `MODELS=MyModel`, `VERBOSE=false`, `DEBUG=true`

`db:migrate`: Migrates the schema for classes inheriting from ActiveRest::Base. Options: `MODELS=MyModel`, `VERBOSE=false`, `DEBUG=true`

`db:setup`: Runs `db:install`, `db:start`, and `db:migrate`. Options: `VERBOSE=false`, `DEBUG=true`

`db:nuke`: Destroys all schema *and* data.

`db:reset`: Runs `db:nuke`, then `db:schema`. Options: `FILE=dump.json`, `VERBOSE=false`, `DEBUG=true`

`db:truncate`: Destroys only the data, leaves the schema.

`db:dump`: Dumps schema and data to `db/{environment}.json`. Options: `FILE=dump.json`, `VERBOSE=false`, `DEBUG=true`
