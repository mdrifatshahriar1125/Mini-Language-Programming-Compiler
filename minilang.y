%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern int line_no;
extern FILE *yyin;

void yyerror(const char *s);

#define MAX_SYMBOLS 100

typedef struct {
    char name[50];
    char type[10];
    float value;
    int has_value;
} Symbol;

Symbol symbol_table[MAX_SYMBOLS];
int symbol_count = 0;

int lookup_symbol(char *name);
void insert_symbol(char *name, char *type);
void set_symbol_value(char *name, float value);
float get_symbol_value(char *name, int *found);
void print_symbol_table();
%}

%union {
    int num;
    float fnum;
    char *str;
    struct {
        char *str;
        float value;
        int has_value;
    } expr;
}

%token <str> IDENTIFIER
%token <num> INTEGER_VAL
%token <fnum> FLOAT_VAL
%token INT FLOAT STRING IF ELSE WHILE PRINT
%token PLUS MINUS MULT DIV ASSIGN
%token EQ NEQ LT GT LE GE
%token LPAREN RPAREN LBRACE RBRACE SEMICOLON

%type <expr> expression term factor condition

%left PLUS MINUS
%left MULT DIV
%nonassoc LT GT LE GE EQ NEQ

%%

program:
    statements
    {
        printf("\nCompilation finished successfully.\n");
        print_symbol_table();
    }
    ;

statements:
    statements statement
    | statement
    ;

statement:
    declaration
    | assignment
    | print_statement
    | if_statement
    | while_statement
    ;

declaration:
    INT IDENTIFIER SEMICOLON
    {
        insert_symbol($2, "int");
        printf("Declared integer variable: %s\n", $2);
    }
    | FLOAT IDENTIFIER SEMICOLON
    {
        insert_symbol($2, "float");
        printf("Declared float variable: %s\n", $2);
    }
    | STRING IDENTIFIER SEMICOLON
    {
        insert_symbol($2, "string");
        printf("Declared string variable: %s\n", $2);
    }
    ;

assignment:
    IDENTIFIER ASSIGN expression SEMICOLON
    {
        printf("Assignment: %s = %.2f\n", $1, $3.value);
        set_symbol_value($1, $3.value);
        free($1);
        free($3.str);
    }
    ;

print_statement:
    PRINT expression SEMICOLON
    {
        if ($2.has_value) {
            printf("Output: %.2f\n", $2.value);
        } else {
            int found;
            float val = get_symbol_value($2.str, &found);
            if (found) {
                printf("Output: %.2f\n", val);
            } else {
                printf("Output: undefined\n");
            }
        }
        free($2.str);
    }
    ;

if_statement:
    IF LPAREN condition RPAREN LBRACE statements RBRACE
    {
        if ($3.value != 0) {
            printf("IF condition true\n");
        } else {
            printf("IF condition false\n");
        }
    }
    | IF LPAREN condition RPAREN LBRACE statements RBRACE ELSE LBRACE statements RBRACE
    {
        if ($3.value != 0) {
            printf("IF condition true\n");
        } else {
            printf("ELSE branch executed\n");
        }
    }
    ;

while_statement:
    WHILE LPAREN condition RPAREN LBRACE statements RBRACE
    {
        int counter = 0;
        while ($3.value != 0 && counter < 5) {
            printf("WHILE loop iteration %d\n", counter);
            counter++;
            if (counter >= 5) break;
        }
    }
    ;

condition:
    expression EQ expression
    {
        $$.value = ($1.value == $3.value);
        $$.has_value = 1;
        $$.str = strdup("cond");
    }
    | expression NEQ expression
    {
        $$.value = ($1.value != $3.value);
        $$.has_value = 1;
        $$.str = strdup("cond");
    }
    | expression LT expression
    {
        $$.value = ($1.value < $3.value);
        $$.has_value = 1;
        $$.str = strdup("cond");
    }
    | expression GT expression
    {
        $$.value = ($1.value > $3.value);
        $$.has_value = 1;
        $$.str = strdup("cond");
    }
    | expression LE expression
    {
        $$.value = ($1.value <= $3.value);
        $$.has_value = 1;
        $$.str = strdup("cond");
    }
    | expression GE expression
    {
        $$.value = ($1.value >= $3.value);
        $$.has_value = 1;
        $$.str = strdup("cond");
    }
    ;

expression:
    expression PLUS term
    {
        $$.str = strdup("tmp");
        $$.value = $1.value + $3.value;
        $$.has_value = 1;
    }
    | expression MINUS term
    {
        $$.str = strdup("tmp");
        $$.value = $1.value - $3.value;
        $$.has_value = 1;
    }
    | term
    {
        $$ = $1;
    }
    ;

term:
    term MULT factor
    {
        $$.str = strdup("tmp");
        $$.value = $1.value * $3.value;
        $$.has_value = 1;
    }
    | term DIV factor
    {
        $$.str = strdup("tmp");
        if ($3.value != 0) {
            $$.value = $1.value / $3.value;
            $$.has_value = 1;
        } else {
            $$.value = 0;
            $$.has_value = 0;
        }
    }
    | factor
    {
        $$ = $1;
    }
    ;

factor:
    LPAREN expression RPAREN
    {
        $$ = $2;
    }
    | IDENTIFIER
    {
        int found;
        float val = get_symbol_value($1, &found);
        $$.str = strdup($1);
        if (found) {
            $$.value = val;
            $$.has_value = 1;
        } else {
            $$.value = 0;
            $$.has_value = 0;
        }
    }
    | INTEGER_VAL
    {
        char *temp = (char*)malloc(20);
        sprintf(temp, "%d", $1);
        $$.str = temp;
        $$.value = (float)$1;
        $$.has_value = 1;
    }
    | FLOAT_VAL
    {
        char *temp = (char*)malloc(20);
        sprintf(temp, "%.2f", $1);
        $$.str = temp;
        $$.value = $1;
        $$.has_value = 1;
    }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error at line %d: %s\n", line_no, s);
}

int lookup_symbol(char *name) {
    for (int i = 0; i < symbol_count; i++) {
        if (strcmp(symbol_table[i].name, name) == 0) {
            return i;
        }
    }
    return -1;
}

void insert_symbol(char *name, char *type) {
    if (lookup_symbol(name) != -1) {
        printf("Warning: Variable '%s' already declared!\n", name);
        return;
    }
    strcpy(symbol_table[symbol_count].name, name);
    strcpy(symbol_table[symbol_count].type, type);
    symbol_table[symbol_count].has_value = 0;
    symbol_table[symbol_count].value = 0;
    symbol_count++;
}

void set_symbol_value(char *name, float value) {
    int index = lookup_symbol(name);
    if (index != -1) {
        symbol_table[index].value = value;
        symbol_table[index].has_value = 1;
    }
}

float get_symbol_value(char *name, int *found) {
    int index = lookup_symbol(name);
    if (index != -1 && symbol_table[index].has_value) {
        *found = 1;
        return symbol_table[index].value;
    }
    *found = 0;
    return 0;
}

void print_symbol_table() {
    printf("\nSymbol Table:\n");
    printf("%-15s %-10s %-15s\n", "Name", "Type", "Value");
    for (int i = 0; i < symbol_count; i++) {
        if (symbol_table[i].has_value) {
            printf("%-15s %-10s %-15.2f\n",
                   symbol_table[i].name,
                   symbol_table[i].type,
                   symbol_table[i].value);
        } else {
            printf("%-15s %-10s %-15s\n",
                   symbol_table[i].name,
                   symbol_table[i].type,
                   "undefined");
        }
    }
}
