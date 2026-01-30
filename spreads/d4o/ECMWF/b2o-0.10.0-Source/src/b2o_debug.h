#ifndef B2O_DEBUG_H
#define B2O_DEBUG_H

#undef NDEBUG

#ifdef NDEBUG
#define B2O_ASSERT(condition)
#define     ASSERT(condition)
#define b2o_assert(condition) b2o_do_nothing
#define     assert(condition) b2o_do_nothing
#else
#if defined(__INTEL_COMPILER) || defined(__PGI)
#define B2O_ASSERT(condition) \
 if (.not.(condition)) then; \
 write(0, "(/,'b2o: Assertion error : ',a,' at ',a,':',i0)") #condition,__FILE__, __LINE__; \
 call b2o_exit(1); \
endif
#elif defined(__GFORTRAN__)
#define B2O_ASSERT(condition) \
 if (.not.(condition)) then; \
 write(0, "(/,'b2o: Assertion error : ',a,' at ',a,':',i0)") "condition",__FILE__, __LINE__; \
 call b2o_exit(1); \
endif
#else
#define B2O_ASSERT(condition) \
 if (.not.(condition)) then; \
 write(0, "(/,'b2o: Assertion error at ',a,':',i0)") __FILE__, __LINE__; \
 call b2o_exit(1); \
endif
#endif
#define b2o_assert(condition) b2o_do_nothing; B2O_ASSERT(condition)
#define     assert(condition) b2o_do_nothing; B2O_ASSERT(condition)
#endif
#endif
