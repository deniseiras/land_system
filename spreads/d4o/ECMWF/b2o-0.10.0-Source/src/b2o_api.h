#ifndef b2o_api_h
#define b2o_api_h

#include <eccodes.h>

#ifdef __cplusplus
extern "C" {
#endif

const int B2O_SUCCESS = 0;
const int B2O_SKIP_MESSAGE = -3;

void b2o_init(int argc, char* argv[]);

struct b2o_context_t;
struct b2o_converter_t;
struct b2o_frame_t;

typedef struct b2o_context_t b2o_context_t;
typedef struct b2o_converter_t b2o_converter_t;
typedef struct b2o_frame_t b2o_frame_t;

void b2o_new_context(b2o_context_t** x, b2o_context_t* parent);
void b2o_delete_context(b2o_context_t* x);
void b2o_context_set_message_source(b2o_context_t* x, const char* source);

void b2o_new_converter(b2o_converter_t** c);
void b2o_delete_converter(b2o_converter_t* c);

int b2o_new_frame(b2o_frame_t** f);
int b2o_delete_frame(b2o_frame_t* f);
int b2o_frame_column_count(const b2o_frame_t* f, int* count);
int b2o_frame_column_name(const b2o_frame_t* f, int index, char* name, int name_len);
int b2o_frame_shape(const b2o_frame_t* f, long* width, long* height);
int b2o_frame_data(const b2o_frame_t* f, const void** data, int elem_len, long* size);
int b2o_frame_clear(b2o_frame_t* f);
int b2o_frame_append(b2o_frame_t* f, b2o_frame_t* o);
int b2o_frame_masked_append(b2o_frame_t* f, b2o_frame_t* o, const int mask[], int nmask);
  
int b2o_convert_message_data(b2o_context_t* x, b2o_converter_t* c, const void* data, size_t data_size, b2o_frame_t* f, bool* new_columns);
int b2o_convert_message_handle(b2o_context_t* x, b2o_converter_t* c, codes_handle* h, b2o_frame_t* f, bool* new_columns);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // b2o_api_h
