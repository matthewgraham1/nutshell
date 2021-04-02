#include <string>
#include "EnvTable.h"

EnvTable& EnvTable::the()
{
    static EnvTable s_env_table;
    return s_env_table;
}

std::string EnvTable::get(const std::string& env) const
{
    auto result = m_table.find(env);
    if (result == m_table.end())
        return "";
    return result->second;
}
