" vim: foldmethod=marker
"
" BufSelect - a Vim buffer selection and deletion utility

" Default values for settings {{{1
let g:BufSelectKeyExit         = get(g:, 'BufSelectKeyExit',         'q')
let g:BufSelectKeyOpen         = get(g:, 'BufSelectKeyOpen',         'o')
let g:BufSelectKeySplit        = get(g:, 'BufSelectKeySplit',        's')
let g:BufSelectKeyVSplit       = get(g:, 'BufSelectKeyVSplit',       'v')
let g:BufSelectKeyDeleteBuffer = get(g:, 'BufSelectKeyDeleteBuffer', 'x')
let g:BufSelectKeySort         = get(g:, 'BufSelectKeySort',         'S')
let g:BufSelectSortOrder       = get(g:, 'BufSelectSortOrder',    'Name')
let g:BufSelectKeyChDir        = get(g:, 'BufSelectKeyChDir',       'cd')
let g:BufSelectKeyChDirUp      = get(g:, 'BufSelectKeyChDirUp',     '..')
let g:BufSelectKeySelectOpen   = get(g:, 'BufSelectKeySelectOpen',   '#')
let s:sortOptions = ["Num", "Status", "Name", "Extension", "Path"]

command! ShowBufferList :call <SID>ShowBufferList()   " {{{1

function! s:ShowBufferList()
    let s:bufnrSearch = 0
    let s:currBuffer = bufnr('%')
    let s:prevBuffer = bufnr('#')
    call s:RefreshBufferList(-1)
endfunction

function! s:RefreshBufferList(currentLine)   " {{{1
    call s:SwitchBuffers(-1, '')
    call s:FormatBufferNames()
    call s:DisplayBuffers()
    call s:SortBufferList()
    call s:SetPosition(a:currentLine)
    call s:SetupCommands()
endfunction

function! s:SwitchBuffers(nextBuffer, windowCmd)   " {{{1
    " Switch to the prev, curr, and next buffer in that order (if they exist)
    " to preserve or recalculate the # and % buffers.
    let old_ei = &eventignore
    set eventignore=all

    call s:SwitchBuffer(s:prevBuffer)

    if s:currBuffer != a:nextBuffer
        call s:SwitchBuffer(s:currBuffer)
    endif

    let &eventignore = old_ei
    execute a:windowCmd
    call s:SwitchBuffer(a:nextBuffer)
endfunction

function! s:SwitchBuffer(buffer)
    if bufexists(a:buffer)
        execute 'buffer ' . a:buffer
    endif
endfunction

function! s:CollectBufferNames()   " {{{1
    let l:tmpBuffers = split(execute('buffers'), '\n')
    return filter(l:tmpBuffers, 'v:val !~? "\\(Location\\|Quickfix\\) List"')
endfunction

