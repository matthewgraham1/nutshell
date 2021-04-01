CC=/usr/bin/g++

all: nutshell

lex.yy.cpp: lexer.l
	flex -o lex.yy.cpp lexer.l

lexer.o: lex.yy.cpp tokens.h
	$(CC) -g -c -o lexer.o lex.yy.cpp -O2

nutshell.o: nutshell.cpp tokens.h
	$(CC) -g -c nutshell.cpp -O2

nutshell: lexer.o nutshell.o
	$(CC) -o nutshell nutshell.o lexer.o -lm
