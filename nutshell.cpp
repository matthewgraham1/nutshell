#include <string>
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include "parser.hh"

extern char* yytext;
extern std::string yyword; // replace this usage with yylword once yacc is used
int yylex(void);
extern FILE* yyin;

int
nutshell()
{
	int irrecoverable_status;
	std::string str;
	str.append(getenv("USER"));
	while (1) {
		printf("%s$ ", str.c_str());
		std::cout << yyparse() << "\n";
	}
}

int
main()
{
    yyin = stdin;
    nutshell();
    return 0;
}
