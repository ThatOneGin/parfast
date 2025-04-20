lua = luac
lua_flags = -s
bin = parfast
lua_source = $(wildcard src/*.lua)
lua_location = $(shell which lua)

all: put_shebang

put_shebang: compile
	sed "1 i#!$(lua_location)" luac.out > $(bin)
	chmod +x $(bin)
	rm luac.out

compile:
	$(lua) $(lua_flags) $(lua_source)