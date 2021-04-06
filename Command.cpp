#include <list>
#include <vector>
#include <string>
#include <functional>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include "Command.h"
#include "EnvTable.h"
#include "AliasTable.h"

using std::vector;
using std::string;

void Command::create_pipe_between(const Node&, const Node&)
{
}

int Command::run()
{

}

BuiltinTable& BuiltinCommandTable::the()
{
    static BuiltinCommandTable s_builtin_command_table;
    return s_builtin_command_table;
}

BuiltinCommandTable()
{
    m_builtin_table.insert({ "bye", [](const vector<std::string>&) {
            exit(0);
            return 0;
        });
    m_builtin_table.insert({ "alias", [](const vector<std::string>& arguments) {
            if (arguments.size() != 0 || arguments.size() != 2) {
                fprintf(stderr, "alias: takes either 0 or 2 args\n");
                return 1;
            }
            if (!arguments.size()) {
                AliasTable::the().print();
                return 0;
            }
            AliasTable::the().set(arguments[0], arguments[1]);
            return 0;
        });
    m_builtin_table.insert({ "unalias", [](const vector<std::string>& arguments) {
            if (arguments.size() != 1) {
                fprintf(stderr, "unalias: takes 1 argument\n");
                return 1;
            }
            AliasTable::the().unset(arguments[0]);
            return 0;
        });

    m_builtin_table.insert({ "printenv", [](const vector<std::string>& arguments) {
            EnvTable::the().print();
            return 0;
        });

    m_builtin_table.insert({ "setenv", [](const vector<std::string>& arguments) {
            if (arguments.size() != 2) {
                fprintf(stderr, "setenv: takes 2 arguments\n");
                return 1;
            }
            EnvTable::the().set(arguments[0], arguments[1]);
            return 0;
        });
    m_builtin_table.insert({ "unsetenv", [](const vector<std::string>& arguments) {
            if (arguments.size() != 1) {
                fprintf(stderr, "unsetenv: takes 1 argument\n");
                return 1;
            }
            EnvTable::the().unset(arguments[0]);
            return 0;
        });
    m_builtin_table.insert({ "cd", [](const vector<std::string>& arguments) {
            if (arguments.size() != 0 || arguments.size() != 1) {
                fprintf(stderr, "cd: takes 1 argument\n");
                return 1;
            }
            if (!arguments.size()) {
                if (chdir(EnvTable::the().get("HOME").c_str()) == -1) {
                    fprintf(stderr, "cd: chdir() error: %s\n", strerror(errno));
                    return 1;
                }
                return 0;
            }
            if (chdir(arguments[0].c_str()) == -1) {
                fprintf(stderr, "cd: chdir() error: %s\n", strerror(errno));
                return 1;
            }
        });
};

