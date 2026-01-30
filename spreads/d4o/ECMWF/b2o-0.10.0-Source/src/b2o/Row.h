#ifndef b2o_Row_H
#define b2o_Row_H

#include <stddef.h>

namespace b2o {

class Row
{
public:
    typedef double value_type;
    typedef double& reference;
    typedef double* pointer;

    Row() : data_(nullptr), size_(0) {}
    Row(pointer data, size_t size) : data_(data), size_(size) {}
    Row(const Row& other) : data_(other.data_), size_(other.size_) {}

    reference operator[](size_t n) { return data_[n]; }
  //const reference operator[](size_t n) const { return data_[n]; }
    reference operator[](size_t n) const { return data_[n]; }
    Row& operator++() { data_ += size_; return *this; }

    pointer data() { return data_; }
    pointer data() const { return data_; }
    void data(pointer p) { data_ = p; }
    size_t size() const { return size_; }
    void size(size_t s) { size_ = s; }

    pointer begin() { return data_; }
    pointer begin() const { return data_; }
    pointer end() { return data_ + size_; }
    pointer end() const { return data_ + size_; }

protected:
    pointer data_;
    size_t size_;
};

} // namespace b2o

#endif // b2o_Row_H
