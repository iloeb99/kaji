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

int fprintStr(struct str *f, struct str *s, int append)
{
    FILE *fp;
    char *flag;

    if (append)
        flag = "a";
    else
        flag = "w";

    fp = fopen(f->data, flag);
    fputs(s->data, fp);
    fclose(fp);

    return 0;
}

void subStr(int start, int end, const struct str *s, struct str *sub)
{
    int sublen = end - start;
    if (sublen > 0)
    {
        sub->length = sublen;
        sub->data = malloc(sublen + 1 * sizeof(char));
        strncpy(sub->data, s->data + start, end - start);
        sub->data[sublen] = '\0';
    }
}
int strLen(struct str *s)
{
    return s->length;
}

int strEq(struct str *s, struct str *t)
{
    return strcmp(s->data, t->data);
}
