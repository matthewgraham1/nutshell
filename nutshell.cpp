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
		std::cout << "\n";
	}
}

int
main()
{
    yyin = stdin;
    Command command;
    // The final string argument is if there is an input file
    //command.add_command({ "printenv", { }, { {"1", "other_test", false /* true says append, false says don't append */}, {"2", "&1", false /* same here */}}, ""});
    //command.add_command({ "grep", {"bin"}, {}, ""});
    //command.add_command({ "wc", {"-l"}, {{"1", "test_output", true}}, ""});
    //command.run(Command::RunIn::Background);
    nutshell();
    return 0;
}
