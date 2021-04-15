#include <string>
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include "Command.h"
#include "parser.hh"

extern char* yytext;
extern std::string yyword; // replace this usage with yylword once yacc is used
int yylex(void);
extern FILE* yyin;

int
nutshell()
{
	std::string str;
	str.append(getenv("USER"));
	while (1) {
		printf("%s$ ", str.c_str());
		yyparse();
	}
}

int
main()
{
    yyin = stdin;
    nutshell();
    return 0;
}
