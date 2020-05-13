#include "str.h"

#include <stdio.h>

int main(int argc, char *argv[])
{
    struct str s;
    initStr(&s);
    assignStr(&s, "Hello World!");
    struct str sub;
    initStr(&sub);
    subStr(0, 5, &s, &sub);
    printStr(&s);
    printStr(&sub);
}