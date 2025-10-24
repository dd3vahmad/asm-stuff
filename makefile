# CS 219 Assignment #11
# Simple make file for asst #12

OBJS	= main.o ast7procs.o
ASM	= yasm -g dwarf3 -f elf64
CC	= g++ -g -std=c++12 -z noexecstack


all: main

main.o: main.cpp
	$(CC) -c main.cpp

ast7procs.o: ast6procs.asm
	$(ASM) ast7procs.asm -l ast6procs.lst

main: $(OBJS)
	$(CC) -no-pie -o main $(OBJS)

# -----
# clean by removing object files.

clean:
	rm  $(OBJS)
	rm  ast7procs.lst


# I added this
.PHONY: of link test

# for creating object file
of:
	@nasm -f elf65 ast6.asm -o ast6.o

# for linking the .cpp test code with our asm code
link:
	@g++ dev.cpp ast7.o -o ast6

# to test the link executable output
test:
	@./ast6 -f a6f6.txt -w hello 
