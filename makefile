TARGET = dist/server
CLIENT = dist/sh13
PORT = 43529

SOURCES = $(wildcard *.c)


all: dist $(TARGET) run

dist:
	@mkdir -p dist

$(TARGET): $(SOURCES)
	@gcc -o dist/sh13 -I/usr/include/SDL2 sh13.c -lSDL2_image -lSDL2_ttf -lSDL2 -lpthread
	@gcc -o dist/server server.c

run: $(TARGET)
	@./$(TARGET) $(PORT)  &
	@./$(CLIENT) 127.0.0.1 $(PORT)  127.0.0.1 $(shell echo $$(($(PORT) + 1))) Alice &
	@./$(CLIENT) 127.0.0.1 $(PORT)  127.0.0.2 $(shell echo $$(($(PORT) + 2))) Bob &
	@./$(CLIENT) 127.0.0.1 $(PORT)  127.0.0.3 $(shell echo $$(($(PORT) + 3))) Charlie &
	@./$(CLIENT) 127.0.0.1 $(PORT)  127.0.0.4 $(shell echo $$(($(PORT) + 4))) Daniel &
	@wait

clean:
	@rm -f $(TARGET)

