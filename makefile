# CS 218 Assignment #11
# Simple make file for asst #11

OBJS	= main.o ast6procs.o
ASM	= yasm -g dwarf2 -f elf64
CC	= g++ -g -std=c++11 -z noexecstack

all: main

main.o: main.cpp
	$(CC) -c main.cpp

ast6procs.o: ast6procs.asm
	$(ASM) ast6procs.asm -l ast6procs.lst

main: $(OBJS)
	$(CC) -no-pie -o main $(OBJS)

# -----
# clean by removing object files.

clean:
	rm  $(OBJS)
	rm  ast6procs.lst

