#include <string>
#include "AliasTable.h"

AliasTable& AliasTable::the()
{
    static AliasTable s_alias_table;
    return s_alias_table;
}

std::string AliasTable::get(const std::string& alias) const
{
    auto result = m_table.find(alias);
    if (result == m_table.end())
        return alias;
    return result->second;
}
