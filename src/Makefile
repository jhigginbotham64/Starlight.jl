CFLAGS = -std=c++2a -O2
LDFLAGS = -lSDL2 -lvulkan

telescope: Telescope.cpp
	g++ $(CFLAGS) -o telescope Telescope.cpp $(LDFLAGS)

.PHONY: test clean

test: telescope
	./telescope

clean:
	rm -f telescope