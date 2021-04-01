%option noyywrap
%{
#include <string>
#include "tokens.h"

std::string yyword_builder;
std::string yyword;

%}

%x STRING
%x WORD

%%

[&<>|\n] { return *yytext; }
<<EOF>> { exit(1); /* return EOF; exit maybe? */ }

\" { BEGIN STRING; }
<STRING>\\\" { yyword_builder.push_back('"'); }
<STRING>\n { fprintf(stderr, "Unterminated quote!\n"); BEGIN 0; return '\n'; /* How should an unterminated quote be punished if at all? */ }
<STRING>\" {
    BEGIN 0;
    yyword = move(yyword_builder);
    return TOK_Word;
}
<STRING>. { yyword_builder.push_back(*yytext); }

\\[|<>&"] { BEGIN WORD; yyword_builder.push_back(yytext[1]); }
[^ \t\n] { BEGIN WORD; yyword_builder.push_back(*yytext); }
<WORD>\\[|<>&"] { yyword.push_back(yytext[1]); }
<WORD>[ \t\n|<>&"] {
    BEGIN 0;
    yyless(0);
    yyword = move(yyword_builder);
    return TOK_Word;
}
<WORD>. { yyword_builder.push_back(*yytext); }

%%
