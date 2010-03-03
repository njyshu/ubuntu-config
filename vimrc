" Macro's .vimrc file
"
" Maintainer:  Macro <njyshu@gmail.com>
"
" To use it, copy it to
" for Unix and OS/2: ~/.vimrc
" for Amiga: s:.vimrc
" for MS-DOS and Win32: $HOME\.vimrc or $VIM\_vimrc
" for OpenVMS: sys$login:.vimrc
 
" ----------------------------------------------------------------------------
" Multi-encoding setting, MUST BE IN THE BEGINNING OF .vimrc!
"
function! s:MultiEncodingSetting()
  if has("multi_byte")
    " 设置中文支持
    set fileencodings=ucs-bom,utf-8,chinese

    if &fileencoding == ''
      let can_set_fenc = 1
    else
      let can_set_fenc = 0
    endif

    " CJK environment detection and corresponding setting
    if v:lang =~ "^zh_CN"
      " Simplified Chinese, on Unix euc-cn, on MS-Windows cp936
      set encoding=chinese
      set termencoding=chinese
      if can_set_fenc
        set fileencoding=chinese
      endif
    elseif v:lang =~ "^zh_TW"
      " Traditional Chinese, on Unix euc-tw, on MS-Windows cp950
      set encoding=taiwan
      set termencoding=taiwan
      if can_set_fenc
        set fileencoding=taiwan
      endif
    elseif v:lang =~ "^ja_JP"
      " Japanese, on Unix euc-jp, on MS-Windows cp932
      set encoding=japan
      set termencoding=japan
      if can_set_fenc
        set fileencoding=japan
      endif
    elseif v:lang =~ "^ko"
      " Korean on Unix euc-kr, on MS-Windows cp949
      set encoding=korea
      set termencoding=korea
      if can_set_fenc
        set fileencoding=korea
      endif
    endif
 
    " Detect UTF-8 locale, and override CJK setting if needed
    if v:lang =~ "utf8$" || v:lang =~ "UTF-8$"
      set encoding=utf-8
      if has("unix") && !has("win32unix")
        " Only use UTF-8 termencoding when we're in Linux/Unix, cause Windows
        " does not support UTF-8. Mac? I don't know :p
        set termencoding=utf-8
      end
      if can_set_fenc
        set fileencoding=utf-8
      endif
      set ambiwidth=double
    endif
  else
    echoerr 'Sorry, this version of (g)Vim was not compiled with "multi_byte"'
  endif
endfunction
 
 
" Toggle indent style smartly
function! s:ToggleIndentStyle(...)
  if a:0
    if a:1 == 8
      execute 'setlocal noexpandtab softtabstop=' . a:1 . ' shiftwidth=' . a:1
      if a:0 > 1
        echo 'Indent style changed to noexpandtab'
      endif
    else
      execute 'setlocal expandtab softtabstop=' . a:1 . ' shiftwidth=' . a:1
      if a:0 > 1
        echo 'Indent style changed to expandtab with ' . a:1 . ' spaces'
      endif
    endif
  else
 
    if &expandtab
      let b:previous_indent_width = &shiftwidth
      call s:ToggleIndentStyle(8, 1)
    else
      if !exists('b:previous_indent_width')
        let b:previous_indent_width = 4
      endif
      call s:ToggleIndentStyle(b:previous_indent_width, 1)
    endif
  endif
endfunction
 
 
" ----------------------------------------------------------------------------
" Initialization
" Commands only execute in Vim initialization
"
function! s:VimInit()
  " Use Vim settings, rather then Vi settings (much better!).
  " This must be first, because it changes other options as a side effect.
  " 去掉讨厌的有关vi一致性模式，避免以前版本的一些bug和局限
  set nocompatible
  call s:MultiEncodingSetting()
  source $VIMRUNTIME/mswin.vim
  behave xterm
  " Restore CTRL-A to increase number instead of Select All
  unmap <C-A>
endfunction
 
" When Vim is starting, the winpos information is not available
if getwinposx() == -1
  call s:VimInit()
endif
 
 
" ----------------------------------------------------------------------------
" Primary settings
"
 
" Backup only not in VMS and backup directory present
if has("vms")
  " 关闭自动备份，生成file~文件
  set nobackup    " do not keep a backup file, use versions instead
