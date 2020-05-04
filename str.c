#include "str.h"
#include <stdlib.h>
#include <string.h>

void initStr(struct str *s)
{
    s->data = NULL;
    s->length = 0;
}

void freeStr(struct str *s)
{
    if (s->data != NULL)
    {
        free(s->data);
        initStr(s);
    }
}

struct str *assignStr(struct str *s, char *val)
{
    freeStr(s);

    s->length = strlen(val);
    s->data = malloc((s->length + 1) * sizeof(char));
    strcpy(s->data, val);

    return s;
}
