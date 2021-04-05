%option noyywrap
%option stack
%{
#include <pwd.h>
#include <string>
#include "EnvTable.h"
#include "AliasTable.h"
#include "tokens.h"

int variable_caller;

std::string yyword_builder;
std::string yyword;
std::string variable;

unsigned word_count = 1;

// for some reason this function is not declared in a way that lets 
// functions in this file use it, so this manual declaration lets that happen.
static void yyunput(int, char*);

void unput_string(const std::string& str)
{
    for (int i = str.length() - 1; i >= 0; i--)
	    unput(str[i]);
}

void expand_tilda_if_at_beginning(std::string& path)
{
    std::string substring;
    if (path.length() == 0)
        return;
    if (path[0] != '~')
        return;
    int i;
    for (i = 1; i < path.length(); i++) {
        if (path[i] == '/')
            break;
        substring.push_back(path[i]);
    }
    if (substring.length()) {
        auto* user = getpwnam(substring.c_str());
        substring = user ? user->pw_dir : "";
    } else
        substring = EnvTable::the().get("HOME");
    std::string mediator = move(substring);
    for (; i < path.length(); i++)
        mediator.push_back(path[i]);
    path = move(mediator);
}

%}

%x STRING
%x WORD
%x VARIABLE

%%

[&<>|\n] { word_count = 0; return *yytext; }
<*><<EOF>> { fprintf(stderr, "Unexpected end of file!\n"); }
<*>\$\{ { yy_push_state(VARIABLE); }

\" { BEGIN STRING; }
<STRING>\\\" { yyword_builder.push_back('"'); }
<STRING>\n { fprintf(stderr, "Unterminated quote!\n"); BEGIN 0; yyword_builder.clear(); return '\n'; /* How should an unterminated quote be punished if at all? */ }
<STRING>\" {
    BEGIN 0;
    yyword = move(yyword_builder);
    auto alias = AliasTable::the().get(yyword);
    if (word_count == 1 && alias != yyword) {
        unput_string(alias);
    } else {
        ++word_count;
        return TOK_Word;
    }
}
<STRING>. { yyword_builder.push_back(*yytext); }

\\[|<>&"] { BEGIN WORD; yyword_builder.push_back(yytext[1]); }
[^ \t\n] { BEGIN WORD; yyword_builder.push_back(*yytext); }
<WORD>\\[|<>&"] { yyword.push_back(yytext[1]); }
<WORD>[ \t\n|<>&"] {
    BEGIN 0;
    yyless(0);
    expand_tilda_if_at_beginning(yyword_builder);
    yyword = move(yyword_builder);
    auto alias = AliasTable::the().get(yyword);
    if (word_count == 1 && alias != yyword) {
        unput_string(alias);
    } else {
        ++word_count;
        return TOK_Word;
    }
}
<WORD>. { yyword_builder.push_back(*yytext); }

<VARIABLE>\} {
    yy_pop_state();
    unput_string(EnvTable::the().get(variable));
    variable.clear();
}
<VARIABLE>. { variable.push_back(*yytext); }

%%
