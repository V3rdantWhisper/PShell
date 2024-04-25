IP ?= 127.0.0.1
PORT ?= 4444
CFLAG := --static  
ASMFLAGS := -f bin
SOCKET_VAL := $(shell python3 convert.py $(IP) $(PORT))

all:
	nasm -DSOCKET_VAL=$(SOCKET_VAL) -o dawn ./Pshell.s $(ASMFLAGS)

debug:
	gcc -DDEBUG -DSOCKET_VAL=$(SOCKET_VAL) -g -o dawn ./Pshell.c $(CFLAG) 