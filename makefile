TARGET = dist/server
CLIENT = dist/sh13

SOURCES = $(wildcard *.c)


all: $(TARGET) run


$(TARGET): $(SOURCES)
	@gcc -o dist/sh13 -I/usr/include/SDL2 sh13.c -lSDL2_image -lSDL2_ttf -lSDL2 -lpthread
	@gcc -o dist/server server.c

run: $(TARGET)
	@./$(TARGET) 3200
	@./$(CLIENT) 127.0.0.1 32000 127.0.0.1 32001 Player1
	@./$(CLIENT) 127.0.0.1 32000 127.0.0.2 32002 Player2

clean:
	@rm -f $(TARGET)

