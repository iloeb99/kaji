struct str
{
    char *s;
    int length;
};

void initStr(struct str *string);

void freeStr(struct str *string);

struct str *assignStr(struct str *string, char *val);