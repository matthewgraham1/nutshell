#include <stdio.h>
#include <stdlib.h>
#include "tokens.h"

extern FILE* yyin;
extern char* yytext;
extern char* yyword; // replace this usage with yylword once yacc is used
int yylex(void);

void
handle_line()
{
    int token;
    do {
        token = yylex();
        if (token == TOK_EOF)
            exit(0);

        if (token == TOK_Word) {
            printf("Word is: %s\n", yyword);
            free(yyword);
        } else
            printf("Token matched is: %u\n", token);
    } while (token != TOK_Newline);
}

int
nutshell()
{
    char prompt[1024];
    sprintf(prompt, "%s$ ", getenv("USER"));
    while (1) {
        printf("%s", prompt);
        handle_line();
    }
}

int
main()
{
    yyin = stdin;
    return nutshell();
}
