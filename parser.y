%{
#include <iostream>
#include <stdio.h>
#include <vector>
#include "Command.h"
#include <string>
#include <vector>

int yylex(void);

void
yyerror(const char* s)
{
	fprintf(stderr, "%s\n", *s);
}

std::vector<std::string>*
create_s_list(void)
{
	
	std::vector<std::string>* s_list = new std::vector<std::string>(0);
	return s_list;
}

std::vector<std::string>*
append_s_list(std::vector<std::string>* s_list, std::vector<std::string>* stmt)
{
        std::vector<std::string> new_s_list;
	new_s_list.reserve(s_list->size() + stmt->size());
        new_s_list.insert(new_s_list.end(), s_list->begin(), s_list->end());
	new_s_list.insert(new_s_list.end(), stmt->begin(), stmt->end());
	
        return &new_s_list;
}

std::vector<std::string>*
append_s_list(std::vector<std::string>* s_list, std::string* word)
{
	(*s_list).push_back(*word);
	return s_list;
}

void
print_s_list(std::vector<std::string>* s_list)
{
	printf("Printing:\n");
	for(int i = 0; i < s_list->size(); ++i)
	{
		std::cout << (*s_list)[i] << " ";
	}
	std::cout << "\n";
}

std::vector<std::string>*
execute_command(std::vector<std::string>* s_list)
{
	Command command = Command();
	Command::Node node;
	node.name = (*s_list)[0];
	node.arguments.reserve(s_list->size() - 1);
	node.arguments.insert(node.arguments.end(), s_list->begin() + 1, s_list->end());

	command.add_command(node);
}

%}

%union 
{
	int int_t;
	const char *char_ptr_t;
	std::string *string;
	std::vector<std::string> *vector;
}

%define parse.error verbose

%token <string> TOK_Pipe
%token <string> TOK_LeftBracket
%token <string> TOK_RightBracket
%token <string> TOK_Backslash
%token <string> TOK_Ampersand
%token <string> TOK_Word
%token <string> TOK_QuotedWord
%token <string> TOK_EnvOpen
%token <string> TOK_EnvClose
%token <string> TOK_Newline
%token <string> TOK_Whitespace

%nterm <string> argument
%nterm <vector> stmt

%%

stmt	: argument { $$ = create_s_list(); $$ = append_s_list($$, $1); }
	| stmt argument { $$ = append_s_list($1, $2); }
	| stmt '|' { $$ = execute_command($1); }
	| stmt { $$ = execute_command($1); }
	;

argument: TOK_Word
	;

%%
