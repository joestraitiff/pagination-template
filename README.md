# Pagination Candidate Homework from Example Template

This is my (Joe Straitiff) candidate homework solution derived from the example
sinatra template provided.  The specification is included at [SPEC.md](./SPEC.md)

Quick Set-up:

``` bash
git clone https://github.com/joestraitiff/pagination-template
bundle install
export PAGINATION_DB="postgres://postgres:postgres@localhost/pagination-template" # or update the .env file in the project
bundle exec ruby ./setup.rb
foreman start
```

## Run Tests

```
bundle exec rake
```

## Database Creation

The setup.rb script mentioned above will get the database bootstrapped assuming
you have postgres installed with the following:

``` bash
brew install postgres # or as applicable for system
createdb pagination-template # -O to specify owner if your system setup requires it
```

Also you will need to update the .env file in the project or set the environment
variable for PAGINATION_DB for your system and specific database name before running
tests or starting the app.
