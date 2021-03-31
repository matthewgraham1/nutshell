#pragma once

enum Token {
    TOK_EOF,
    TOK_Pipe,
    TOK_LeftBracket,
    TOK_RightBracket,
    TOK_Backslash,
    TOK_Ampersand,
    TOK_Word,
    TOK_QuotedWord,
    TOK_EnvOpen,
    TOK_EnvClose,
    TOK_Newline,
    TOK_Whitespace, // Newline and Whitespace in this shell context are two separate concepts.
};
