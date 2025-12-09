#include <stdio.h>

int yyparse(void);

int main(int argc, char *argv[]) {
    printf("MiniLang Compiler started...\n");
    if (yyparse() == 0) {
        printf("Parsing finished successfully.\n");
    } else {
        printf("Parsing failed.\n");
    }
    return 0;
}
