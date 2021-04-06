#pragma once

#include <list>
#include <vector>
#include <string>
#include <functional>

class Command {
public:
    inline bool should_run_in_background() const { return m_background; }
    struct Node {
        std::string name;
        std::vector<std::string> arguments;
        std::string take_from_file; // command < file.
        std::string redirect_to; // command > file; support N>&M somehow?
    };
    int run();
    int run(const Node&);
    void create_pipe_between(const Node&, const Node&);
private:
    list<Node> m_commands;
    bool m_background { false };
};

class BuiltinCommandTable {
public:
    using BuiltinTableType = map<std::string, std::function<int(const std::vector<std::string>&)>;
    static BuiltinTable& the();
    int run(const std::string& builtin_name, vector<std::string>& arguments);

    inline BuiltinTableType::iterator get_if_exists(const std::string& name) { return m_builtin_table.find(name); }
private:
    BuiltinCommandTable();
    BuiltinTableType m_builtin_table;
};

