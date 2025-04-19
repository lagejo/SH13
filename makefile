TARGET = dist/server
CLIENT = dist/sh13

SOURCES = $(wildcard *.c)


all: dist $(TARGET) run

dist:
	@mkdir -p dist

$(TARGET): $(SOURCES)
	@gcc -o dist/sh13 -I/usr/include/SDL2 sh13.c -lSDL2_image -lSDL2_ttf -lSDL2 -lpthread
	@gcc -o dist/server server.c

run: $(TARGET)
	@./$(TARGET) 32000 &
	@./$(CLIENT) 127.0.0.1 32000 127.0.0.1 32001 Player1 &
	@./$(CLIENT) 127.0.0.1 32000 127.0.0.2 32002 Player2 &
	@./$(CLIENT) 127.0.0.1 32000 127.0.0.3 32003 Player3 &
	@./$(CLIENT) 127.0.0.1 32000 127.0.0.4 32004 Player4 &
	@wait

clean:
	@rm -f $(TARGET)

