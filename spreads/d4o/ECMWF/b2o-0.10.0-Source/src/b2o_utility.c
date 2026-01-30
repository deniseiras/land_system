#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#if defined(__APPLE__) && defined(__MACH__)

#include <libproc.h> // proc_pidpath

void b2o_get_executable_path(char* path, size_t path_size)
{
    char buffer[PROC_PIDPATHINFO_MAXSIZE];

    memset(buffer, 0, sizeof(buffer));

    pid_t pid = getpid();
    int code = proc_pidpath(pid, buffer, sizeof(buffer));

    if (code < 0) {
        fprintf(stderr, "System call proc_pidpath() failed: %s\n", strerror(errno));
        fprintf(stderr, "Couldn't get executable path\n");
        abort();
    }

    strncpy(path, buffer, path_size);
}

#elif defined(__linux__)

#include <limits.h> // PATH_MAX
#include <stdlib.h> // realpath

void b2o_get_executable_path(char* path, size_t path_size)
{
    char buffer[PATH_MAX];

    memset(buffer, 0, sizeof(buffer));

    ssize_t code = readlink("/proc/self/exe", buffer, sizeof(buffer));

    if (code <= 0) {
        fprintf(stderr, "System call readlink() failed: %s\n", strerror(errno));
        fprintf(stderr, "Couldn't get executable path\n");
        abort();
    }

    if (strstr(buffer, "/var/opt/cray/alps/spool")) {
        char cmdline[PATH_MAX];
        FILE* fd = fopen("/proc/self/cmdline", "r");
        size_t dummy = fread(cmdline, 1, sizeof(cmdline), fd);
        fclose(fd);
        if (!realpath(cmdline, buffer)) {
            fprintf(stderr, "System call realpath() failed: %s\n", strerror(errno));
            fprintf(stderr, "Couldn't get executable path\n");
            abort();
        }
    }

    strncpy(path, buffer, path_size);
}

#else

#error "Function b2o_get_executable_path not defined for this platform"

#endif
