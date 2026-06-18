#include <stdio.h>
#include <string.h>
#include <unistd.h>

#define SERVICE_NAME "c-service"
#define RUNTIME_NAME "native-c"
#define DEFAULT_PORT 8050

static const char *response_for(const char *path) {
    if (strcmp(path, "/healthz") == 0 || strcmp(path, "--healthz") == 0) {
        return "{\"service\":\"c-service\",\"status\":\"ok\"}";
    }
    if (strcmp(path, "/hello") == 0 || strcmp(path, "--hello") == 0) {
        return "{\"service\":\"c-service\",\"message\":\"hello from c-service\"}";
    }
    if (strcmp(path, "/info") == 0 || strcmp(path, "--info") == 0) {
        return "{\"service\":\"c-service\",\"runtime\":\"native-c\",\"port\":8050}";
    }
    return "{\"error\":\"not found\"}";
}

static int status_for(const char *path) {
    if (strcmp(path, "/healthz") == 0 || strcmp(path, "--healthz") == 0 ||
        strcmp(path, "/hello") == 0 || strcmp(path, "--hello") == 0 ||
        strcmp(path, "/info") == 0 || strcmp(path, "--info") == 0) {
        return 0;
    }
    return 1;
}

static void serve_forever(void) {
    printf("%s ready on representative port %d\n", SERVICE_NAME, DEFAULT_PORT);
    fflush(stdout);
    for (;;) {
        sleep(60);
    }
}

int main(int argc, char **argv) {
    const char *path = argc > 1 ? argv[1] : "--info";
    if (strcmp(path, "--serve") == 0) {
        serve_forever();
        return 0;
    }
    printf("%s\n", response_for(path));
    return status_for(path);
}
