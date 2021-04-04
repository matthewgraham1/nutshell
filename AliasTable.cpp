#include <string>
#include "AliasTable.h"

AliasTable& AliasTable::the()
{
    static AliasTable s_alias_table;
    return s_alias_table;
}

void AliasTable::set(const std::string& alias, const std::string& word)
{
    if (alias == word) {
        fprintf(stderr, "Attempted to make %s an alias of itself\n", alias.c_str());
        return;
    }
    if (auto result = m_table.find(word); result != m_table.end() && result->second == alias) {
        fprintf(stderr, "Attempted to make %s an alias of %s, which would make an infinite loop!\n", alias.c_str(), word.c_str());
        return;
    }
    m_table.insert({ alias, word });
}

std::string AliasTable::get(const std::string& alias) const
{
    auto result = m_table.find(alias);
    if (result == m_table.end())
        return alias;
    return result->second;
}
