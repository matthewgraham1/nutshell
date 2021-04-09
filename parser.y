%{
#include <stdio.h>

int yylex(void);

void
yyerror(char* s)
{
	fprintf(stderr, "%s\n", s);
}

%}

%define api.value.type union

%token <char*> TOK_EOF
%token <char*> TOK_Pipe
%token <char*> TOK_LeftBracket
%token <char*> TOK_RightBracket
%token <char*> TOK_Backslash
%token <char*> TOK_Ampersand
%token <char*> TOK_Word
%token <char*> TOK_QuotedWord
%token <char*> TOK_EnvOpen
%token <char*> TOK_EnvClose
%token <char*> TOK_Newline
%token <char*> TOK_Whitespace

%nterm <char const *> stmt
%nterm <char const **> s_list

%%

s_list: /* empty */
        | s_list stmt { printf("Statement: %s\n", $2); } ;

stmt:
	TOK_Word { $$ = "Word"; } 
	| TOK_Whitespace { $$ = "Whitespace"; }
	| TOK_Newline { $$ = "Newline"; }
	| TOK_EOF { $$ = "EOF"; }
	;


%%
