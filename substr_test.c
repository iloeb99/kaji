#include "str.h"

#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[])
{
    struct str s;
    initStr(&s);
    assignStr(&s, "Hello World!");
    struct str *sub = subStr(0, 5, &s);
    printStr(&s);
    printStr(sub);
    freeStr(sub);
    free(sub);
}