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
      parfastc = "parfast/parfastc.lua",
      util = "parfast/util.lua",
      union = "parfast/union.lua"
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
