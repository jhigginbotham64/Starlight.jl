# minimal script demo of Starlight
using Starlight
a = App("test/test.yml")
print(a)
awake(a)
while true
  yield()
end