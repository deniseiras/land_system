#include "b2o_api.h"

extern "C" {

int b2o_convert_message_handle(b2o_context_t* x, b2o_converter_t* c, codes_handle* h, b2o_frame_t* f, bool* new_columns)
{
    const void* data;
    size_t data_size;

    CODES_CHECK(codes_get_message(h, &data, &data_size), CODES_SUCCESS);

    return b2o_convert_message_data(x, c, data, data_size, f, new_columns);
}

} // extern "C"
