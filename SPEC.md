# Pagination

Pagination is a technique frequently seen in HTTP API's to make working with
large data sets more manageable. A huge number of different styles and
implementations can be observed across the web, but all of them share common
characteristics.

On Heroku's API, we paginate by means of an HTTP request header called `Range`,
which was originally defined as part of [RFC
2616](http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html). The format of a
"page" request might look like the following:

```
Range: id 5..; max=5
```

The server would respond with the request range of elements, a `Content-Range`
header describing the precise range of the response, along with a value in the
`Next-Range` header to indicate how to request the following page:

```
Content-Range: id 5..10
Next-Range: id ]10..; max=5
```

The closing square bracket is an exclusivity operator that indicates that the
next range should start at `10`, but not include it. An opening square bracket
indicates an inclusive range, but because this is the default, it is optional
and can be omitted.

The format of a `Range`, `Content-Range`, or `Next-Range` Heroku pagination
request or response header looks like the following:

```
Range: <field> [[<exclusivity operator>]<start identifier>]]..[<end identifier>][; [max=<max number of results>], [order=[<asc|desc>]]
```

Note that:

* Both start and end identifiers can be omitted, in which case the start
  identifier is assumed to be the first in the data set.
* Even if the start identifier is included, the end identifier can be omitted,
  in which case the program queries with no ending bound, but will still return
  results accounting for max page size.
* The max page size can be omitted, in which case the default of `200` is
  assumed.
* For cases where the end identifier extends beyond what can fit inside the
  maximum page, the page size takes precedence.
* The behavior in other corner cases can be safely assumed to be undefined.

Some examples of valid ranges:

```
Range: id ..
Range: id 1..
Range: id 1..5
Range: id ]5..
Range: id 1..; max=5
Range: id 1..; order=desc
Range: id ]5..10; max=5, order=desc
Range: name ]my-app-001..my-app-999; max=10, order=asc
```

## Exercise

Let's build a simple HTTP API endpoint that will perform pagination. The
endpoint shold return a JSON array of "apps" that look like the following:

```js
[
  {
    "id":   1,
    "name": "my-app-001",
  },
  // ...
]
```

When no `Range` header is provided with a request, the endpoint should respond
with an array according to default parameters (that is, select appropriate
defaults for the field which should be ordered on, the maximum page size, and
the sort order).

When the endpoint is requested with a `Range`, it should modify its response to
appropriately include only the items bounded by that range request:

```
Range: id 1..; max=2
```

``` json
[
  {
    "id":   1,
    "name": "my-app-001",
  },
  {
    "id":   2,
    "name": "my-app-002",
  }
]
```

It should also respond with the more precise manifested `Content-Range` that
describes the data set which it respond with (i.e. properly include an ending
identifier), and the next page in the `Next-Range` header:

```
Content-Range: id 1..2
Next-Range: id ]2..; max=2
```

(Note that the `Next-Range` should inherit the same maximum page size as the
requested range.)

A [tiny Sinatra template](https://github.com/heroku/pagination-template) is
available to boostrap this problem if so desired, but implementation in any
framework in any language that you can run is perfectly fine.

## Requirements

* Paginates according to the range format described in the first section.
* Paginates on either the `id` or `name` fields of our "app" object.
* Support for an inclusive or exclusive starting bound for a range with square
  brackets (`[` and `]` respectively).
* Backed by a database containing fixture data that will be returned from the
  running program.
* Delivered as part of a Git repository. This can either be on GitHub, or if
  you'd prefer, just a Git repo that's zipped up and e-mailed to us.
* Includes a test suite to verify basic functionality.
* Includes instructions to setup the project and run the test suite.
