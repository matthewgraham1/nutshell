%option noyywrap
%option stack
%{
#include <pwd.h>
#include <unistd.h>
#include <string>
#include <vector>
#include <fnmatch.h>
#include <filesystem>
#include "EnvTable.h"
#include "AliasTable.h"
#include "parser.hh"

int variable_caller;

std::string yyword_builder;
std::string yyword;
std::string variable;

unsigned line_count = 1;
unsigned word_count = 1;

// for some reason this function is not declared in a way that lets 
// functions in this file use it, so this manual declaration lets that happen.
static void yyunput(int, char*);

void unput_string(const std::string& str)
{
    for (int i = str.length() - 1; i >= 0; i--)
	    unput(str[i]);
}

void normalize_path_if_needed(std::string& path)
{
    if (!path.length()) {
        return;
    }
    if (path[0] == '/') {
        path = std::filesystem::path(std::move(path)).lexically_normal();
        return;
    }
    if (path[0] != '.') {
        return;
    }
    char cwd[1024];
    getcwd(cwd, 1024);
    std::string resolved_path;
    resolved_path.append(cwd);
    resolved_path.push_back('/');
    resolved_path.append(path);
    path = std::filesystem::path(std::move(resolved_path)).lexically_normal();
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

bool is_glob(const std::string& word)
{
    for (auto c : word) {
        if (c == '*' || c == '?') {
            return true;
    }
}
return false;
}

bool match_glob_if_exists(const std::string& word)
{
    if (!word.length())
	return false;
    std::string parent_directory;
    std::string glob;
    if (!is_glob(word)) {
        return false;
    }
    if (word[0] == '/') {
	std::string dir_name;
	parent_directory.push_back('/');
	bool glob_found = false;
	for (char c : word) {
	    if (c == '*' || c == '?') {
            glob_found = true;
            glob.append(dir_name);
            glob.push_back(c);
            dir_name.clear();
            continue;
	    }
	    
	    if (glob_found) {
            if (c == '/') {
                break;
            }
            glob.push_back(c);
	    }
		    
	    if (c == '/') {
	        parent_directory.push_back(c);
            parent_directory.append(dir_name);
            dir_name.clear();
            continue;
	    }
	    dir_name.push_back(c);
	}
    } else {
        glob = word;
        char cwd[1024];
        getcwd(cwd, 1024);
        parent_directory = cwd;
    }
    bool matched_at_least_one = false;
    for (auto& file : std::filesystem::directory_iterator(parent_directory)) {
        printf("Current file to be checked against %s: %s\n", glob.c_str(), file.path().filename().c_str());
        if (!fnmatch(glob.c_str(), file.path().filename().c_str(), 0)) {
            unput_string(file.path());
            unput(' ');
            matched_at_least_one = true;
        }
    }
    return matched_at_least_one;
}

%}

%x STRING
%x WORD
%x VARIABLE

%%

[&|] { word_count = 1; return *yytext; }
[>] { word_count = 1; return TOK_Great; }
">>" { word_count = 1; return TOK_GreatGreat; }
">&" { word_count = 1; return TOK_GreatAmpersand; }
">>&" { word_count = 1; return TOK_GreatGreatAmpersand; }
[<] { word_count = 1; return TOK_Less; }
[\n] { word_count = 1; line_count++; return *yytext; }

<*><<EOF>> { fprintf(stderr, "Unexpected end of file!\n"); }
<*>\$\{ { yy_push_state(VARIABLE); }
<*>\\\$ { yyword_builder.push_back('$'); }
\" { BEGIN STRING; }
<STRING>\\\" { yyword_builder.push_back('"'); }
<STRING>\n { fprintf(stderr, "Unterminated quote!\n"); BEGIN 0; yyword_builder.clear(); ++line_count; return '\n'; /* How should an unterminated quote be punished if at all? */ }
<STRING>\" {
    BEGIN 0;
    normalize_path_if_needed(yyword_builder); // Should quoted dots be expanded? Tilda isn't supposed to be.
    yyword = std::move(yyword_builder);
    if (!match_glob_if_exists(yyword)) {
        auto alias = AliasTable::the().get(yyword);
        if (word_count == 1 && alias != yyword) {
            unput_string(alias);
        } else {
            ++word_count;
            return TOK_Word;
        }
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
    normalize_path_if_needed(yyword_builder);
    yyword = std::move(yyword_builder);

  if (!match_glob_if_exists(yyword)) {
    auto alias = AliasTable::the().get(yyword);
    if (word_count == 1 && alias != yyword) {
        unput_string(alias);
    } else {
      ++word_count;
      yylval.string = &yyword;
      return TOK_Word;
    }
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
