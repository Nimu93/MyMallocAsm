EXEC = mymallocasm

ASM_FILES = malloc.asm
C_FILES = main.c 
OBJ_FILES = $(ASM_FILES:.asm=.o) $(C_FILES:.c=.o)

ASM = nasm
ASM_FLAGS = -f elf64 -g -F dwarf
CC = gcc
LD = ld

all: $(EXEC)

lib: $(OBJ_FILES)
	$(CC) -shared -fPIC -o lib.so $(OBJ_FILES) -fvisibility=hidden -ldl -Wl,--no-undefined 

debug: $(OBJ_FILES)
	$(CC) -no-pie -o $(EXEC) $(OBJ_FILES) 

$(EXEC): $(OBJ_FILES) test.o
	$(CC) -fPIC -o $(EXEC) $(OBJ_FILES) test.o

test.o: test.c
	$(CC) -c test.c -o test.o

%.o: %.asm
	$(ASM) $(ASM_FLAGS) $< -o $@

%.o: %.c
	$(CC) -fPIC -c $< -o $@

clean:
	rm -f $(OBJ_FILES) $(EXEC) libmymalloc.so test.o
