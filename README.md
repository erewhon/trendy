# Trendy

WARNING: the below is very raw.  Not really for public consumption until I have
some time to clean things up.

## Fashionable, yet trendy

Trendy is a simple disk trend reporter and alerter. I created it as a
supplement to traditional threshold-based alerting. Sometimes alerts
are timely, but other times they can be unnecessary (slow growing
large disk), or totally missed (small, fast growing disk).

The motivation was a couple of articles

	http://lpenz.github.com/articles/df0pred-1/index.html

There are 2 phases:
- collection
- trend analysis

Collection consists of gathering the statistics.  Right now, it's a fairly
small, simple wrapper around Ruby.  You can have it collect statistics for a
given machine only, or you can have it run against multiple machines.  By
default, it is in "localhost" mode.  Eventually, there will be a way of
pulling statistics out of OpenTSDB or InfluxDB.

The trend analysis stage uses a Monte Carlo simulation.

These scripts are developed in a literate programming style.

Specifically, the Ruby is written using:

   http://rtomayko.github.com/rocco/

And R is written using

  http://yihui.name/knitr/

Perhaps.

To rebuild the documentation:

  groc scripts/*.rb README.md

# Example

For some example output, see ...

# Presentation

This is a placeholder to a mini-presentation describing my motivation.

Is this you?

Tale of 2 servers

# License

See UNLICENSE.  Basically, don't call me, I won't call you.

# References

# Todo

- increase linear component. For example, past 12 hours / samples.
  That way if we have a runaway process, we can estimate when that
  will cause us to run out of disk.

