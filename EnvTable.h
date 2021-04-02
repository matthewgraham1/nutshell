#pragma once

#include <string>
#include "VariableTable.h"

class EnvTable : public VariableTable {
public:
    EnvTable()
    {
        m_table.insert({ "PATH", ".:/bin" });
        m_table.insert({ "HOME", getenv("HOME") });
    }
    static EnvTable& the();
    virtual std::string get(const std::string&) const override;
};
