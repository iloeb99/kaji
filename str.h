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

int fprintStr(struct str *f, struct str *s, int append);

struct str *subStr(int start, int end, const struct str *s);

int strLen(struct str *s);

int strEq(struct str *s, struct str *t);

struct str *concatStr(struct str *s1, struct str *s2);