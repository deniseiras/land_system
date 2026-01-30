#include <algorithm>
#include <string>
#include <tuple>
#include <vector>

#include <eckit/config/Resource.h>
#include <eckit/filesystem/PathName.h>
#include <eckit/sql/SQLParser.h>
#include <eckit/sql/SQLSession.h>
#include <eckit/sql/SchemaAnalyzer.h>

#include <odc/api/odc.h>
#include <odc/StringTool.h>

extern "C" { void b2o_get_executable_path(char* path, size_t path_size); }

using namespace std;

namespace b2o {

eckit::sql::TableDefs parse_schema() {

    char exePath[256];
    b2o_get_executable_path(exePath, sizeof(exePath));
    const string homeDir = eckit::Resource<string>("$B2O_HOME", eckit::PathName(exePath).dirName().dirName().asString());
    //const string schemaFile = eckit::Resource<string>("$ODB_SCHEMA_FILE", homeDir + "/share/bufr2odb/cma.ddl");
    const string schemaFile = eckit::Resource<string>("$ODB_SCHEMA_FILE", homeDir + "/share/b2o/cma.ddl");
    eckit::sql::SQLSession session;
    eckit::sql::SQLParser::parseString(session, odc::StringTool::readFile(schemaFile));
    return session.currentDatabase().schemaAnalyzer().definitions();
}

int type_string_to_int(string type) {

    static const map<string, int> mapping = {

        {"INTEGER", ODC_INTEGER}, {"YYYYMMDD", ODC_INTEGER}, {"HHMMSS", ODC_INTEGER},
        {"PK1INT",  ODC_INTEGER}, {"PK9INT",   ODC_INTEGER}, {"@LINK",  ODC_INTEGER},
        {"REAL",    ODC_REAL   }, {"FLOAT",    ODC_REAL   },
        {"DOUBLE",  ODC_DOUBLE }, {"PK9REAL",  ODC_DOUBLE },
        {"STRING",  ODC_STRING }
    };

    transform(begin(type), end(type), begin(type), ::toupper);

    const auto match = find_if(begin(mapping), end(mapping),
            [&type](const pair<string, int>& p) { return type.find(p.first) != string::npos; });

    return match != end(mapping) ? match->second : ODC_BITFIELD;
}

tuple<int, vector<string>, vector<int>> get_column_attrs(const string& name) {

    // Takes a fully qualified column name (e.g. column@table) and looks up
    // column attributes in the schema.

    static const eckit::sql::TableDefs tables(parse_schema());

    const auto at = name.find("@");
    const auto column_name = name.substr(0, at);
    const auto table_name = name.substr(at+1);

    const auto table = find_if(begin(tables), end(tables),
            [&table_name](const eckit::sql::TableDef& t) { return t.name() == table_name; });

    if (table == end(tables)) {
        throw eckit::UserError("Unrecognized column qualifier: @" + table_name);
    }

    const auto& columns = table->columns();
    const auto column = find_if(begin(columns), end(columns),
            [&column_name](const eckit::sql::ColumnDef& c) { return c.name() == column_name; });

    if (column == end(columns)) {
        throw eckit::UserError("No match found for column '" + column_name + "' in table '" + table_name + "'");
    }

    int type = type_string_to_int(column->type());
    auto& bitfield_names = column->bitfield().first;
    auto& bitfield_sizes = column->bitfield().second;

    return make_tuple(type, bitfield_names, bitfield_sizes);
}

} // namespace b2o

extern "C" {

int b2o_get_column_type(const char* name) {

    // Takes a fully qualified column name (e.g. column@table) and returns its column type.

    int type; std::tie(type, std::ignore, std::ignore) = b2o::get_column_attrs(name); return type;
}

} // extern "C"
