#include <chrono>
#include <iostream>
#include <string>
#include <thread>

namespace {
constexpr const char *kServiceName = "cpp-service";
constexpr int kDefaultPort = 8060;

std::string responseFor(const std::string &path) {
    if (path == "/healthz" || path == "--healthz") {
        return "{\"service\":\"cpp-service\",\"status\":\"ok\"}";
    }
    if (path == "/hello" || path == "--hello") {
        return "{\"service\":\"cpp-service\",\"message\":\"hello from cpp-service\"}";
    }
    if (path == "/info" || path == "--info") {
        return "{\"service\":\"cpp-service\",\"runtime\":\"native-cpp\",\"port\":8060}";
    }
    return "{\"error\":\"not found\"}";
}

int statusFor(const std::string &path) {
    if (path == "/healthz" || path == "--healthz" || path == "/hello" || path == "--hello" ||
        path == "/info" || path == "--info") {
        return 0;
    }
    return 1;
}

void serveForever() {
    std::cout << kServiceName << " ready on representative port " << kDefaultPort << std::endl;
    for (;;) {
        std::this_thread::sleep_for(std::chrono::seconds(60));
    }
}
}  // namespace

int main(int argc, char **argv) {
    std::string path = argc > 1 ? argv[1] : "--info";
    if (path == "--serve") {
        serveForever();
        return 0;
    }
    std::cout << responseFor(path) << std::endl;
    return statusFor(path);
}
