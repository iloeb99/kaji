#include "kajilist.h"
#include <stdlib.h>
#include <string.h>

void initList(struct list *l)
{
    l->data = NULL;
    l->length = 0;
    l->capacity = 0;
}

void freeList(struct list *l)
{
    if (l->data != NULL)
    {
        free(l->data);
        initList(l);
    }
}

void expandList(struct list *l, int n)
{
    l->capacity += n;

    void **tmp = malloc(l->capacity * sizeof(void *));
    memcpy(tmp, l->data, l->length * sizeof(void *));

    free(l->data);
    l->data = tmp;
}

int listLen(struct list *l)
{
	return l->length;
}

void appendList(struct list *l, void *val)
{
    if (l->capacity == l->length)
    {
        expandList(l, l->capacity / 2 + 1);
    }

    l->data[l->length] = val;
    l->length++;
}

void *indexList(struct list *l, int i)
{
    if (i < 0 || i >= l->length)
    {
        return NULL;
    }

    return l->data[i];
}
