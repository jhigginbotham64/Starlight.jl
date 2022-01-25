# minimal script demo of Starlight
using Starlight

# load test file
a = App("test/test.yml")

# make sure we didn't silently fail
print(a)

# kick off
awake(a)

# keep process alive but invoke scheduler
while true
  yield()
end