" Vim compiler file
" Compiler: DMD Runner
" Maintainer:   oldrev
" Last Change:  2007/03/28

if exists("current_compiler")
  finish
endif
let current_compiler = "dmd"

if exists(":CompilerSet") != 2      " older Vim always used :setlocal
  command -nargs=* CompilerSet setlocal
endif

let s:cpo_save = &cpo
set cpo-=C

CompilerSet makeprg=dmd\ -run\ %

CompilerSet errorformat=%f:%l:%m

let &cpo = s:cpo_save
unlet s:cpo_save

" vim: nowrap sw=2 sts=2 ts=8 ff=unix:
