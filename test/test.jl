# minimal script demo of Starlight
using Starlight

# load test file
a = App("test/test.yml")

# make sure we didn't silently fail be verifying config values
print(a)

# kick off
# run with JULIA_DEBUG=all to see clock messages
awake(a)