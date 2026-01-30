#include <stdio.h>
#include <string.h>
/* #include "drhook.h" */

/* wildcard_strcmp.c : Shared memory thread-safe */

#ifndef WILDCARD
#define WILDCARD '.'
#endif

int wildcard_strcmp(const char *left_str, const char *right_str, const int is_8)
{ 
  int irc;
  /* DRHOOK_START(wildcard_strcmp); */
  {
    const char *pleft_str = left_str;
    const char *pright_str = right_str;
    irc = 
      (is_8 || (strlen(pleft_str) == strlen(pright_str))); /* Strings have to have equal len */
    for ( ; irc && *pleft_str && *pright_str; pleft_str++, pright_str++) {
      if (*pright_str == WILDCARD) continue; /* A wildcard --> no need to compare */
      irc = (*pleft_str == *pright_str);
    }
    irc = irc ? 0 : 1; /* 0 = matched, 1 = no match */
  }
  /* DRHOOK_END(0); */
  return irc;
}
