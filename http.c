#include "http.h"
#include "str.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <curl/curl.h>


size_t write_string(char *ptr, size_t size, size_t nmemb, struct str *s)
{
  struct str tmp;

  if (s->data != NULL) {
    tmp.data = s->data;
    tmp.length = s->length;

    s->length += nmemb;
    s->data = malloc((s->length + 1) * sizeof(char));

    strcpy(s->data, tmp.data);
    strncpy(s->data + tmp.length, ptr, nmemb);
    freeStr(&tmp);
  } else {
    s->length = nmemb;
    s->data = malloc((s->length + 1) * sizeof(char));
    strncpy(s->data, ptr, nmemb);
  }

  return nmemb;
}

struct str get(const char *url)
{
  {
    CURL *curl;
    CURLcode res;
    struct str out;

    initStr(&out);

    curl = curl_easy_init();
    if(curl != NULL) {
      curl_easy_setopt(curl, CURLOPT_URL, url);
      /* example.com is redirected, so we tell libcurl to follow redirection */
      curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
      curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_string);
      curl_easy_setopt(curl, CURLOPT_WRITEDATA, &out);

      /* Perform the request, res will get the return code */
      res = curl_easy_perform(curl);
      /* Check for errors */
      if(res != CURLE_OK)
        fprintf(stderr, "curl_easy_perform() failed: %s\n",
                curl_easy_strerror(res));

      /* always cleanup */
      curl_easy_cleanup(curl);
    }
    return out;
  }
}
