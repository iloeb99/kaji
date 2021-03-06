struct list
{
    void **data;
    int length;
    int capacity;
};

void initList(struct list *l);

void freeList(struct list *l);

void expandList(struct list *l, int n);

int listLen(struct list *l);

void appendList(struct list *l, void *val);

void setElem(struct list *l, int i, void *val);

void *indexList(struct list *l, int i);
