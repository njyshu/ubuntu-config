" Vim support file to define the default menus
" You can also use this as a start for your own set of menus.
"
" Maintainer:	Bram Moolenaar <Bram@vim.org>
" Last Change:	2005 Oct 01

" Note that ":an" (short for ":anoremenu") is often used to make a menu work
" in all modes and avoid side effects from mappings defined by the user.

" Make sure the '<' and 'C' flags are not included in 'cpoptions', otherwise
" <CR> would not be recognized.  See ":help 'cpoptions'".

an 50.740 &Syntax.&Convert\ to\ XHTML	:let html_use_css=1<CR>:let use_xhtml=1<CR>:runtime syntax/2html.vim<CR>

" vim: set sw=2 :
