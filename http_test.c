#include "http.h"
#include "str.h"

#include <stdio.h>

int main(int argc, char *argv[])
{
  struct str boy;

  if (argc < 2) {
    printf("usage: %s url\n", argv[0]);
    exit(0);
  }

  boy = get(argv[1]);
  printStr(&boy);
  return 0;
}