function! s:FormatBufferNames()   " {{{1
    let l:tmpBuffers = s:CollectBufferNames()
    let l:filenameMaxLength = max(map(copy(l:tmpBuffers), 'strlen(fnamemodify(matchstr(v:val, "\"\\zs.*\\ze\""), ":t"))'))
    let s:filenameColumn = match(l:tmpBuffers[0], '"')
    let s:pathColumn = s:filenameColumn + l:filenameMaxLength + 2
    let s:bufferList = []
    for buf in l:tmpBuffers
        let bufferName = matchstr(buf, '"\zs.*\ze"')
        if filereadable(fnamemodify(bufferName, ':p'))
            " Parse the bufferName into filename and path.
            let bufferName = printf( '%-' . (l:filenameMaxLength) . 's  %s',
                                   \ fnamemodify(bufferName, ':t'),
                                   \ escape(fnamemodify(bufferName, ':h'), '\') )
        endif
        let buf = substitute(buf, '^\(\s*\d\+\)', '\1:', "")  " Put colon after buffer number.
        let buf = substitute(buf, '".*', bufferName, "")      " Replace quoted buffer name with parsed or unquoted buffer
        call add(s:bufferList, buf)
    endfor
endfunction

function! s:DisplayBuffers()   " {{{1
    let s:bufferListNumber = bufnr('-=[Buffers]=-', 1)
    execute 'silent buffer ' . s:bufferListNumber
    execute 'setlocal buftype=nofile noswapfile nonumber nowrap cursorline syntax=bufselect statusline='.escape("[Buffer List]  Press ? for Help", " ")
    setlocal modifiable
    %delete _
    call setline(1, s:bufferList)
    call append(line('$'), [repeat('-',100), 'CWD: ' . getcwd()])
    call s:UpdateFooter()
    setlocal nomodifiable
endfunction

function! s:SortBufferList()   " {{{1
    setlocal modifiable
    1,$-2sort n
    if g:BufSelectSortOrder != "Num"
        execute '1,$-2sort /^' . repeat('.', s:filenameColumn-1) . '/'
    endif
    if g:BufSelectSortOrder == "Status"
        execute '1,$-2sort! /^\s*\d\+:..\zs.\ze/ r'
    elseif g:BufSelectSortOrder == "Extension"
        execute '1,$-2sort /^' . repeat('.', s:filenameColumn-1) . '.*\.\zs\S*\ze\s/ r'
    elseif g:BufSelectSortOrder == "Path"
        execute '1,$-2sort /^' . repeat('.', s:pathColumn-1) . '/'
    endif
    setlocal nomodifiable
endfunction

function! s:UpdateFooter()   " {{{1
    let l:line = (g:BufSelectSortOrder == "Num" ? '===---' : '------').
               \ (g:BufSelectSortOrder == "Status" ? '=---' : '----').
               \ repeat(g:BufSelectSortOrder == "Name" ? '=' : '-', s:pathColumn - s:filenameColumn - 4).
               \ (g:BufSelectSortOrder == "Extension" ? '===-' : '----').
               \ repeat(g:BufSelectSortOrder == "Path" ? '=' : '-', 100 - s:pathColumn)
    setlocal modifiable
    call setline(line('$')-1, l:line)
    call setline(line('$'), printf('Sort: %-9s  CWD: %s', g:BufSelectSortOrder, getcwd()))
    setlocal nomodifiable
endfunction

function! s:SetPosition(currentLine)   " {{{1
    normal! gg0
    if a:currentLine != -1
        execute 'normal! '.a:currentLine.'gg0'
    elseif search('^\s*\d\+:\s*%', 'w') == 0
        call search('^\s*\d\+:\s*#', 'w')
    endif
endfunction

function! s:SetupCommands()   " {{{1
    execute "nnoremap <buffer> <silent> ".g:BufSelectKeyDeleteBuffer." :call <SID>CloseBuffer()\<CR>"
    execute "nnoremap <buffer> <silent> ".g:BufSelectKeyExit." :call <SID>ExitBufSelect()\<CR>"
    execute "nnoremap <buffer> <silent> ".g:BufSelectKeyOpen." :call <SID>SwitchBuffers(<SID>GetSelectedBuffer(), '')\<CR>"
    execute "nnoremap <buffer> <silent> ".g:BufSelectKeySplit." :call <SID>SwitchBuffers(<SID>GetSelectedBuffer(), 'wincmd s')\<CR>"
    execute "nnoremap <buffer> <silent> ".g:BufSelectKeyVSplit." :call <SID>SwitchBuffers(<SID>GetSelectedBuffer(), 'wincmd v')\<CR>"
    execute "nnoremap <buffer> <silent> ".g:BufSelectKeySort." :call <SID>ChangeSort()\<CR>"
    execute "nnoremap <buffer> <silent> ".g:BufSelectKeyChDir." :call <SID>ChangeDir()\<CR>"
    execute "nnoremap <buffer> <silent> ".g:BufSelectKeyChDirUp." :call <SID>ChangeDirUp()<CR>"
    execute "nnoremap <buffer> <silent> ".g:BufSelectKeySelectOpen." :call <SID>SelectOpenBuffers()<CR>"

    let l:i = 0
    while l:i < 10
        execute "nnoremap <buffer> <silent> ".l:i." :call <SID>SelectByNumber(".l:i.")<CR>"
        let l:i += 1
    endwhile
    nnoremap <buffer> <silent> ? :call <SID>ShowHelp()<CR>

    augroup BufSelectLinesBoundary
        autocmd!
        autocmd CursorMoved -=\[Buffers\]=- if line('.') > line('$')-2 | normal! G2k0 | endif
    augroup END
endfunction

function! s:GetSelectedBuffer()   " {{{1
    let lineOfText = getline(line('.'))
    let bufNum = matchstr(lineOfText, '^\s*\zs\d\+\ze:')
    return str2nr(bufNum)
endfunction

function! s:CloseBuffer()   " {{{1
    if len(s:CollectBufferNames()) == 1
        echomsg "Not gonna do it. The last buffer stays."
    else
        execute 'bwipeout ' . s:GetSelectedBuffer()
        call s:RefreshBufferList(line('.'))
    endif
endfunction

function! s:ExitBufSelect()   "{{{1
    if !bufexists(s:prevBuffer) && !bufexists(s:currBuffer)
        let s:currBuffer = s:GetSelectedBuffer()
    endif
    call s:SwitchBuffers(-1, '')
endfunction

function! s:ChangeSort()   " {{{1
    let g:BufSelectSortOrder = s:sortOptions[(index(s:sortOptions, g:BufSelectSortOrder) + 1) % len(s:sortOptions)]
    let l:currBuffer = s:GetSelectedBuffer()
    call s:SortBufferList()
    call s:UpdateFooter()
    call s:SetPosition(search('^\s*'.l:currBuffer.':', 'w'))
endfunction

function! s:ChangeDir()   " {{{1
    let l:currBuffer = s:GetSelectedBuffer()
    execute 'cd '.fnamemodify(bufname(l:currBuffer), ':p:h')
    call s:RefreshBufferList(line('.'))
endfunction

function! s:ChangeDirUp()   " {{{1
    cd ..
    call s:RefreshBufferList(line('.'))
endfunction

function! s:SelectOpenBuffers()   " {{{1
    call search('^\s*\d\+:\s*[%# ][ha]', 'w')
endfunction

function! s:SelectByNumber(num)   " {{{1
    let s:bufnrSearch = 10*s:bufnrSearch + a:num
    while !search('^\s*\d*'.s:bufnrSearch.'\d*:', 'w') && s:bufnrSearch > 0
        let s:bufnrSearch = s:bufnrSearch % float2nr(pow(10,floor(log10(s:bufnrSearch))))
    endwhile
endfunction

function! s:ShowHelp()   " {{{1
    echohl Special
    echomsg printf("%3s: Open the selected buffer in the current window.", g:BufSelectKeyOpen)
    echomsg printf("%3s: Split the window horizontally, and open the selected buffer there.", g:BufSelectKeySplit)
    echomsg printf("%3s: Split the window vertically, and open the selected buffer there.", g:BufSelectKeyVSplit)
    echomsg printf("%3s: Close the selected buffer using vim's :bwipeout command.", g:BufSelectKeyDeleteBuffer)
    echomsg printf("%3s: Change the sort order, cycling between Number, Status, Name, Extension, and Path.", g:BufSelectKeySort)
    echomsg printf("%3s: Change the working directory to that of the selected buffer", g:BufSelectKeyChDir)
    echomsg printf("%3s: Change the working directory up one level from current", g:BufSelectKeyChDirUp)
    echomsg printf("%3s: Highlight (move cursor to) the next open buffer, those marked with h or a.", g:BufSelectKeySelectOpen)
    echomsg printf("0-9: Highlight (move cursor to) the next buffer matching the cumulatively-typed buffer number.")
    echomsg printf("%3s: Exit the buffer list.", g:BufSelectKeyExit)
    echohl None
endfunction
