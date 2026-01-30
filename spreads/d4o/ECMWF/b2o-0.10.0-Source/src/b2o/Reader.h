#ifndef b2o_Reader_H
#define b2o_Reader_H

#include "b2o_api.h"
#include "b2o/Row.h"
#include "b2o/SharedIterator.h"

#include <odc/core/MetaData.h>

namespace b2o {

namespace internal { class ReaderIterator; }

class Reader {
public:
    typedef odc::core::MetaData Columns;;
    typedef SharedIterator<internal::ReaderIterator> iterator;
    Reader(const std::string& path);
   ~Reader();
    Columns& columns() { return columns_; }
    const Columns& columns() const { return columns_; }
    iterator begin();
    iterator end();

    Reader(const Reader&) = delete;
    Reader& operator=(const Reader&) = delete;

private:
    FILE* file_;
    b2o_context_t* context_;
    b2o_converter_t* converter_;
    std::unique_ptr<internal::ReaderIterator> begin_ptr_;
    Columns columns_;
};

namespace internal {

class ReaderIterator {
public:
    typedef odc::core::MetaData Columns;;
    typedef const Row value_type;
    typedef std::input_iterator_tag iterator_category;
    typedef std::ptrdiff_t difference_type;
    typedef value_type& reference;
    typedef value_type* pointer;

    ReaderIterator();
   ~ReaderIterator();

    reference operator*() const { return row_; } 
    pointer operator->() const { return &row_; }

    ReaderIterator& operator++();

    bool operator==(const ReaderIterator&) const { return done_; }
    bool operator!=(const ReaderIterator&) const { return !done_; }

    const Columns& columns() const { return columns_; };

private:
    ReaderIterator(FILE* f, b2o_context_t* x, b2o_converter_t* c);
    ReaderIterator(const ReaderIterator&);
    ReaderIterator& operator=(const ReaderIterator&);

    void getNextFrame();

private:
    FILE* file_;
    b2o_context_t* context_;
    b2o_converter_t* converter_;
    b2o_frame_t* frame_;
    double* frame_end_;
    Columns columns_;
    Row row_;
    bool done_;

    friend class b2o::Reader;
};

} // namespace internal
} // namespace b2o

#endif // b2o_Reader_H
