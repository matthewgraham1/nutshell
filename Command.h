#pragma once

#include <list>
#include <vector>
#include <string>
#include <functional>
#include <map>

class Command {
public:
    inline Command() { expand_PATH(); }
    inline bool should_run_in_background() const { return m_background; }
    struct Node {
        std::string name;
        std::vector<std::string> arguments;
        struct Output {
            std::string from;
            std::string to;
            bool append { false };
        };
        std::vector<Output> output;
        std::string input_file;
    };
    void add_command(const Node&);
    int run();
    int run(Node&, int from, int to);
    void create_pipe_between(const Node&, const Node&);
private:
    void expand_PATH();
    std::list<Node> m_commands;
    int** m_pipes;
    bool m_background { false };
    std::vector<std::string> m_path;
};

class BuiltinCommandTable {
public:
    using BuiltinTableType = std::map<std::string, std::function<void(const std::vector<std::string>&)>>;
    using PairType = std::pair<std::string, std::function<int(const std::vector<std::string>&)>>;
    static BuiltinCommandTable& the();
    const BuiltinTableType& internal_table() const { return m_builtin_table; }
    int run(const std::string& builtin_name, const std::vector<std::string>& arguments);

    inline BuiltinTableType::iterator get(const std::string& name) { return m_builtin_table.find(name); }
private:
    BuiltinCommandTable();
    BuiltinTableType m_builtin_table;
};

