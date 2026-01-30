#include "Select.h"

#include "odb_api/SQLDatabase.h"
#include "odb_api/SQLSelect.h"
#include "odb_api/SQLExpression.h"

#include "SelectIterator.h"
#include "Reader.h"
#include "SqlDatabase.h"
#include "Table.h"

using namespace odb;
using namespace eckit;

namespace b2o {

Select::Select(const std::string& statement, const Reader& reader,
        const string& includePath)
  : statement_(statement + ";"),
    reader_(reader),
    // table_(0),
    includePath_(includePath),
    begin_(new internal::SelectIterator(this)),
    columns_()
{
    populateColumns();
}

odb::sql::SQLDatabase* Select::createDatabase() const
{
    odb::sql::SQLDatabase* db = new SqlDatabase("BUFR"); // TODO: reader.filename());

    ASSERT(db);

    odb::sql::SQLTable* table = new Table(*db, reader_);
    ASSERT(table);
    db->addTable(table);

    if (!includePath_.empty()) {
        db->setIncludePath(includePath_);
    }

    return db;
}

Select::~Select()
{}

Select::iterator Select::begin()
{
    internal::SelectIterator* it = begin_.get()
        ? begin_.release()
        : new internal::SelectIterator(this);

    ASSERT(it);

    it->prepare();

    return iterator(it);
}

Select::iterator Select::end() const
{
    return iterator(new internal::SelectIterator());
}

void Select::populateColumns()
{
    ASSERT(begin_.get());

    const Expressions& results = begin_->results();

    for (size_t i = 0u; i < results.size(); i++)
    {
        const odb::sql::expression::SQLExpression* exp = results[i];
        const odb::sql::type::SQLType* sqlType = exp->type();
        const int kind = sqlType->getKind();

        DataType dataType;

        switch (kind)
        {
            using namespace odb::sql::type;

            case SQLType::realType:    dataType = FLOAT;    break;
            case SQLType::doubleType:  dataType = DOUBLE;   break;
            case SQLType::integerType: dataType = INTEGER;  break;
            case SQLType::stringType:  dataType = STRING;   break;
            case SQLType::bitmapType:  dataType = BITFIELD; break;
            case SQLType::blobType: NOTIMP; break;
            default:
                Log::error() << "Unknown type: " << *sqlType << ", kind: " << kind << endl;
                ASSERT(!"UnknownType");
                break;
        }

        Column c(exp->title(), dataType);
        // TODO: c.hasMissing(exp->hasMissingValue());
        c.missingValue(exp->missingValue());
        c.bitfieldDef(exp->bitfieldDef());
        columns_.push_back(c);
    }
}

} // namespace b2o
