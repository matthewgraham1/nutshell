%{
#include <iostream>
#include <stdio.h>
#include <vector>
#include "Command.h"
#include <string>
#include <vector>

int yylex(void);
Command command;

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
add_command(std::vector<std::string>* s_list)
{
	if (!(s_list)->size()) return;

	std::string called_command = (*s_list)[0];
	std::vector<std::string> arguments;
	for (int i = 1; i < s_list->size(); ++i) arguments.push_back((*s_list)[i]);

	command.add_command({ called_command, arguments, {}, ""});
}

void
run_command(int run_in_background)
{
	if (run_in_background)
                command.run(Command::RunIn::Background);
        else
                command.run(Command::RunIn::Foreground);
}


void
add_command_with_io_redirection(std::vector<std::string>* s_list, std::vector<std::string>* io_info)
{
	std::cout << "Statement:\n";
	print_s_list(s_list);
	std::cout << "IO Info:\n";
	print_s_list(io_info);

	std::string called_command = (*s_list)[0];
        std::vector<std::string> arguments;
        //Wildcard scanning
	for (int i = 1; i < s_list->size(); ++i) arguments.push_back((*s_list)[i]);

	if ((*io_info)[0] == ">")
	{
		command.add_command({ called_command, arguments, {{"1", (*io_info)[1], false}}, ""});
	}
	else if ((*io_info)[0] == ">>")
	{
		command.add_command({ called_command, arguments, {{"1", (*io_info)[1], true}}, ""});
	}
	else if ((*io_info)[0] == ">>&")
	{
		command.add_command({ called_command, arguments, {{called_command, (*io_info)[1], true}}, ""});
	}
	else if ((*io_info)[0] == ">&")
        {
                command.add_command({ called_command, arguments, {{called_command, (*io_info)[1], false}}, ""});
        }
	else if ((*io_info)[0] == "<")
        {
                command.add_command({ called_command, arguments, {}, (*io_info)[1]});
        }
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
%token <string> TOK_Great
%token <string> TOK_GreatGreat
%token <string> TOK_GreatGreatAmpersand
%token <string> TOK_GreatAmpersand
%token <string> TOK_Less

%token <int_t> TOK_END

%nterm <string> argument
%nterm <vector> stmt
%nterm <vector> io_redirect

%%

stmt	: /* Empty */	{ $$ = create_s_list(); }
	| stmt io_redirect { add_command_with_io_redirection($1, $2); $$ = create_s_list(); }
	| stmt argument { $$ = append_s_list($1, $2); }
	| stmt '|' { add_command($1); $$ = create_s_list(); }
	| stmt '&' '\n' { add_command($1); run_command(1); YYACCEPT; }
	| stmt '\n' { add_command($1); run_command(0); YYACCEPT; }
	| error '\n' { yyerrok; }
	;

io_redirect	: TOK_GreatGreat argument { $$ = create_s_list(); append_s_list($$, ">>"); append_s_list($$, $2); }
		| TOK_Great argument { $$ = create_s_list(); append_s_list($$, ">"); append_s_list($$, $2); }
		| TOK_GreatGreatAmpersand argument { $$ = create_s_list(); append_s_list($$, ">>&"); append_s_list($$, $2); }
		| TOK_GreatAmpersand argument { $$ = create_s_list(); append_s_list($$, ">&"); append_s_list($$, $2); }
		| TOK_Less argument { $$ = create_s_list(); append_s_list($$, "<"); append_s_list($$, $2); }
		| TOK_GreatGreat error '\n' { yyerrok; }
		;

argument: TOK_Word { $$ = $1; }
	;

%%
