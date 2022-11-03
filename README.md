# PG Fixtures

PG Fixtures is loosely based on [Fixpoints](https://github.com/motine/fixpoints) in that it saves a copy of your databases to files and reloads your databases later saving precious time if you have test that require lots of setup.  PG Fixtures is different because it is Postgres specific, and uses `db_dump` and `psql` to decrease the memory requirements of saving and loading data.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pg_fixtures'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install pg_fixtures

## Usage

PG Fixtures will speed up subsequent test runs by storing the DB state after complex and lengthy processing.For subsequent runs, instead of re-running the setup routine, PG Fixtures simply loads the data from the SQL file.
```
pg_fixture = PgFixtures.new(
    directory: 'spec/pg_fixtures',
    excluded_tables: ['versions', 'spatial_ref_sys', 'uploads']
    model: ApplicationRecord,
)
if pg_fixture.exists?
    pg_fixture.restore
else
    # ... do some involved data manipulation that takes significant time
    pg_fixture.store
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/pg_fixtures. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/pg_fixtures/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the PgFixtures project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/pg_fixtures/blob/master/CODE_OF_CONDUCT.md).
