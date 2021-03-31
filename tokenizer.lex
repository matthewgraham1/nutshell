%{
#include "tokens.h"

char buf[1024];
char* yyword;

enum Token
construct_word()
{
    *yyword = '\0';
    yyword = strdup(buf);
    return TOK_Word;
}
%}

%x STRING
%x WORD

%%

\n { return TOK_Newline; }
& { return TOK_Ampersand; }
[<] { return TOK_LeftBracket; }
[>] { return TOK_RightBracket; }
[|] { return TOK_Pipe; }
<<EOF>> { return TOK_EOF; }

\" { BEGIN STRING; yyword = buf;}
<STRING>\\\" { *yyword++ = '"'; }
<STRING>\n { fprintf(stderr, "Unterminated quote!\n"); BEGIN 0; return TOK_Newline; /* How should an unterminated quote be punished if at all? */ }
<STRING>\" {
    BEGIN 0;
    return construct_word();
}
<STRING>. { *yyword++ = *yytext; }

\\[|<>&"] { BEGIN WORD; yyword = buf; *yyword++ = yytext[1]; }
[^ \t\n] { BEGIN WORD; yyword = buf; *yyword++ = *yytext; }
<WORD>\\[|<>&"] { *yyword++ = yytext[1]; }
<WORD>[ \t\n|<>&"] {
    BEGIN 0;
    yyless(0); // throws the matched character back to be lexed again in the INITIAL state.
    return construct_word();
}
<WORD>. { *yyword++ = *yytext; }

%%
