%{
#include <stdio.h>
#include <vector>
#include "Command.h"
#include <string.h>

int yylex(void);

Command command;

void
yyerror(const char* s)
{
	fprintf(stderr, "%s\n", s);
}

char**
create_s_list(void)
{
	
	char** s_list = new char*[1];
	s_list[0] = "\0";
	return s_list;
}

char**
append_s_list(char** s_list, char** stmt)
{
	int size = 0;
        for(; s_list[size] != "\0"; ++size);
	int stmt_size = 0;
	for(; stmt[stmt_size] != "\0"; ++stmt_size);
        char** ret_s_list = new char*[size+stmt_size+1];
        for(int i=0; i < size; ++i)
        {
                ret_s_list[i] = s_list[i];
        }
        for(int i=size; i < size+stmt_size; ++i)
        {
                ret_s_list[i] = stmt[i];
        }
        ret_s_list[size+stmt_size] = "\0";
	
        return ret_s_list;
}

char**
append_s_list(char** s_list, char* word)
{
	int size = 0;
	for(; s_list[size] != "\0"; ++size);
	char** ret_s_list = new char*[++size+1];
	for(int i=0; i < size-1; ++i)
	{
		ret_s_list[i] = s_list[i];
	}
	ret_s_list[size-1] = word;
	ret_s_list[size] = "\0";
	return ret_s_list;
}

void
print_s_list(char** s_list)
{
	printf("Printing:\n");
	for(int i = 0; s_list[i] != "\0"; ++i)
	{
		printf("%s\n", s_list[i]);
	}
}


%}

%union 
{
	int int_t;
	char* char_ptr_t;
	char** str_list_t;
}

%define parse.error verbose

%token <char_ptr_t> TOK_Pipe
%token <char_ptr_t> TOK_LeftBracket
%token <char_ptr_t> TOK_RightBracket
%token <char_ptr_t> TOK_Backslash
%token <char_ptr_t> TOK_Ampersand
%token <char_ptr_t> TOK_Word
%token <char_ptr_t> TOK_QuotedWord
%token <char_ptr_t> TOK_EnvOpen
%token <char_ptr_t> TOK_EnvClose
%token <char_ptr_t> TOK_Newline
%token <char_ptr_t> TOK_Whitespace

%nterm <char_ptr_t> command
%nterm <char_ptr_t> argument
%nterm <str_list_t> stmt
%nterm <str_list_t> s_list

%%

s_list	: /* empty */ { $$ = create_s_list(); }
        | s_list stmt { $$ = append_s_list($1, $2); }
	;

stmt	: command { $$ = new char*[2]; $$[0] = $1; $$[1] = "\0"; printf("command\n"); }
	| command argument { $$ = new char*[3]; $$[0] = $1; $$[1] = $2; $$[2] = "\0"; printf("command + arg\n"); }
	| command argument argument { $$ = new char*[4]; $$[0] = $1; $$[1] = $2; $$[2] = $3; $$[3] = "\0"; printf("command + arg + arg\n"); }
	;

command	: TOK_Word { $$ = $1; }
	;

argument: TOK_Word { $$ = $1; }
	;

%%
