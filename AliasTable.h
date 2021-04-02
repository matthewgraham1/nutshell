#pragma once

#include <string>
#include "VariableTable.h"

class AliasTable : public VariableTable {
public:
    static AliasTable& the();
    virtual std::string get(const std::string&) const override;
};
