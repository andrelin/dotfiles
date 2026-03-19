syntax on
filetype plugin on

" Search
set incsearch       " search as you type
set hlsearch        " highlight matches
set ignorecase      " case-insensitive search...
set smartcase       " ...unless you use uppercase

" Indentation
set expandtab       " spaces instead of tabs
set tabstop=4       " tab width
set shiftwidth=4    " indent width
set autoindent      " keep indent on new lines

" UI
set number          " line numbers
highlight LineNr ctermfg=darkgrey guifg=#606060
augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave,WinEnter * if &nu && mode() != "i" | set rnu | endif
  autocmd BufLeave,FocusLost,InsertEnter,WinLeave * if &nu | set nornu | endif
augroup END
set ruler           " cursor position in status bar
set wildmenu        " tab completion menu for commands
set scrolloff=5     " keep 5 lines visible above/below cursor
set backspace=indent,eol,start  " backspace works as expected

" Mouse
set mouse=a         " enable mouse in all modes (scroll, click, select)

" Performance
set lazyredraw      " don't redraw during macros
