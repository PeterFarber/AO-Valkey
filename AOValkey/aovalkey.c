

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#include <unistd.h>
#include "server.h"

static int l_createValkey(lua_State *L)
{
    printf("Create Valkey!\n");
    
    lua_pushnumber(L, create());
    return 1;
}

static int l_send(lua_State *L)
{
    printf("Send!\n");
    char * query = strdup(luaL_checkstring(L, 1));
    char newline = '\n';
    strncat(query, &newline, 1);
    printf("Query: %s\n", query);
    int send = r_send(query);
    printf("Send: %d\n", send);
    char * result = r_recv();
    printf("Result: %s\n", result);
    lua_pushstring(L, result);
    return 1;
}

// library to be registered
static const struct luaL_Reg valkey_funcs[] = {
    {"create", l_createValkey},
    {"send", l_send},
    {NULL, NULL} /* sentinel */
};

int luaopen_valkey(lua_State *L)
{
    luaL_newlib(L, valkey_funcs);
    return 1;
}
