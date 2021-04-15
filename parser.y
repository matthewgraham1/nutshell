%{
#include <iostream>
#include <stdio.h>
#include <vector>
#include "Command.h"
#include <string>
#include <vector>

int yylex(void);

int
yywrap(void)
{
	return 1;
}

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
	std::vector<std::string>* new_s_list;
	new_s_list->reserve(s_list->size() + stmt->size());
        new_s_list->insert(new_s_list->end(), s_list->begin(), s_list->end());
	new_s_list->insert(new_s_list->end(), stmt->begin(), stmt->end());
	
        return new_s_list;
}

std::vector<std::string>*
append_s_list(std::vector<std::string>* s_list, std::string* word)
{
	(*s_list).push_back(*word);
	return s_list;
}

std::vector<std::string>*
append_s_list(std::vector<std::string>* s_list, std::string word)
{
        (*s_list).push_back(word);
        return s_list;
}

void
print_s_list(std::vector<std::string>* s_list)
{
	for(int i = 0; i < s_list->size(); ++i)
	{
		std::cout << (*s_list)[i] << " ";
	}
	std::cout << "\n";
}

void
execute_command(std::vector<std::string>* s_chain, int run_in_background)
{
	if (!(s_chain)->size()) return;

	Command command;

	std::string called_command;
	std::vector<std::string> arguments;
	for (int j = 0; j < s_chain->size(); ++j)
	{
		called_command = (*s_chain)[j++];
		arguments = {};

		for (int i = j; i < s_chain->size() && (*s_chain)[i] != "|"; ++i, ++j) arguments.push_back((*s_chain)[i]);
		//if ((*s_chain)[j] == "|") ++j;

		// The final string argument is if there is an input file
	
		//std::cout << "Command: " << command << "\nArguments:";
	
		//print_s_list(&arguments);
	
		command.add_command({ called_command, arguments, {}, ""});
	}

	if (run_in_background)
		command.run(Command::RunIn::Background);
	else
		command.run(Command::RunIn::Foreground);
}

%}

%union 
{
	int int_t;
	const char *char_ptr_t;
	std::string *string;
	std::vector<std::string> *vector;
}

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

%token <int_t> TOK_END

%nterm <string> argument
%nterm <vector> stmt

%%

stmt	: /* Empty */	{ $$ = create_s_list(); }
	| stmt argument { $$ = append_s_list($1, $2); }
	| stmt '|' { $$ = append_s_list($$, "|"); }
	| stmt '\n' { execute_command($1, 0); YYACCEPT; }
        | stmt '&' '\n' { execute_command($1, 1); YYACCEPT; }
	;

argument: TOK_Word { $$ = $1; }
	;

%%
