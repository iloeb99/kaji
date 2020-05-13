#include "str.h"
#include <stdio.h>
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

void copyStr(struct str *dest, struct str *src)
{
	dest->data = malloc((src->length + 1) * sizeof(char));
	dest->length = src->length;
	strcpy(dest->data, src->data);
}

int printStr(struct str *s)
{
	return printf("%s\n", s->data);
}

char *getData(struct str *s)
{
	return s->data;
}

int strLen(struct str *s)
{
	return s->length;
}

int strEq(struct str *s, struct str *t)
{
	return strcmp(s->data, t->data);
}