else
  if isdirectory("./.backup") || isdirectory($HOME . "/.backup")
    set backup
    set backupdir=./.backup,~/.backup
  else
    set nobackup
  endif
endif
 
" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
  " 语法高亮度显示
  syntax on
  " 默认情况下，寻找匹配是高亮度显示的，该设置关闭高亮显示
  " set nohls
  " 开启匹配时的高亮
  set hlsearch
endif
 
" Only do this part when compiled with support for autocommands.
if has("autocmd")
 
  " Enable file type detection.
  " Use the default filetype settings, so that mail gets 'tw' set to 72,
  " 'cindent' is on in C files, etc.
  " Also load indent files, to automatically do language-dependent indenting.
  " 检测文件的类型  filetype on
  filetype plugin indent on
 
  " Put these in an autocmd group, so that we can delete them easily.
  augroup vimrcEx
    au!
 
    " For all text files set 'textwidth' to 78 characters.
    autocmd FileType text setlocal textwidth=78
 
    autocmd FileType c compiler gcc
    autocmd FileType d compiler dmd
    autocmd FileType delphi compiler borland
    autocmd FileType php compiler php
    autocmd FileType ruby,eruby
          \ setlocal omnifunc=rubycomplete#Complete |
          \ setlocal tags+=~/.gem/tags |
          \ call s:ToggleIsKeyword(':,?,!', 1) |
 
    let s:indent2_regex = '^\%(e\=ruby\|[yh]aml\|delphi\|x\=html\|nsis\|vim\)$'
    let s:indent8_regex = '^\%(css\|gitconfig\)$'
 
    function! s:BufEnter()
      " Set indent style for diffent file type
      if &ft =~ s:indent2_regex
        call s:ToggleIndentStyle(2)
      elseif &ft =~ s:indent8_regex
        call s:ToggleIndentStyle(8)
      else
        call s:ToggleIndentStyle(4)
      endif
 
      " Change to directory of current file automatically when current file is not
      " on remote server nor inside an archive file like .zip/.tgz
      if bufname('%') !~ '::\|://'
        lcd %:p:h
      endif
      if exists("b:rails_root")
        let g:rails_root_dir = b:rails_root
      endif
    endfunction
 
    autocmd BufEnter * call s:BufEnter()
 
    " Apply file template if it exists
    autocmd BufNewFile *
          \ set ff=unix |
          \ let s:Template = expand('~/.template/template.' . substitute(bufname("%"), '.\{-\}\.*\([^.]*\)$', '\1', '')) |
          \ if filereadable(s:Template) |
          \ execute "0read " . s:Template |
          \ normal Gdd |
          \ endif |
 
    " When editing a file, always jump to the last known cursor position.
    " Don't do it when the position is invalid or when inside an event handler
    " (happens when dropping a file on gvim).
    autocmd BufReadPost *
          \ if line("'\"") > 0 && line("'\"") <= line("$") |
          \ execute "normal g`\"" |
          \ endif |
 
  augroup END
endif " has("autocmd")
 
 
" ----------------------------------------------------------------------------
" My customizations
"
" Set options
" 设置vim正文自动缩进，即将当前行的对齐格式应用到下一行,在编写代码时有用
set autoindent
" 设置tab键跳过的空格数，如4个空格
" set tabstop=4
" 设置tab键的宽度
" set softtabstop=4
" 换行时行间交错使用4个空格
" set shiftwidth=4
" 设置匹配模式，类似当输入一个左括号时会匹配相应的那个右括号
" 当vim进行编辑时，如果命令错误，会发出一个响声，该设置去掉响声
set vb t_vb=
" 高亮当前行
set cursorline
" 设置颜色方案,方案的vim插件目录在~/.vim/colors和/usr/local/share/vim/vim72/colors中查找
" colorscheme torte  " 查找torte.vim
" 关掉工具条
" set go=e
" 设置匹配模式，类似当输入一个左括号时会匹配相应的那个右括号
set showmatch
" allow backspacing over everything in insert mode设置退格键可用
set backspace=indent,eol,start
if v:version >= 700
  set completeopt=menuone,preview
