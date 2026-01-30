#include "b2o/Reader.h"

#include <memory>
#include <string>

#include "eckit/exception/Exceptions.h"

#include <eccodes.h>

#include "b2o_api.h"
#include "b2o/schema.h"

using namespace std;
using namespace eckit;

namespace b2o {

Reader::Reader(const string& path)
  : file_(nullptr),
    context_(nullptr),
    converter_(nullptr)
{
    file_ = ::fopen(path.c_str(), "r");
    if (!file_) throw CantOpenFile(path);
    b2o_new_context(&context_, nullptr);
    b2o_context_set_message_source(context_, path.c_str());
    b2o_new_converter(&converter_);
    begin_ptr_.reset(new internal::ReaderIterator(file_, context_, converter_));
    columns_ = begin_ptr_.get()->columns();
}

Reader::~Reader()
{
    b2o_delete_converter(converter_);
    b2o_delete_context(context_);
    ::fclose(file_);
}

Reader::iterator Reader::begin()
{
    ASSERT(begin_ptr_.get());
    return iterator(begin_ptr_.release());
}

Reader::iterator Reader::end()
{
    return iterator(new internal::ReaderIterator());
}

namespace internal {

ReaderIterator::ReaderIterator()
  : file_(nullptr),
    converter_(nullptr),
    frame_(nullptr),
    done_(true)
{}

ReaderIterator::ReaderIterator(FILE* f, b2o_context_t* x, b2o_converter_t* c)
  : file_(f),
    context_(x),
    converter_(c),
    frame_(nullptr),
    done_(false)
{
    b2o_new_frame(&frame_);

    getNextFrame();

    int count;
    b2o_frame_column_count(frame_, &count);
    columns_.reserve(count);

    for (int index = 0; index < count; ++index) {

        char name[128];
        b2o_frame_column_name(frame_, index, name, sizeof(name));

        int type;
        vector<string> bitfield_names;
        vector<int> bitfield_sizes;

        tie(type, bitfield_names, bitfield_sizes) = b2o::get_column_attrs(name);

        auto* c = new odc::core::Column(columns_);
        c->name(name);
        c->type(static_cast<odc::api::ColumnType>(type));
        c->bitfieldDef(make_pair(bitfield_names, bitfield_sizes));
        columns_.push_back(c);
    }
}

void ReaderIterator::getNextFrame()
{
    ASSERT(file_);
    ASSERT(context_);
    ASSERT(converter_);
    ASSERT(frame_);
    ASSERT(!done_);

    codes_handle* h;
    int error = CODES_SUCCESS;
    int status = B2O_SKIP_MESSAGE;

    while ((status == B2O_SKIP_MESSAGE) &&
           ((h = codes_bufr_handle_new_from_file(nullptr, file_, &error)) != nullptr || (error != CODES_SUCCESS))) {
        bool new_columns;
        status = b2o_convert_message_handle(context_, converter_, h, frame_, &new_columns);
        CODES_CHECK(codes_handle_delete(h), CODES_SUCCESS);
    }

    done_ = (status != B2O_SUCCESS) || (error != CODES_SUCCESS);

    if (!done_) {
        long width, height, size;
        const void* data = nullptr;
        b2o_frame_shape(frame_, &width, &height);
        b2o_frame_data(frame_, &data, sizeof(double), &size);
        row_ = Row((double*)data, width);
        frame_end_ = (double*)((char*)data + size);
    }
}

ReaderIterator::~ReaderIterator()
{
    if (frame_) b2o_delete_frame(frame_);
}

ReaderIterator& ReaderIterator::operator++()
{
    if (!done_) {
        ++row_;
        if (row_.data() == frame_end_) {
            getNextFrame();
        }
    }

    return *this;
}

} // namespace internal
} // namespace b2o
