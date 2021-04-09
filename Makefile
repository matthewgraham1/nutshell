CXX=/usr/bin/g++
CXX_FLAGS=--std=c++17 -O2 -g

all: nutshell

parser.cc: parser.y
	bison -d parser.y -o parser.cc

lex.yy.cpp: lexer.l
	flex -o lex.yy.cpp lexer.l

lexer.o: lex.yy.cpp tokens.h
	$(CXX) $(CXX_FLAGS) -c -o lexer.o lex.yy.cpp

EnvTable.o: EnvTable.cpp EnvTable.h VariableTable.h
	$(CXX) $(CXX_FLAGS) -c EnvTable.cpp

AliasTable.o: AliasTable.cpp AliasTable.h VariableTable.h
	$(CXX) $(CXX_FLAGS) -c AliasTable.cpp

Command.o: Command.cpp Command.h AliasTable.h EnvTable.h
	$(CXX) $(CXX_FLAGS) -c Command.cpp

nutshell.o: nutshell.cpp tokens.h
	$(CXX) $(CXX_FLAGS) -c nutshell.cpp

nutshell: parser.cc lexer.o nutshell.o EnvTable.o AliasTable.o Command.o
	$(CXX) -o nutshell nutshell.o parser.cc lexer.o EnvTable.o AliasTable.o Command.o -lm

clean:
	rm *.o *.hh *.cc
