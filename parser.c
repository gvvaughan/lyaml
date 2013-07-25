/*
 * parser.c, libyaml parser binding for Lua
 *
 * Copyright (c) 2013, Gary V. Vaughan <gary@vaughan.pe>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#include <config.h>

#define LYAML__STR(_s)		(#_s)
#define LYAML_STR(_s)		LYAML__STR(_s)

/* NOTE: Make sure L is in scope before using these macros. */
#define RAWSET_BOOLEAN(_k, _v)			\
	lua_pushstring  (L, (_k));		\
	lua_pushboolean (L, (_v) != 0);		\
	lua_rawset (L, -3)

#define RAWSET_INTEGER(_k, _v)			\
	lua_pushstring  (L, (_k));		\
	lua_pushinteger (L, (_v));		\
	lua_rawset (L, -3)

#define RAWSET_STRING(_k, _v)			\
	lua_pushstring (L, (_k));		\
	lua_pushstring (L, (_v));		\
	lua_rawset (L, -3)

#define RAWSET_EVENTF(_k)			\
	lua_pushstring (L, LYAML_STR(_k));	\
	lua_pushstring (L, EVENTF(_k));		\
	lua_rawset (L, -3)

/* With the event result table on the top of the stack, insert
   a mark entry. */
static void
parser_set_mark (lua_State *L, const char *k, yaml_mark_t mark)
{
   lua_pushstring (L, k);
   lua_createtable (L, 0, 3);
#define MENTRY(_s)	RAWSET_INTEGER(LYAML_STR(_s), mark._s)
	MENTRY( index	);
	MENTRY( line	);
	MENTRY( column	);
#undef MENTRY
   lua_rawset (L, -3);
}

/* Push a new event table, pre-populated with shared elements. */
static void
parser_push_eventtable (struct lua_yaml_loader *loader, const char *v, int n)
{
   lua_State *L = loader->L;

   lua_createtable (L, 0, n + 3);
   RAWSET_STRING   ("type", v);
#define MENTRY(_s)	parser_set_mark (L, LYAML_STR(_s), loader->event._s)
	MENTRY( start_mark	);
	MENTRY( end_mark	);
#undef MENTRY
}

static void
parse_STREAM_START (struct lua_yaml_loader *loader)
{
#define EVENTF(_f)	(loader->event.data.stream_start._f)
   lua_State *L = loader->L;
   const char *encoding;

   switch (EVENTF (encoding))
   {
#define MENTRY(_s)		\
      case YAML_##_s##_ENCODING: encoding = LYAML_STR(_s); break

	MENTRY( ANY	);
	MENTRY( UTF8	);
	MENTRY( UTF16LE	);
	MENTRY( UTF16BE	);
#undef MENTRY

      default:
         lua_pushfstring(loader->L, "invalid encoding %d", EVENTF (encoding));
         loader->error = 1;
         return;
   }

   parser_push_eventtable (loader, "STREAM-START", 1);
   RAWSET_STRING ("encoding", encoding);
#undef EVENTF
}

static void
parse_STREAM_END (struct lua_yaml_loader *loader)
{
   parser_push_eventtable (loader, "STREAM-END", 0);
}

/* With the tag list on the top of the stack, append TAG. */
static void
parser_append_tag (lua_State *L, yaml_tag_directive_t tag)
{
   lua_createtable (L, 0, 2);
#define MENTRY(_s)	RAWSET_STRING(LYAML_STR(_s), tag._s)
	MENTRY( handle	);
	MENTRY( prefix	);
#undef MENTRY
   lua_rawseti (L, -2, lua_objlen (L, -2) + 1);
}

static void
parse_DOCUMENT_START (struct lua_yaml_loader *loader)
{
#define EVENTF(_f)	(loader->event.data.document_start._f)
   lua_State *L = loader->L;

   parser_push_eventtable (loader, "DOCUMENT-START", 1);
   RAWSET_BOOLEAN ("implicit", EVENTF (implicit));

   /* version_directive = { major = M, minor = N } */
   if (EVENTF (version_directive))
   {
      lua_pushliteral (loader->L, "version_directive");
      lua_createtable (loader->L, 0, 2);
#define MENTRY(_s)		\
	RAWSET_INTEGER(LYAML_STR(_s), EVENTF (version_directive->_s))
	MENTRY( major	);
	MENTRY( minor	);
#undef MENTRY
      lua_rawset (loader->L, -3);
   }

   /* tag_directives = { {handle = H1, prefix = P1}, ... } */
   if (EVENTF (tag_directives.start) &&
       EVENTF (tag_directives.end)) {
      yaml_tag_directive_t *cur;

      lua_pushliteral (loader->L, "tag_directives");
      lua_newtable (loader->L);
      for (cur = EVENTF (tag_directives.start);
           cur != EVENTF (tag_directives.end);
	   cur = cur + 1) {
	 parser_append_tag (loader->L, *cur);
      }
      lua_rawset (loader->L, -3);
   }
#undef EVENTF
}

static void
parse_DOCUMENT_END (struct lua_yaml_loader *loader)
{
#define EVENTF(_f)	(loader->event.data.document_end._f)
   lua_State *L = loader->L;

   parser_push_eventtable (loader, "DOCUMENT-END", 1);
   RAWSET_BOOLEAN ("implicit", EVENTF (implicit));
#undef EVENTF
}

static void
parse_ALIAS (struct lua_yaml_loader *loader)
{
#define EVENTF(_f)	(loader->event.data.alias._f)
   lua_State *L = loader->L;

   parser_push_eventtable (loader, "ALIAS", 1);
   RAWSET_EVENTF (anchor);
#undef EVENTF
}

