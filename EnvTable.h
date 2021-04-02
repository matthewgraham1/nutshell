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
        set("PATH", ".:/bin");
        set("HOME", getenv("HOME"));
    }
};
