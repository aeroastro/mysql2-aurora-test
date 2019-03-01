# mysql2 reconnect

Example codes to looking into Mysql2 reconnect options

`reconnect: false` makes you happy!

https://dev.mysql.com/doc/refman/8.0/en/c-api-auto-reconnect.html

## Prerequisites

* Ruby >= 2.3
* MySQL >= 5.6

## Usage

```bash
$ bundle install --path=vendor/bundle
$ cp database.yml.example database.yml
$ vim database.yml # or use your favorite editor to fill connection config
$ bundle exec rake -T # see what you can do
```
