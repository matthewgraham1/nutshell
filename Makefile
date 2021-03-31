CC=/usr/bin/cc

all: nutshell

lex.yy.c: tokenizer.lex
	flex tokenizer.lex

nutshell-lexer.o: lex.yy.c tokens.h
	$(CC) -c -o nutshell-lexer.o lex.yy.c

nutshell.o: nutshell.c tokens.h
	$(CC) -g -c nutshell.c

nutshell: nutshell-lexer.o nutshell.o
	$(CC) -o nutshell nutshell.o nutshell-lexer.o -lm -lfl