end
set directory=~/.tmp,.,/var/tmp,/tmp
set fileformats=unix,dos
set grepprg=grep\ -nH\ $*
" 去除vim的GUI版本中的toolbar
" set guioptions=T
" set guioptions=gmrLtT
set helplang=CN
" 记录历史的行数
set history=50
" ignorecase选项是忽略正则表达式中大小写字母的区别
set ignorecase smartcase smartcase
" 查询时非常方便，如要查找book单词，当输入到/b时，会自动找到第一个b开头的单词
" 进行查找时，使用此设置会快速找到答案,当你找要匹配的单词时，别忘记回车
set incsearch
set laststatus=2
set linebreak
set list
if v:version < 700
  set listchars=tab:>-,trail:-
else
  set listchars=tab:>-,trail:-,nbsp:%
endif
set modeline
" 显示行号或用set nu!简写
set number
" 在编辑过程中，在右下角显示光标位置的状态行(显示所在行、列的位置)
set ruler
set runtimepath=$HOME/.vim,$VIM/vimfiles,$VIMRUNTIME,$VIM/vimfiles/after,$HOME/.vim/after
" 设置换行标识符，表示该行与上一行是同一行
set sbr=->
set ai!      " 设置自动缩进
set shellslash
" display incomplete commands
set showcmd
" 依据上一行的对齐格式，智能选择该行的方式，对于类似C语言编写上很有用。它与autoindent结合使用
set smartindent
set viminfo=!,'1000,<100,c,f1,h,s10,rA:,rB:,n~/.viminfo
set virtualedit=block
set visualbell
set wildmenu
 
if v:version < 700
  set diffopt=filler
else
  set diffopt=filler
endif
set diffexpr=MyDiff()
function! MyDiff()
  let opt = ' -a --binary '
  if &diffopt =~ 'icase' | let opt = opt . '-i ' | endif
  if &diffopt =~ 'iwhite' | let opt = opt . '-b ' | endif
  let arg1 = v:fname_in
  if arg1 =~ ' ' | let arg1 = '"' . arg1 . '"' | endif
  let arg2 = v:fname_new
  if arg2 =~ ' ' | let arg2 = '"' . arg2 . '"' | endif
  let arg3 = v:fname_out
  if arg3 =~ ' ' | let arg3 = '"' . arg3 . '"' | endif
  let diffprg = $VIMRUNTIME . "/diff"
  if !executable(diffprg)
    let diffprg = "diff"
  endif
  silent execute '!' . diffprg . opt . arg1 . ' ' . arg2 . ' > ' . arg3
endfunction
 
" Force read viminfo
try
  rviminfo ~/.viminfo
catch
endtry
 
