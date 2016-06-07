# MuchTimeout

IO.select based timeouts.  This is an alternative to the stdlib's Timeout module that doesn't rely on `sleep`.  This should produce more accurate timeouts with an expanded API for different handling options.

## Usage

### `timeout`

```ruby
require 'much-timeout'

MuchTimeout.timeout(5) do
  # ... something that should be interrupted ...

  # raises a `MuchTimeout::TimeoutError` exception if it takes more than 5 seconds
  # returns the result of the block otherwise
end
```

MuchTimeout, in its basic form, is a replacement for Timeout.  The main difference is that `IO.select` on an internal pipe is the mechanism for detecting the timeout.  Another difference is that the block is executed in a separate thread while the select/monitoring occurs in the main thread.

**Note**: like Timeout, **`Thread#raise` is used to interrupt the block**.  This technique is [widely](http://blog.headius.com/2008/02/ruby-threadraise-threadkill-timeoutrb.html) [considered](http://www.mikeperham.com/2015/05/08/timeout-rubys-most-dangerous-api/) to be [dangerous](http://jvns.ca/blog/2015/11/27/why-rubys-timeout-is-dangerous-and-thread-dot-raise-is-terrifying/).  Be aware and use responsibly.

```ruby
MuchTimeout.timeout(5, MyCustomTimeoutError) do
  # ... something that should be interrupted ...

  # raises a `MyCustomTimeoutError` exception if it takes more than 5 seconds
end
```

Like Timeout, you can optionally specify a custom exception class to raise.

### `optional_timeout`

```ruby
seconds = [5, nil].sample
MuchTimeout.optional_timeout(seconds) do
  # ... something that should be interrupted ...

  # raises an exception if seconds is not nil and it takes more than 5 seconds
  # otherwise the block is called directly and will not be interrupted
end
```

In addtion to the basic `timeout` API, MuchTimeout provides `optional_timeout` which conditionally applies timeout handling based on the given seconds value.  Passing `nil` seconds will just call the block and will not apply any timeout handling (where passing `nil` seconds to `timeout` raises an argument error).

### `just_{optional_}timeout`

```ruby
MuchTimeout.just_timeout(5, :do => proc{
  # ... something that should be interrupted ...

  # interrupt if it takes more than 5 seconds
  # no exceptions are raised (they are all rescued internally)
})

seconds = [5, nil].sample
MuchTimeout.just_optional_timeout(seconds, :do => proc{
  # ... something that should be interrupted ...

  # interrupt if seconds is not nil and it takes more than 5 seconds
  # no exceptions are raised (they are all rescued internally)
})
```

These alternative timeout methods execute and interrupt the given `:do` block if it times out.  However, no exceptions are raised and no exception handling is required (the `Thread#raise` interrupt is rescued internally).  Use this option to avoid any custom exception handling logic when you don't care about the timeout exception information.

In the case you want to run some custom logic when a timeout occurs, pass an optional `:on_timeout` proc:

```ruby
MuchTimeout.just_timeout(5, {
  :do => proc{
    # ... something that should be interrupted ...
  },
  :on_timeout => proc{
    # ... something that should run when a timeout occurs ...
  }
})
```

This works as you'd expect for both `just_timeout` and `just_optional_timeout`.

## Installation

Add this line to your application's Gemfile:

    gem 'much-timeout'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install much-timeout

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
