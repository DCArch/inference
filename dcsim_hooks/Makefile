# Makefile for building DCSim hooks shared library

CC = gcc
CFLAGS = -fPIC -O2 -Wall
LDFLAGS = -shared

LIB_NAME = libdcsim_hooks.so
SRC = dcsim_hooks.c
OBJ = $(SRC:.c=.o)

all: $(LIB_NAME)

$(LIB_NAME): $(OBJ)
	$(CC) $(LDFLAGS) -o $@ $^

%.o: %.c DCSim.h
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJ) $(LIB_NAME)

.PHONY: all clean
