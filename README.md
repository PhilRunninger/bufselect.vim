# bufselect.vim

This is a minimalist alternative to [bufexplorer](https://github.com/jlanzarotta/bufexplorer) and [buffergator](https://github.com/jeetsukumaran/vim-buffergator), both of which I'd used in the past. I wanted this plugin to be a lot lighter weight, so I removed functionality I didn't really find necessary. What it ended up being is:

* a very clean list that shows the buffer number, filename, and relative path of the buffers you see in the `:ls` command
* a few key mappings to do the following tasks:
    * open buffers, including into splits (**`o`**, **`s`**, **`v`**)
    * delete buffers (**`x`**)
    * sort the list (**`S`**)
* a single command to kick things off (**`:ShowBufferList`**)
* a non-persistent list of buffers. The buffer list is generated each time the command is called, rather than being maintained behind the scenes with autocommands. This simplifies the code considerably.

## Installation

Use your favorite plugin manager to install this plugin. My personal favorite is [vim-plug](https://github.com/junegunn/vim-plug). In your **`.vimrc`**, add the following line.
```vim
Plug 'git@github.com:PhilRunninger/bufselect.vim.git'
```

[Vundle](https://github.com/VundleVim/Vundle.vim), [pathogen](https://github.com/tpope/vim-pathogen), and others should also work as easily. Just follow the convention set up by the plugin manager of your choice.

## Command

The only command is **`:ShowBufferList`**, which can be assigned to a key. For example,
```vim
nnoremap <silent> <leader>b :ShowBufferList<CR>
```
The mapping is not done by this plugin, so as not to interfere with any existing mappings you may have.

## Settings
### Key Mappings

The following key mappings are used only within the **`[Buffer List]`** buffer. They are configurable by setting the corresponding global variables.

Default Key | Variable                  | Function
---|---|---
**`o`**     | `g:BufSelectOpen`         | Open the selected buffer in the current window.
**`s`**     | `g:BufSelectSplit`        | Split the window horizontally, and open the selected buffer there.
**`v`**     | `g:BufSelectVSplit`       | Split the window vertically, and open the selected buffer there.
**`x`**     | `g:BufSelectDeleteBuffer` | Close the selected buffer using vim's **`:bwipeout`** command.
**`S`**     | `g:BufSelectSort`         | Change the sort order, cycling between **Number**, **Name**, and **Path**.
**`cd`**    | `g:BufSelectChDir`        | Change the working directory to that of the selected buffer
**`..`**    | `g:BufSelectChDirUp`      | Change the working directory up one level from current
**`q`**     | `g:BufSelectExit`         | Exit the buffer list.
**`?`**     |                           | Display short descriptions of these commands.

### Sort Order
The default sort order can be set in the variable `g:BufSelectSortOrder`. The valid values are `"Num"`, `"Name"`, and `"Path"`, with `"Name"` being the default.
