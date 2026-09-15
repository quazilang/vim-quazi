" Quazi support for Vim through vim-lsp. Neovim uses plugin/quazi.lua instead.
if has('nvim') || exists('g:loaded_quazi_vim')
  finish
endif
let g:loaded_quazi_vim = 1

augroup quazi_filetype
  autocmd!
  autocmd BufRead,BufNewFile *.qz setlocal filetype=quazi
augroup END

function! s:quazi_lsp_command() abort
  let l:command = empty($QUAZI_LSP_COMMAND) ? 'qz' : $QUAZI_LSP_COMMAND
  return [l:command, 'lsp']
endfunction

function! s:register_quazi_lsp() abort
  if exists('g:quazi_vim_lsp_registered')
    return
  endif
  let g:quazi_vim_lsp_registered = 1
  call lsp#register_server({
        \ 'name': 'quazi',
        \ 'cmd': {server_info -> s:quazi_lsp_command()},
        \ 'allowlist': ['quazi'],
        \ })
endfunction

if exists('*lsp#register_server')
  call s:register_quazi_lsp()
else
  augroup quazi_vim_lsp
    autocmd!
    autocmd User lsp_setup call s:register_quazi_lsp()
  augroup END
endif
