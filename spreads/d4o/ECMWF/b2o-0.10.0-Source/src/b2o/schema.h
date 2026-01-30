#ifndef b2o_schema_h
#define b2o_schema_h

#include <string>
#include <tuple>
#include <vector>

namespace b2o {

std::tuple<int, std::vector<std::string>, std::vector<int>> get_column_attrs(const std::string& name);

}

#endif // b2o_schema_h
