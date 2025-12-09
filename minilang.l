%{
#include "minilang.tab.h"
#include <string.h>
#include <stdlib.h>

int line_no = 1;   /* declare line_no here */
%}

%option noyywrap

DIGIT       [0-9]
LETTER      [a-zA-Z_]
ID          {LETTER}({LETTER}|{DIGIT})*
INTEGER     {DIGIT}+
FLOAT       {DIGIT}+"."{DIGIT}+
WHITESPACE  [ \t]+

%%

"int"       { return INT; }
"float"     { return FLOAT; }
"string"    { return STRING; }
"if"        { return IF; }
"else"      { return ELSE; }
"while"     { return WHILE; }
"print"     { return PRINT; }

{ID}        { yylval.str = strdup(yytext); return IDENTIFIER; }
{INTEGER}   { yylval.num = atoi(yytext); return INTEGER_VAL; }
{FLOAT}     { yylval.fnum = atof(yytext); return FLOAT_VAL; }

"+"         { return PLUS; }
"-"         { return MINUS; }
"*"         { return MULT; }
"/"         { return DIV; }
"="         { return ASSIGN; }
"=="        { return EQ; }
"!="        { return NEQ; }
"<"         { return LT; }
">"         { return GT; }
"<="        { return LE; }
">="        { return GE; }

"("         { return LPAREN; }
")"         { return RPAREN; }
"{"         { return LBRACE; }
"}"         { return RBRACE; }
";"         { return SEMICOLON; }

\n          { line_no++; }
{WHITESPACE} { /* skip whitespace */ }

.           { printf("Unknown character: %s at line %d\n", yytext, line_no); }

%%
