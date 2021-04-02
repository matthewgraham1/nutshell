#pragma once

#include <string>
#include <map>
#include <stdlib.h>

class VariableTable {
public:
    virtual std::string get(const std::string&) const = 0;
    void set(const std::string&, const std::string&);
    void unset(const std::string&);
    void print() const;
    virtual ~VariableTable() = 0;
protected:
    VariableTable() { };
    std::map<std::string, std::string> m_table;
};
