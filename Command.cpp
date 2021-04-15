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


void normalize_path_if_needed(std::string& path);
void expand_tilda_if_at_beginning(std::string& path);

void Command::expand_PATH()
{
    m_path.clear();
    std::string dir;
    for (auto c : EnvTable::the().get("PATH")) {
        if (c == ':') {
            //normalize_path_if_needed(dir);
            expand_tilda_if_at_beginning(dir);
            if (dir[dir.length() - 1] != '/')
                dir.push_back('/');
            m_path.push_back(dir);
            dir.clear();
            continue;
        }
        dir.push_back(c);
    }
    if (dir.length())
        m_path.push_back(dir);
}

int Command::run(Command::RunIn run_in)
{
    if (!m_commands.size())
        return 0;
    m_pipes = (int**)malloc((m_commands.size() - 1) * sizeof(int*));
    for (int i = 0; i < m_commands.size() - 1; i++) {
        int* p = (int*)malloc(2 * sizeof(int));
        pipe(p);
        m_pipes[i] = p;
    }
    auto node = m_commands.begin();
    if (m_commands.size() == 1) {
        run(*node, 0, 1);
    }
    else {
        run(*node++, 0, m_pipes[0][1]);
        unsigned i = 0;
        for (; node != m_commands.end(); ++node) {
            if (i + 1 < m_commands.size() - 1) // If not the last one
                run(*node, m_pipes[i][0], m_pipes[i + 1][1]);
            else {
                run(*node, m_pipes[i][0], 1);
            }
            ++i;
        }
    }
    if (run_in != Command::RunIn::Background)
        while (wait(nullptr) > 0);

    for (int i = 0; i < m_commands.size() - 1; i++) {
        close(m_pipes[i][0]);
        close(m_pipes[i][1]);
        free(m_pipes[i]);
    }
    free(m_pipes);
    fflush(stdout);
    fflush(stdin);
    m_commands.clear();
    return 0;
}
bool file_exists(const std::string& path)
{
    struct stat file_stat;
    if (stat(path.c_str(), &file_stat)) {
        //fprintf(stderr, "File %s does not exist\n", command_node.name.c_str());
        return false;
    }
    return true;
}
int file_exists_or_executable_or_error(const std::string& path)
{
    struct stat file_stat;
    if (stat(path.c_str(), &file_stat)) {
        fprintf(stderr, "File %s does not exist\n", path.c_str());
        return 1;
    }
    if (!(file_stat.st_mode & S_IXUSR)) {
        fprintf(stderr, "File %s is not executable\n", path.c_str());
        return 1;
    }
    return 0;
}
int Command::run(Node& command_node, int read_from, int write_to)
{
    if (command_node.name == "setenv") { // this is all terrible but I am short on time
        if (command_node.arguments.size() != 2) {
            fprintf(stderr, "setenv: takes 2 arguments\n");
            return 1;
        }
        EnvTable::the().set(command_node.arguments[0], command_node.arguments[1]);
        if (command_node.arguments[0] == "PATH")
            expand_PATH();
        return 0;
    }
    if (command_node.name == "unsetenv") {
            if (command_node.arguments.size() != 1) {
                fprintf(stderr, "unsetenv: takes 1 argument\n");
                return 1;
            }
            EnvTable::the().unset(command_node.arguments[0]);
            if (command_node.arguments[0] == "PATH") {
                EnvTable::the().set("PATH", ".");
                expand_PATH();
            }
            return 0;
    }
    if (command_node.name == "bye") {
        exit(0);
    }
    if (command_node.name == "alias" && command_node.arguments.size() == 2) {
        AliasTable::the().set(command_node.arguments[0], command_node.arguments[1]);
        return 0;
    }
    if (command_node.name == "unalias") {
        if (command_node.arguments.size() != 1) {
            fprintf(stderr, "unalias: takes 1 argument\n");
            return 1;
        }
        AliasTable::the().unset(command_node.arguments[0]);
        return 0;
    }
    if (command_node.name == "cd") {
        if (command_node.arguments.size() != 0 && command_node.arguments.size() != 1) {
            fprintf(stderr, "cd: takes 1 or 0 argument\n");
            return 1;
        }
        if (!command_node.arguments.size()) {
            if (chdir(EnvTable::the().get("HOME").c_str()) == -1) {
                fprintf(stderr, "cd: chdir() error: %s\n", strerror(errno));
                return 1;
            }
            return 0;
        }
        if (chdir(command_node.arguments[0].c_str()) == -1) {
            fprintf(stderr, "cd: chdir() error: %s\n", strerror(errno));
            return 1;
        }
        return 0;
    }
    auto builtin_res = BuiltinCommandTable::the().get(command_node.name); 
    if (builtin_res == BuiltinCommandTable::the().internal_table().end()) [[likely]] {
        std::string full_path;
        if (command_node.name.length() && command_node.name[0] != '/') {
            for (auto dir : m_path) {
                normalize_path_if_needed(dir);
                full_path.append(dir);
                full_path.append(command_node.name);
                if (!file_exists(full_path)) {
                    full_path.clear();
                    continue;
                }
                command_node.name = std::move(full_path);
                break;
            }
        }
        if (file_exists_or_executable_or_error(command_node.name)) {
            return 1;
        }
    }
    int pid = fork();
    if (pid < 0) [[unlikely]] {
        perror("fork");
        return pid;
    }
    if (!pid) {
        if (command_node.output.size() > 2) {
            fprintf(stderr, "Adding more than two redirections in a command block is pointless!\n");
            return 1;
        }

        // Beware ye who enter
        bool has_set_2_to_1 = false;
        bool has_set_1_to_2 = false;
        if (!command_node.output.size()) {
            dup2(write_to, 1);
        } else {
            for (auto& output : command_node.output) {
                int from_fd;
                if (output.from == "1" || output.from == "2") {
                    from_fd = output.from[0] - '0';
                } else if (output.from.length()) {
                    fprintf(stderr, "Shell error: must either have 1, 2, or nothing before '>' token.\n");
                    return 1;
                }
                int to_fd = 1;
                if (!output.to.length()) [[unlikely]] {
                    fprintf(stderr, "shell error: must direct output to something\n");
                    return 1;
                }
                if (output.to.length() == 2 && output.to[0] == '&' && (output.to[1] == '1' || output.to[1] == '2')) {
                    to_fd = output.to[1] - '0';
                    if (from_fd == 2 && to_fd == 1) {
                        dup2(write_to, 2);
                        dup2(write_to, 1);
                        has_set_2_to_1 = true;
                    } else if (from_fd == 1 && to_fd == 2) {
                        dup2(2, 1);
                        has_set_1_to_2 = true;
                    } else {
                        if (!has_set_1_to_2 && !has_set_2_to_1) {
                            dup2(write_to, 1);
                        }
                    }
                } else if (output.to.length()) {
                    FILE* file_fd = fopen(output.to.c_str(), output.append ? "a" : "w");
                    if (!file_fd) {
                        perror("fopen");
                        return 1;
                    }
                    //chown(output.to.c_str(), getuid(), -1);
                    if (has_set_2_to_1) {
                        dup2(file_fd->_fileno, 1);
                        dup2(file_fd->_fileno, 2);
                    }
                    else if (has_set_1_to_2) {
                        if (output.from == "2") {
                            dup2(file_fd->_fileno, 1);
                            dup2(file_fd->_fileno, 2);
                        } else { 
                            // Undefined i guess?
                        }
                    }
                    else {
                        if (output.from == "2")
                            dup2(file_fd->_fileno, 2);
                        else if (output.from == "1")
                            dup2(file_fd->_fileno, 1);
                    }
                    fclose(file_fd);
                }
            }
        }
        if (read_from == 0) {
            if (command_node.input_file.length()) {
                read_from = open(command_node.input_file.c_str(), O_RDONLY);
                if (read_from < 0) {
                    perror("open");
                    return 1;
                }
            }
        }
        dup2(read_from, 0);
        for (int i = 0; i < m_commands.size() - 1; i++) {
            int* p = m_pipes[i];
            close(p[0]);
            close(p[1]);
        }
        if (read_from != 0)
            close(read_from);
        if (write_to != 1 && write_to != 2)
            close(write_to);

        if (builtin_res != BuiltinCommandTable::the().internal_table().end()) [[unlikely]] {
            builtin_res->second(command_node.arguments);
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
    m_builtin_table.insert({ string("alias"), [](const vector<std::string>& arguments) {
            if (arguments.size() != 0 && arguments.size() != 2) {
                fprintf(stderr, "alias: takes either 0 or 2 args\n");
                return 1;
            }
            AliasTable::the().print();
            return 0;
        } });

    m_builtin_table.insert({ string("printenv"), [](const vector<std::string>& arguments) {
            EnvTable::the().print();
            return 0;
        } });

};
