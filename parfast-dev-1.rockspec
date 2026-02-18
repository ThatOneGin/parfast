package = "parfast"
version = "dev-1"
source = {
   url = "git+https://github.com/ThatOneGin/parfast"
}
description = {
   detailed = [[
>NOTE: This new branch is for rewriting the compiler for many reasons
>and mostly because the majority of this code is bad in many ways,
>this is also the reason why the development was paused
>for some months.]],
   homepage = "https://github.com/ThatOneGin/parfast",
   license = "MIT"
}
build = {
   type = "builtin",
   modules = {
      ["parfast.ast"] = "parfast/ast.lua",
      ["parfast.compiler"] = "parfast/compiler.lua",
      ["parfast.comptime"] = "parfast/comptime.lua",
      ["parfast.header"] = "parfast/header.lua",
      ["parfast.lex"] = "parfast/lex.lua",
      ["parfast.parfastc"] = "parfast/parfastc.lua",
      ["parfast.parser"] = "parfast/parser.lua",
      ["parfast.symtab"] = "parfast/symtab.lua",
      ["parfast.union"] = "parfast/union.lua",
      ["parfast.util"] = "parfast/util.lua"
   },
   copy_directories = {
      "tests"
   },
   install = {
      bin = {
         "bin/parfast"
      }
   }
}
