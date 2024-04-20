IP ?= 127.0.0.1
PORT ?= 4444
CFLAG := --static -s
SOCKET_VAL := $(shell python convert.py $(IP) $(PORT))

all:
	gcc -DSOCKET_VAL=$(SOCKET_VAL) -o Pshell ProtectShell.c $(CFLAG)

debug:
	gcc -DSOCKET_VAL=$(SOCKET_VAL) -DDEBUG -o dawn ProtectShell.c $(CFLAG)