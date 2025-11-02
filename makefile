# CS 218 Assignment 6 Makefile
# Simple makefile for ASM + C++ linking

OBJS = main.o
ASM = nasm -g -f elf64
CC = g++ -g -O0 -std=c++11 -z noexecstack -no-pie

all: main

main.o: main.asm
	$(ASM) main.asm -o main.o

main: main.cpp main.o
	$(CC) -o main main.cpp main.o

clean:
	rm -f $(OBJS) main *.lst

# Your added targets (updated with flags)