" GUI version settings
if has("gui_running")
  if has("gui_macvim") && v:version >= 700
    " Define a font list for MacOS with corresponding winsize and winpos arguments list
    let s:GuiFontList = [
          \"Monaco:h12",
          \"Bitstream\\ Vera\\ Sans\\ Mono\\ 11",
          \"DejaVu\\ Sans\\ Mono\\ 11",
          \"Inconsolat1\\ 11",
          \]
 
    let s:WinSizeList = [
          \[138, 43],
          \[138, 43],
          \[138, 43],
          \[138, 43]
          \]
 
    let s:WinPosList = [
          \[5, 50],
          \[5, 50],
          \[5, 50],
          \[5, 50]
          \]
  end
 
  if has("gui_gtk2") && v:version >= 700
    " Define a font list for GTK2 with corresponding winsize and winpos arguments list
    " 删除了没有的字体\"Inconsolat1\\11",其他字体安装在winfonts中，是从网上下载的
    " 如果不删除则在用F8更换几种字体时，系统会找一个很丑的字体来替换
    let s:GuiFontList = [
          \"Monaco\\ 11",
          \"Bitstream\\ Vera\\ Sans\\ Mono\\ 11",
          \"DejaVu\\ Sans\\ Mono\\ 11",
          \"Courier\\ 12"
          \]
    " 这个会导致终端变形,所以改为和终端大小一样，这样在用gvim命令时，gvim大小与终端是一样大的
    let s:WinSizeList = [
          \[80, 25],
          \[80, 25],
          \[80, 25],
          \[80, 25],
          \]
 
    let s:WinPosList = [
          \[400, 0],
          \[400, 0],
          \[400, 0],
          \[400, 0],
          \]
  end
 
  if has("gui_win32") && v:version >= 700
    " Define a font list for Win32 with corresponding winsize and winpos arguments list
    let s:GuiFontList = [
          \"Monaco:h10",
          \"SimSun:h11",
          \"Courier_New:h12",
          \"Bitstream_Vera_Sans_Mono:h11",
          \"Fixedsys:h11",
          \"Lucida_Console:h11",
          \"Terminal:h12:cGB2312"
          \]
 
    let s:WinSizeList = [
          \[256, 64],
          \[256, 64],
          \[256, 64],
          \[256, 64],
          \[256, 64],
          \[256, 64],
          \[256, 64]
          \]
 
    let s:WinPosList = [
          \[9, -4],
          \[9, -4],
          \[9, -4],
          \[9, -4],
          \[9, -4],
          \[6, -4],
          \[9, -4]
          \]
  end
 
  " Set default index to 0
  if !exists("g:CUR_FONT_INDEX") || g:CUR_FONT_INDEX < 0 || g:CUR_FONT_INDEX >= len(s:GuiFontList)
    let g:CUR_FONT_INDEX = 0
  endif
 
  " Set GUI font by index
  function! s:SetGuiFont(Index)
    try
      " 设置字体，字体名称和字号
      execute 'set guifont=' . s:GuiFontList[a:Index]
    catch
      return 1
    endtry
  endfunction
 
  function! s:SetWinSize(Index)
    execute 'winsize ' . s:WinSizeList[a:Index][0] . ' ' .
          \ s:WinSizeList[a:Index][1]
  endfunction
 
  " Set window pos by index
  function! s:SetWinPos(Index)
    let WinPosX = s:WinPosList[a:Index][0]
    let WinPosY = s:WinPosList[a:Index][1]
    if WinPosX != getwinposx() || WinPosY != getwinposy()
      execute 'winpos ' . WinPosX . ' ' . WinPosY
    endif
  endfunction

  " Initialize GUI font and window settings
  call s:SetGuiFont(g:CUR_FONT_INDEX)
  call s:SetWinSize(g:CUR_FONT_INDEX)
  " Only effect when reload .vimrc
  call s:SetWinPos(g:CUR_FONT_INDEX)
  " Add to some event so they can auto execute when need
  if has("autocmd")
    autocmd GUIEnter * call s:SetWinPos(g:CUR_FONT_INDEX)
    autocmd WinEnter * call s:SetWinPos(g:CUR_FONT_INDEX)
  endif
  color desert
else
  " Console version settings
  " 背景使用黑色
  set background=dark
endif
 
" Customizing some default highlight
function! s:CustomHighlight()
  if !exists("g:colors_name") || g:colors_name == "default"
    highlight LineNr gui=NONE guifg=#666666 guibg=#e8e8e8 cterm=NONE ctermfg=DarkGray ctermbg=LightGray
    " Status line
    highlight User1 gui=bold guifg=#000000 guibg=#f3f3f3 cterm=NONE ctermfg=Black ctermbg=LightGray
    highlight User2 gui=bold guifg=#888888 guibg=#f3f3f3 cterm=NONE ctermfg=DarkGray ctermbg=LightGray
    highlight User3 gui=bold guifg=#0000ff guibg=#f3f3f3 cterm=NONE ctermfg=Blue ctermbg=LightGray
    highlight User4 gui=bold guifg=#ff0000 guibg=#f3f3f3 cterm=NONE ctermfg=Red ctermbg=LightGray
  endif
endfunction
 
call s:CustomHighlight()
if has("autocmd")
  autocmd CursorHold * call s:CustomHighlight()
  autocmd FocusGained * call s:CustomHighlight()
  autocmd VimEnter * call s:CustomHighlight()
endif
 
" Customizing status line
function! CustomStatusLineBufSize()
  let BufSize = line2byte(line("$") + 1) - 1
  if BufSize < 0
    let BufSize = 0
  endif
  " Add commas
  let Remain = BufSize
  let BufSize = ""
  while strlen(Remain) > 3
    let BufSize = "," . strpart(Remain, strlen(Remain) - 3) . BufSize
    let Remain = strpart(Remain, 0, strlen(Remain) - 3)
  endwhile
  let BufSize = Remain . BufSize
  let BufSize = BufSize . ' byte'
  return BufSize
