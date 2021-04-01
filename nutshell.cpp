#include <string>
#include <stdio.h>
#include <stdlib.h>
#include "tokens.h"

extern char* yytext;
extern char* yyword; // replace this usage with yylword once yacc is used
int yylex(void);
extern FILE* yyin;

void
handle_line()
{
    int token;
    do {
        token = yylex();
        if (token == EOF)
            exit(0);

        if (token == TOK_Word) {
            printf("Word is: %s\n", yyword);
            free(yyword);
        } else
            printf("Token matched is: %u\n", token);
    } while (token != '\n');
}

int
nutshell()
{
    std::string str;
    str.append(getenv("USER"));
    while (1) {
        printf("%s$ ", str.c_str());
        handle_line();
    }
}

int
main()
{
    yyin = stdin;
    nutshell();
    return 0;
}
