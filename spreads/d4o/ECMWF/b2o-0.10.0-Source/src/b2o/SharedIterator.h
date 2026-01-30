#ifndef b2o_SharedIterator_H
#define b2o_SharedIterator_H

namespace b2o {

template <typename T>
class SharedIterator {
public:
    typedef typename T::value_type value_type;
    typedef typename T::reference reference;
    typedef typename T::pointer pointer;
    typedef typename T::difference_type difference_type;
    typedef typename T::iterator_category iterator_category;

    template <typename U>
    explicit SharedIterator(U* it)
      : it_(it),
        use_count_(nullptr)
    {
        if (it_) use_count_ = new long (1);
    }

    SharedIterator(const SharedIterator& other)
      : it_(other.it_),
        use_count_(other.use_count_)
    {
        if (it_) ++(*use_count_);
    }

    template <typename U>
    SharedIterator(const SharedIterator<U>& other)
      : it_(other.it_),
        use_count_(other.use_count_)
    {
        if (it_) ++(*use_count_);
    }

    ~SharedIterator() {
        destruct();
    }

    SharedIterator& operator=(const SharedIterator& other)
    {
        if (it_ == other.it_)
            return *this;
    
        destruct();

        it_ = other.it_;
        use_count_ = other.use_count_;
        ++(*use_count_);

        return *this;
    }

    bool operator==(const SharedIterator& other) {
        return (*it_ == *other.it_);
    }

    bool operator!=(const SharedIterator& other) {
        return (*it_ != *other.it_);
    }

    SharedIterator& operator++() {
        ++(*it_);
        return *this;
    }

    reference operator*() const {
        return (*it_).operator*();
    }

    pointer operator->() const {
        return (*it_).operator->();
    }

    T* get() const { return it_; }

    bool unique() const {
        return use_count_ && (*use_count_ == 1);
    }

    long use_count() const {
        return use_count_ ? *use_count_ : 0;
    }

private:
    void destruct() {
        if (it_ && (--(*use_count_) == 0)) {
            delete it_;
            delete use_count_;
        }
    }

    T* it_;
    long int* use_count_;

    template <typename U> friend class SharedIterator;
};

} // namespace b2o

#endif // b2o_SharedIterator_H
