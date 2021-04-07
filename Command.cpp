#include <list>
#include <vector>
#include <string>
#include <functional>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <sys/stat.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <stdlib.h>
#include <fcntl.h>
#include "Command.h"
#include "EnvTable.h"
#include "AliasTable.h"

using std::vector;
using std::string;

void Command::create_pipe_between(const Node&, const Node&)
{
}

void Command::add_command(const Node& command)
{
    m_commands.push_back(command);
}

int Command::run()
{
    add_command({ "/usr/bin/ls", { "-l" }, "", "" });
    add_command({ "/usr/bin/grep", { "C" }, "", "" });
    add_command({ "/usr/bin/wc", { "l" }, "", "" });
    if (!m_commands.size())
        return 0;
    m_pipes = (int**)malloc((m_commands.size() - 1) * sizeof(int*));
    for (int i = 0; i < m_commands.size(); i++) {
        int* p = (int*)malloc(2 * sizeof(int));
        pipe(p);
        m_pipes[i] = p;
    }
    auto node = m_commands.begin();
    if (m_commands.size() == 1) {
        int first_to_fd = node->output_file.length() ? open(node->output_file.c_str(), O_WRONLY) : 1;
        run(*node, 0, first_to_fd);
    }
    else {
        run(*node++, 0, m_pipes[0][1]);
        unsigned i = 0;
        for (; node != m_commands.end(); ++node) {
            if (i + 1 != m_commands.size() - 1) // If not the last one
                run(*node, m_pipes[i][0], m_pipes[i + 1][1]);
            else {
                printf("I happen!\n");
                int last_out_fd = 1;
                if (node->output_file.length()) {
                printf("%u size of output_file is\n", node->output_file.length());
                    last_out_fd = open(node->output_file.c_str(), O_WRONLY);
                    if (last_out_fd < 0) {
                        perror("open");
                        return 1;
                    }
                }
                run(*node, m_pipes[i][0], last_out_fd);
            }
            ++i;
        }
    }
    if (!should_run_in_background()) {
        waitpid(-1, nullptr, 0);
    }
    printf("I get here!\n");
    return 0;
}
int Command::run(const Node& command_node, int read_from, int write_to)
{
    auto builtin_res = BuiltinCommandTable::the().get(command_node.name); 
    if (builtin_res == BuiltinCommandTable::the().internal_table().end()) [[likely]] {
        struct stat file_stat;
        if (stat(command_node.name.c_str(), &file_stat)) {
            fprintf(stderr, "File %s does not exist\n", command_node.name.c_str());
            return 1;
        }
        if (!(file_stat.st_mode & S_IXUSR)) {
            fprintf(stderr, "File %s is not executable\n", command_node.name.c_str());
            return 1;
        }
    }
    int pid = fork();
    if (pid < 0) [[unlikely]] {
        perror("fork");
        return pid;
    }
    if (!pid) {
        dup2(read_from, 0);
        dup2(write_to, 1);
        if (read_from != 0)
            close(read_from);
        if (write_to != 1 && write_to != 2)
            close(write_to);
        for (int i = 0; i < m_commands.size() - 1; i++) {
            int* p = m_pipes[i];
            close(p[0]);
            close(p[1]);
        }
        if (builtin_res != BuiltinCommandTable::the().internal_table().end()) [[unlikely]] {
            return builtin_res->second(command_node.arguments);
        }
        int i = 0;
        char** arguments = (char**)calloc(command_node.arguments.size() + 2, sizeof(char*));
        arguments[0] = const_cast<char*>(command_node.name.c_str());
        for (auto& argument : command_node.arguments) {
            arguments[++i] = strdup(argument.c_str());
        }
        execv(command_node.name.c_str(), arguments);
        perror("execv");
        return 1;
    }
    if (read_from != 0)
        close(read_from);
    if (write_to != 1 && write_to != 2)
        close(write_to);
    return 0;
}

BuiltinCommandTable& BuiltinCommandTable::the()
{
    static BuiltinCommandTable s_builtin_command_table;
    return s_builtin_command_table;
}

BuiltinCommandTable::BuiltinCommandTable()
{
    m_builtin_table.insert({ string("bye"), [](const vector<std::string>&) {
            exit(0);
            return 0;
        } });
    m_builtin_table.insert({ string("alias"), [](const vector<std::string>& arguments) {
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
        } });
    m_builtin_table.insert({ string("unalias"), [](const vector<std::string>& arguments) {
            if (arguments.size() != 1) {
                fprintf(stderr, "unalias: takes 1 argument\n");
                return 1;
            }
            AliasTable::the().unset(arguments[0]);
            return 0;
        } });

    m_builtin_table.insert({ string("printenv"), [](const vector<std::string>& arguments) {
            EnvTable::the().print();
            return 0;
        } });

    m_builtin_table.insert({ string("setenv"), [](const vector<std::string>& arguments) {
            if (arguments.size() != 2) {
                fprintf(stderr, "setenv: takes 2 arguments\n");
                return 1;
            }
            EnvTable::the().set(arguments[0], arguments[1]);
            return 0;
        } });
    m_builtin_table.insert({ string("unsetenv"), [](const vector<std::string>& arguments) {
            if (arguments.size() != 1) {
                fprintf(stderr, "unsetenv: takes 1 argument\n");
                return 1;
            }
            EnvTable::the().unset(arguments[0]);
            return 0;
        } });
    m_builtin_table.insert({ string("cd"), [](const vector<std::string>& arguments) {
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
            fprintf(stderr, "cd: I should not get here!\n");
            return 1;
        } });
};

