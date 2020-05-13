struct str
{
    char *data;
    int length;
};

void initStr(struct str *s);

void freeStr(struct str *s);

struct str *assignStr(struct str *s, char *val);

void copyStr(struct str *dest, struct str *src);

int printStr(struct str *s);

char *getData(struct str *s);

int strLen(struct str *s);

int strEq(struct str *s, struct str *t);
