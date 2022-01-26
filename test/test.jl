# minimal script demo of Starlight
using Starlight

# load test file
a = App("test/test.yml")

# kick off
# run with JULIA_DEBUG=Starlight to see clock messages
awake(a)