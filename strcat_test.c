#include "str.h"
#include <stdlib.h>

int main(int argc, char *argv[]) 
{
    struct str s;
    initStr(&s);
    assignStr(&s, "Hello ");
    struct str t;
    initStr(&t);
    assignStr(&t, "World!");
    struct str *concatted_str = concatStr(&s, &t);
    printStr(concatted_str);
    freeStr(concatted_str);
    free(concatted_str);
}