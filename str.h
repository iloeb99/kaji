struct str
{
    char *data;
    int length;
};

void initStr(struct str *s);

void freeStr(struct str *s);

struct str *assignStr(struct str *s, char *val);

void copyStr(struct str *dest, struct str *src);
