#include <string>
#include <stdio.h>
#include "VariableTable.h"


void VariableTable::set(const std::string& alias, const std::string& string)
{
    m_table.insert({ alias, string });
}

void VariableTable::unset(const std::string& variable)
{
    m_table.erase(variable);
}
void VariableTable::print() const
{
    for (auto& pair : m_table) {
        printf("%s=%s\n", pair.first.c_str(), get(pair.first).c_str());
    }
}

VariableTable::~VariableTable() { }
