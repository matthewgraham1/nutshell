#pragma once

#include <map>

class VariableTable {
public:
    virtual std::string get(const std::string&) const = 0;
    inline void set(const std::string& variable, const std::string& word) { m_table.insert({ variable, word }); }
    inline void unset(const std::string& variable) { m_table.erase(variable); }
    inline void print() const // Can be inline since it is only used twice
    {
        for (auto& pair : m_table) {
            printf("%s=%s\n", pair.first.c_str(), get(pair.first).c_str());
        }
    }
    inline virtual ~VariableTable() = 0;
protected:
    VariableTable() { };
    std::map<std::string, std::string> m_table;
};

VariableTable::~VariableTable() { }
