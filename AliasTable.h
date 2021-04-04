#pragma once

#include <string>
#include "VariableTable.h"

class AliasTable : public VariableTable {
public:
    static AliasTable& the();
    void set(const std::string&, const std::string&);
    virtual std::string get(const std::string&) const override;
};
