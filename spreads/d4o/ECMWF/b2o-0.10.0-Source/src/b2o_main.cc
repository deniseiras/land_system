#include "b2o/Tool.h"

int main(int argc, char* argv[])
{
    b2o::Tool tool(argc, argv);
    int status = tool.start();
    return status;
}
