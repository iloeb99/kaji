#include "str.h"
#include <stdlib.h>
#include <string.h>

void initStr(struct str *string)
{
    string->s = NULL;
    string->length = 0;
}

void freeStr(struct str *string)
{
    if (string->s != NULL)
    {
        free(string->s);
        string->s = NULL;
        string->length = 0;
    }
}

struct str *assignStr(struct str *string, char *val)
{
    freeStr(string);

    string->length = strlen(val);
    string->s = malloc((string->length + 1) * sizeof(char));
    strcpy(string->s, val);

    return string;
}