/* #include "drhook.h" */

/* fast_strcmp.c : Shared memory thread-safe */

int fast_strcmp(const unsigned long long int *left_str, 
		const unsigned long long int *right_str)
{ 
  int irc;
  /* DRHOOK_START(fast_strcmp); */
  irc = (*left_str == *right_str) ? 0 : 1; /* 0 = matched, 1 = no match */
  /* DRHOOK_END(0); */
  return irc;
}
