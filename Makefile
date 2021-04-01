CC=/usr/bin/g++

all: nutshell

lex.yy.cpp: tokenizer.lex
	flex -o lex.yy.cpp tokenizer.lex

nutshell-lexer.o: lex.yy.cpp tokens.h
	$(CC) -g -c -o nutshell-lexer.o lex.yy.cpp -O2

nutshell.o: nutshell.cpp tokens.h
	$(CC) -g -c nutshell.cpp -O2

nutshell: nutshell-lexer.o nutshell.o
	$(CC) -o nutshell nutshell.o nutshell-lexer.o -lm