static void
parse_SCALAR (struct lua_yaml_loader *loader)
{
#define EVENTF(_f)	(loader->event.data.scalar._f)
   lua_State *L = loader->L;

   parser_push_eventtable (loader, "SCALAR", 5);
   RAWSET_EVENTF (anchor);
   RAWSET_EVENTF (tag);
   RAWSET_EVENTF (value);

   RAWSET_BOOLEAN ("plain_implicit", EVENTF (plain_implicit));
   RAWSET_BOOLEAN ("quoted_implicit", EVENTF (quoted_implicit));
#undef EVENTF
}

static void
parse_SEQUENCE_START (struct lua_yaml_loader *loader)
{
#define EVENTF(_f)	(loader->event.data.sequence_start._f)
   lua_State *L = loader->L;
   const char *style;

   switch (EVENTF (style))
   {
#define MENTRY(_s)		\
      case YAML_##_s##_SEQUENCE_STYLE: style = LYAML_STR(_s); break

	MENTRY( ANY	);
	MENTRY( BLOCK	);
	MENTRY( FLOW	);
#undef MENTRY

      default:
         lua_pushfstring(L, "invalid sequence style %d", EVENTF (style));
         loader->error = 1;
         return;
   }

   parser_push_eventtable (loader, "SEQUENCE-START", 4);
   RAWSET_EVENTF (anchor);
   RAWSET_EVENTF (tag);
   RAWSET_BOOLEAN ("implicit", EVENTF (implicit));
   RAWSET_STRING ("style", style);
#undef EVENTF
}

static void
parse_SEQUENCE_END (struct lua_yaml_loader *loader)
{
   parser_push_eventtable (loader, "SEQUENCE-END", 0);
}

static void
parse_MAPPING_START (struct lua_yaml_loader *loader)
{
#define EVENTF(_f)	(loader->event.data.mapping_start._f)
   lua_State *L = loader->L;
   const char *style;

   switch (EVENTF (style))
   {
#define MENTRY(_s)		\
      case YAML_##_s##_MAPPING_STYLE: style = LYAML_STR(_s); break

	MENTRY( ANY	);
	MENTRY( BLOCK	);
	MENTRY( FLOW	);
#undef MENTRY

      default:
         lua_pushfstring(L, "invalid mapping style %d", EVENTF (style));
         loader->error = 1;
         return;
   }

   parser_push_eventtable (loader, "MAPPING-START", 4);
   RAWSET_EVENTF (anchor);
   RAWSET_EVENTF (tag);
   RAWSET_BOOLEAN ("implicit", EVENTF (implicit));
   RAWSET_STRING ("style", style);
#undef EVENTF
}

static void
parse_MAPPING_END (struct lua_yaml_loader *loader) {
   parser_push_eventtable (loader, "MAPPING-END", 0);
}

static int
event_iter (lua_State *L)
{
   struct lua_yaml_loader *loader =
       (struct lua_yaml_loader *)lua_touserdata(L, lua_upvalueindex(1));
   char *str;

   delete_event(loader);
   if (yaml_parser_parse(&loader->parser, &loader->event) != 1) {
      generate_error_message(loader);
      lua_error (L);
   }

   loader->validevent = 1;

   lua_newtable (L);
   lua_pushliteral (L, "type");

   switch (loader->event.type) {
#define MENTRY(_s)		\
	   case YAML_##_s##_EVENT: parse_##_s (loader); break

	MENTRY( STREAM_START	);
	MENTRY( STREAM_END	);
	MENTRY( DOCUMENT_START	);
	MENTRY( DOCUMENT_END	);
	MENTRY( ALIAS		);
	MENTRY( SCALAR		);
	MENTRY( SEQUENCE_START	);
	MENTRY( SEQUENCE_END	);
	MENTRY( MAPPING_START	);
	MENTRY( MAPPING_END	);
#undef MENTRY

      case YAML_NO_EVENT:
	 lua_pushnil (L);
         break;
      default:
         lua_pushfstring(L, "invalid event %d", loader->event.type);
         loader->error = 1;
         break;
   }

   if (loader->error) lua_error (L);

   return 1;
}

static int loader_gc(lua_State *L) {
   struct lua_yaml_loader *loader = (struct lua_yaml_loader *)lua_touserdata(L, 1);
   if (loader) {
      delete_event(loader);
      yaml_parser_delete(&loader->parser);
   }
   return 0;
}

static int Pparser(lua_State *L) {
   struct lua_yaml_loader *loader;
   const unsigned char *str;

   /* requires a single string type argument */
   luaL_argcheck(L, lua_isstring(L, 1), 1, "must provide a string argument");
   str = lua_tostring(L, 1);

   /* create a user datum to store the parser */
   loader = (struct lua_yaml_loader *)lua_newuserdata(L, sizeof (*loader));
   memset ((void *) loader, 0, sizeof (*loader));
   loader->L = L;

   /* set its metatable */
   luaL_getmetatable(L, "lyaml.loader");
   lua_setmetatable(L, -2);

   /* try to initialize the parser */
   if (yaml_parser_initialize(&loader->parser) == 0)
      luaL_error(L, "cannot initialize parser for %s", str);
   yaml_parser_set_input_string(&loader->parser, str, lua_strlen(L, 1));

   /* create and return the iterator function, with the loader userdatum as
      its sole upvalue */
   lua_pushcclosure(L, event_iter, 1);
   return 1;
}