endfunction
 
if has("gui_running")
  execute 'set statusline=%<%1*%f\ %h%m%r%2*\|' .
        \ '%3*%{&ff}%2*:%3*%{&fenc}%2*:%3*%{&ft}%2*\|' .
        \ '%{CustomStatusLineBufSize()}' .
        \ '%=%b\ 0x%B\ \ \|' .
        \ '%1*sts%2*:%3*%{&sts}%2*:%1*sw%2*:%3*%{&sw}%2*:' .
        \ '%1*ts%2*:%3*%{&ts}%2*:%1*tw%2*:%3*%{&tw}%2*\|' .
        \ '%06(%l%),%03(%v%)\ %1*%4.4P'
else
  execute 'set statusline=%<%1*%f\ %h%m%r%2*\|' .
        \ '%3*%{&ff}%2*:%3*%{&fenc}%2*:%3*%{&ft}%2*\|' .
        \ '%{CustomStatusLineBufSize()}' .
        \ '%=%b\ 0x%B\ \ ' .
        \ '%06(%l%),%03(%v%)\ %1*%4.4P'
endif
 
 
" ----------------------------------------------------------------------------
" Key mappings
"
" Up & Down is display line upward & downward
map <Up> gk
map <Down> gj
imap <Up> <Esc><Up>a
imap <Down> <Esc><Down>a
 
" F1 is toggle indent style smartly
map <F1> :call <SID>ToggleIndentStyle()<CR>
imap <F1> :call <Esc><F1>a
 
" Shift-F1 is Toggle iskeyword contain or not contain '_'
map <S-F1> :call <SID>ToggleIsKeyword('_')<CR>
imap <S-F1> <Esc><S-F1>a
 
function! s:ToggleIsKeyword(...)
  " Second param means 'force add', not 'toggle'
  if a:0 > 1 || stridx(&iskeyword, a:1) < 0
    exec "setlocal iskeyword+=" . a:1
  else
    exec "setlocal iskeyword-=" . a:1
  endif
endfunction
 
" F2 is Toggle wrap
map <F2> :call <SID>ToggleGuiOption("b")<CR>:set wrap!<CR>
imap <F2> <Esc><F2>a

function! s:ToggleGuiOption(option)
  " If a:option is already set in guioptions, then we want to remove it
  if match(&guioptions, "\\C" . a:option) > -1
    exec "set go-=" . a:option
  else
    exec "set go+=" . a:option
  endif
  " if has("gui_running")
  " call s:SetWinPos(g:CUR_FONT_INDEX)
  " endif
endfunction
 
" F3 is Reverse hlsearch
map <F3> :set hlsearch!<CR>
imap <F3> <Esc><F3>a

" F4 is Toggle Tag List
" Rails Tag List will config this
" map <F4> :TlistToggle<CR>
" imap <F4> <Esc><F4>a

" F5 is Toggle Mini Buffer Explorer
map <F5> :TMiniBufExplorer<CR>
imap <F5> <Esc><F5>a

" F6 is Hex view
map <F6> :%!xxd<CR>
imap <F6> <Esc><F6>a

" F7 is Toggle spell check
map <F7> :set spell!<CR>
imap <F7> <Esc><F7>a

" F8 is Change GUI font
if has("gui_running")
  map <F8> :call <SID>ChangeGuiFont(0)<CR>
  map <S-F8> :call <SID>ChangeGuiFont(1)<CR>
  imap <F8> <Esc><F8>a
  imap <S-F8> <Esc><S-F8>a
 
  function! s:ChangeGuiFont(Inverse)
    let OldIndex = g:CUR_FONT_INDEX
    if a:Inverse == 0
      let g:CUR_FONT_INDEX = g:CUR_FONT_INDEX + 1
      if g:CUR_FONT_INDEX >= len(s:GuiFontList)
        let g:CUR_FONT_INDEX = 0
      endif
    else
      let g:CUR_FONT_INDEX = g:CUR_FONT_INDEX - 1
      if g:CUR_FONT_INDEX < 0
        let g:CUR_FONT_INDEX = len(s:GuiFontList) - 1
      endif
    endif
    " Here we use &tenc that set above to ensure the system locale
    if s:SetGuiFont(g:CUR_FONT_INDEX) == 0
      call s:SetWinSize(g:CUR_FONT_INDEX)
      call s:SetWinPos(g:CUR_FONT_INDEX)
      echo iconv("\rGUI font has changed to \"" .
            \ s:GuiFontList[g:CUR_FONT_INDEX] . '"', &tenc, &enc)
    else
      call s:SetWinSize(OldIndex)
      call s:SetWinPos(OldIndex)
      echohl ErrorMsg | echo iconv("\rError changing GUI font. Maybe selected font \"" .
            \ s:GuiFontList[g:CUR_FONT_INDEX] . "\" not exists.", &tenc, &enc)
            \ | echohl None
    endif
  endfunction
