#ifndef b2o_Tool_H
#define b2o_Tool_H

#include <iosfwd>
#include <string>

#include <eckit/runtime/Tool.h>

#include <odc/CommandLineParser.h>

namespace b2o {

class Tool
  : public eckit::Tool, private odc::tool::CommandLineParser {
public:
    Tool(int argc, char* argv[]);
   ~Tool();
    virtual void run();
    static void usage(std::ostream&);
private:
    Tool(const Tool&);
    Tool& operator=(const Tool&);
};

} // namespace b2o

#endif // b2o_Tool_H
