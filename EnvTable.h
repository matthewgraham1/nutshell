#pragma once

#include <string>
#include "VariableTable.h"

class EnvTable : public VariableTable {
public:
    static EnvTable& the();
    virtual std::string get(const std::string&) const override;
private:
    EnvTable()
    {
        m_table.insert({ "PATH", ".:/bin" });
        m_table.insert({ "HOME", getenv("HOME") });
    }
};