endif
 
" F9 is Compile and Run
map <F9> :call <SID>Run()<CR>
imap <F9> <Esc><F9>a
 
function! s:Run()
  if exists("b:current_compiler")
    make
  endif
 
  let ExeFile = substitute(bufname('%'), '\.[^.]\+$', '.exe', '')
  if filereadable(ExeFile)
    if has("win32")
      execute '!.\"' . ExeFile . '"'
    else
      execute '!./"' . ExeFile . '"'
    endif
  elseif !exists("b:current_compiler")
    " Only try to execute current file as script when no CompilerSet
    if has("win32")
      execute '!.\"' . bufname('%') . '"'
    else
      execute '!./"' . bufname('%') . '"'
    endif
  endif
endfunction
 
" CTRL-F9 is Compile
map <C-F9> :call <SID>Compile()<CR>
imap <C-F9> <Esc><C-F9>a
 
function! s:Compile()
  if exists("b:current_compiler")
    make
  else
    echohl ErrorMsg | echo "No CompilerSet for this type of file" | echohl None
  endif
endfunction
 
" CTRL-Tab is Next buffer
" Mini Buffer Explorer already provided this feature
" map <C-Tab> :bnext!<CR>
" imap <C-Tab> <Esc>:bnext!<CR>
" cmap <C-Tab> <Esc>:bnext!<CR>
 
" CTRL-SHIFT-Tab is Previous buffer
" Mini Buffer Explorer already provided this feature
" map <C-S-Tab> :bNext!<CR>
" imap <C-S-Tab> <Esc>:bNext!<CR>
" cmap <C-S-Tab> <Esc>:bNext!<CR>
 
" CTRL-H is help for PHP
nmap <C-H> "hyiw:call <SID>ShowPHPHelp(@h)<CR>
 
function! s:ShowPHPHelp(function)
  execute '!start "hh.exe" "N:\CompDoc\php_manual_zh\php_manual_zh.chm::/_function.html\#' . a:function
endfunction
 
" ,* is Substitute(Replace)
nmap ,* :%s/<C-R><C-W>/
 
" ,ff is format code
nmap ,f :set ff=unix<CR>:%!dos2unix<CR>gg=G:%s/\s\+$//ge<CR>
 
" ,fc is clean code
nmap ,fc :set ff=unix<CR>:%!dos2unix<CR>:%s/\s\+$//ge<CR>
 
" Make it easy to update/reload .vimrc
nmap ,s :source $HOME/.vimrc<CR>
nmap ,v :e $HOME/.vimrc<CR>
 
" ,> ,< is next or prev error
nmap ,> :cnext<CR>
nmap ,< :cNext<CR>
 
" \date \time Insert current date & time
nmap <Leader>date :call <SID>InsertDate(0)<CR>
nmap <Leader>time :call <SID>InsertDate(1)<CR>
 
function! s:InsertDate(Also_Time)
  let Fmt = '%x'
  if a:Also_Time
    let Fmt .= ' %X'
  endif
  let Time = strftime(Fmt)
  execute 'normal a' . Time
endfunction
 
" \tu \tg Convert to UTF-8, Convert to GBK
nmap <Leader>tu :set fenc=utf8<CR>:w<CR>
nmap <Leader>tg :set fenc=gbk<CR>:w<CR>
 
