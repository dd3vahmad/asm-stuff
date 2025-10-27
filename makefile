# CS 218 Assignment 6 Makefile
# Simple makefile for ASM + C++ linking

OBJS = ast6.o
ASM = nasm -g -f elf64
CC = g++ -g -O0 -std=c++11 -z noexecstack -no-pie

all: ast6

ast6.o: ast6.asm
	$(ASM) ast6.asm -o ast6.o

ast6: dev.cpp ast6.o
	$(CC) -o ast6 dev.cpp ast6.o

clean:
	rm -f $(OBJS) ast6 *.lst

# Your added targets (updated with flags)
.PHONY: of link test run dbg

of:
	@nasm -g -f elf64 ast6.asm -o ast6.o

link:
	@$(CC) -g dev.cpp ast6.o -o ast6

test:
	@./ast6 -f a6f3.txt -w hello_ahmad_rabiu_12

run: of link test

testT:
	@time ./ast6 -f a6f3.txt -w hello

runT: of link testT

dbg:
	@gdb ./ast6

# GDB shortcuts (run in GDB session)
brkp:
	@break checkParams

runt:
	@run -f a6f3.txt -w hello

step:
	@si

next:
	@ni
