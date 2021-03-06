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

struct str *subStr(int start, int end, const struct str *s)
{
    struct str *sub = (struct str *)malloc(sizeof(struct str));
    initStr(sub);
    int sublen = end - start;
    if (sublen > 0)
    {
        char subarr[sublen + 1];
        strncpy(subarr, s->data + start, sublen);
        subarr[sublen] = '\0';
        sub = assignStr(sub, subarr);
    }
    return sub;
}
int strLen(struct str *s)
{
    return s->length;
}

int strEq(struct str *s, struct str *t)
{
    return strcmp(s->data, t->data);
}

struct str *concatStr(struct str *s1, struct str *s2)
{
    struct str *res = (struct str *)malloc(sizeof(struct str));
    initStr(res);
    char con[s1->length + s2->length + 1];
    strcpy(con, s1->data);
    strcat(con, s2->data);
    res = assignStr(res, con);
    return res;
}