" \sym String to Symbol for Ruby
nmap <Leader>sym :%s/[\\]\@<!\(['"]\)\(\w\+\)\1/:\2/gce<CR>
vmap <Leader>sym :s/[\\]\@<!\(['"]\)\(\w\+\)\1/:\2/gce<CR>
 
" Don't use Ex mode, use Q for formatting
nmap Q gq
 
" Emacs-style editing on the command-line
" start of line
cnoremap <C-A> <Home>
" back one character
cnoremap <C-B> <Left>
" delete character under cursor
cnoremap <C-D> <Del>
" end of line
cnoremap <C-E> <End>
" forward one character
cnoremap <C-F> <Right>
" recall newer command-line
cnoremap <C-N> <Down>
" recall previous (older) command-line
cnoremap <C-P> <Up>
" back one word
cnoremap <Esc><C-B> <S-Left>
" forward one word
cnoremap <Esc><C-F> <S-Right>
 
 
" ----------------------------------------------------------------------------
" Configurations for plugins
"
" Mini Buffer Explorer configurations
let g:miniBufExplSplitBelow = 1
let g:miniBufExplMapWindowNavVim = 1
let g:miniBufExplMapWindowNavArrows = 1
let g:miniBufExplMapCTabSwitchBufs = 1
let g:miniBufExplModSelTarget = 1
 
" let g:miniBufExplorerDebugMode = 2
" let g:miniBufExplorerDebugLevel = 10
 
 
" std_c
let c_syntax_for_h = 1
let c_C94 = 1
let c_C99 = 1
let c_cpp = 1
let c_warn_8bitchars = 1
let c_warn_multichar = 1
let c_warn_digraph = 1
let c_warn_trigraph = 1
let c_no_octal = 1
 
let c_comment_strings = 1
let c_comment_numbers = 1
let c_comment_types = 1
let c_comment_date_time = 1
 
 
" EnhCommentify
let g:EnhCommentifyFirstLineMode = 'yes'
let g:EnhCommentifyUseAltKeys = 'yes'
let g:EnhCommentifyUseSyntax = 'yes'
let g:EnhCommentifyPretty = 'yes'
 
 
" Twitter
let g:twitterusername = 'rainux'
let g:twitterpassword = ''
let g:twitterencoding = 'gb2312'
 
nmap <Leader>tp <Esc>:let g:twitterpassword=inputsecret('password? ')<CR>
nmap <Leader>tw <Esc>:execute 'TwitterStatusUpdate ' . inputdialog('Enter a Twitter status message:')<CR>
nmap <Leader>tf <Esc>:TwitterFriendsTimeline<CR>
 
 
" PHP highlighting
let g:php_baselib = 1
let g:php_oldStyle = 1
let g:php_folding = 1
 
 
" rubycomplete
let g:rubycomplete_buffer_loading = 1
let g:rubycomplete_classes_in_global = 1
let g:rubycomplete_rails = 1
let g:rubycomplete_rails_proactive = 1
 
 
" NERD commenter
let g:NERDDefaultNesting = 1
let g:NERDShutUp = 1
let g:NERDSpaceDelims = 1
 
 
" vcscommand
nmap <Leader>va <Plug>VCSAdd
nmap <Leader>vn <Plug>VCSAnnotate
nmap <Leader>vG <Plug>VCSClearAndGotoOriginal
nmap <Leader>vc <Plug>VCSCommit
nmap <Leader>vD <Plug>VCSDelete
nmap <Leader>vd <Plug>VCSDiff
nmap <Leader>vg <Plug>VCSGotoOriginal
nmap <Leader>vi <Plug>VCSInfo
nmap <Leader>vL <Plug>VCSLock
nmap <Leader>vl <Plug>VCSLog
nmap <Leader>vq <Plug>VCSRevert
nmap <Leader>vr <Plug>VCSReview
nmap <Leader>vs <Plug>VCSStatus
nmap <Leader>vU <Plug>VCSUnlock
nmap <Leader>vu <Plug>VCSUpdate
nmap <Leader>vv <Plug>VCSVimDiff

" eclipse的移动行
nmap :move .+1
nmap :move .-2
imap :move .+1
imap :move .-2
vmap :move ‘>+1gv
vmap :move ‘< -2gv

" svncommand
let g:SVNCommandEnableBufferSetup = 1
let g:SVNCommandCommitOnWrite = 1
let g:SVNCommandEdit = 'split'
let g:SVNCommandNameResultBuffers = 1
let g:SVNCommandAutoSVK = 'svk'
 
 
" rails.vim
let g:rails_subversion = 1
 
 
" Rails Tag List
"
" Central additions (also add the functions below)
command! RTlist call CtagAdder("app/models","app/controllers","app/views","public")
 
map <S-F4> :RTlist<CR>
 
" Optional, handy TagList settings
nnoremap <silent> <F4> :Tlist<CR>
inoremap <F4> <Esc><F4>a
 
let Tlist_Compact_Format = 1
let Tlist_Ctags_Cmd = 'ctags --fields=+lS'
let Tlist_File_Fold_Auto_Close = 1
 
let Tlist_Use_Right_Window = 1
let Tlist_Exit_OnlyWindow = 1
 
let Tlist_WinWidth = 40
 
" Function that gets the dirtrees for the provided dirs and feeds
" them to the TlAddAddFiles function below
function! CtagAdder(...)
  let index = 0
  let s:dir_list = ''
  let is_rails_dir = 0
  while index < a:0
    let index = index + 1
    if isdirectory(a:{index}) || isdirectory(g:rails_root_dir . '/' . a:{index})
      let is_rails_dir = 1
    else
      continue
    end
    let s:dir_list = s:dir_list . TlGetDirs(a:{index})
  endwhile
  if is_rails_dir
    call TlAddAddFiles(s:dir_list)
    wincmd p
    exec "normal ="
    wincmd p
  else
    echohl ErrorMsg | echo "This directory does not contain a Rails project" | echohl None
  end
endfunc
 
" Adds *.rb, *.rhtml and *.css files to TagList from a given list
" of dirs
function! TlAddAddFiles(dir_list)
  let dirlist = a:dir_list
  let s:olddir = getcwd()
  while strlen(dirlist) > 0
    let curdir = substitute (dirlist, '|.*', "", "")
    let dirlist = substitute (dirlist, '[^|]*|\?', "", "")
    exec "cd " . g:rails_root_dir
    exec "TlistAddFiles " . curdir . "/*.rb"
    exec "TlistAddFiles " . curdir . "/*.rhtml"
    exec "TlistAddFiles " . curdir . "/*.css"
    exec "TlistAddFiles " . curdir . "/*.js"
  endwhile
  exec "cd " . s:olddir
endfunc
 
" Gets all dirs within a given dir, returns them in a string,
" separated by '|''s
function! TlGetDirs(start_dir)
  let s:olddir = getcwd()
  exec "cd " . g:rails_root_dir . '/' . a:start_dir
  let dirlist = a:start_dir . '|'
  let dirlines = glob ('*')
  let dirlines = substitute (dirlines, "\n", '/', "g")
  while strlen(dirlines) > 0
    let curdir = substitute (dirlines, '/.*', "", "")
    let dirlines = substitute (dirlines, '[^/]*/\?', "", "")
    if isdirectory(g:rails_root_dir . '/' . a:start_dir . '/' . curdir)
      let dirlist = dirlist . TlGetDirs(a:start_dir . '/' . curdir)
    endif
  endwhile
  exec "cd " . s:olddir
  return dirlist
endfunc
 
 
" ----------------------------------------------------------------------------
" Extra: Automatic update the "Last change" date of a file
"
" Automatic update the "Last Change" date of any file
" Need to be improved, e.g. compatible with Subversion's "Date" keyword,
" or (and) search only in 5 lines near head and tail of file.
function! s:UpdateLastChange()
  let LineNr = search('^.*Last change:\s\+.*', 'nw')
  let Line = getline(LineNr)
  let Saved_Lang = v:lc_time
  lang time C
  let Time = strftime('%Y %b %d')
  execute 'lang time ' . Saved_Lang
  let Line = substitute(Line, '\(^.*Last change:\s\+\)\(.*$\)', '\1' .
        \ Time, '')
  call setline(LineNr, Line)
endfunction

colorscheme vividchalk

" 打开javascript折叠
let b:javascript_fold=1
" 打开javascript对dom、html和css的支持
let javascript_enable_domhtmlcss=1
" 设置字典 ~/.vim/dict/javascript.dict是字典文件的路径
autocmd FileType javascript set dictionary=~/.vim/dict/javascript.dict

" if has("autocmd")
  " autocmd BufWritePre * call s:UpdateLastChange()
" endif
 
" vim: set sts=2 sw=2:
