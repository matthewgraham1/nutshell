CXX=/usr/bin/g++
CXX_FLAGS=--std=c++17 -O2 -g

all: nutshell

lex.yy.cpp: lexer.l
	flex -o lex.yy.cpp lexer.l

lexer.o: lex.yy.cpp tokens.h
	$(CXX) $(CXX_FLAGS) -c -o lexer.o lex.yy.cpp

EnvTable.o: EnvTable.cpp EnvTable.h VariableTable.h
	$(CXX) $(CXX_FLAGS) -c EnvTable.cpp

AliasTable.o: AliasTable.cpp AliasTable.h VariableTable.h
	$(CXX) $(CXX_FLAGS) -c AliasTable.cpp

nutshell.o: nutshell.cpp tokens.h
	$(CXX) $(CXX_FLAGS) -c nutshell.cpp

nutshell: lexer.o nutshell.o EnvTable.o AliasTable.o #VariableTable.o 
	$(CXX) -o nutshell nutshell.o lexer.o EnvTable.o AliasTable.o -lm
