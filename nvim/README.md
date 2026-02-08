## Notes

#### Required packages:
 
- https://www.nerdfonts.com/ (any)

#### Troubleshooting

If you encounter the error `module 'nvim-treesitter.configs' not found`, it means the treesitter plugin hasn't been installed yet. Run these commands to fix it:

```bash
# Install the treesitter plugin and parsers
nvim --headless "+TSInstall all" +qa

# Or install specific parsers
nvim --headless "+TSInstall lua vim bash javascript python json" +qa

# Then restart Neovim
```

If the issue persists, try:
```bash
# Update all plugins
nvim --headless "+Lazy! sync" +qa

# Then install treesitter parsers
nvim --headless "+TSInstall all" +qa
```

#### Key bindings

### Navigation
^w  - cycle through windows
^u  - half screen up
^d  - hald screen down
^f  - one screen forward
^b  - one screen back
gg  - go to beginning of the document
G   - go to end of the document
0   - beginning of line
^   - beginning of the text
$   - end of text  

### Text operations
d   - delete selection (in Visual)
dd  - cut line
2dd - cut 2 lines
yy  - copy line
p   - paste line

### Modes
Shift+V - visual mode
d   - deletion mode

### Undo/Redo
:u  - undo
^r  - redo

### Search
:%s/search/replace/gcC - search & replace text globally with confirmation Case-insensitive
:/term - Search forward for 'term'
:?term - Search backward for 'term'
:n - Repeat the search in the same direction
:N - Repeat the search in the opposite direction
:/\<term\> - Search for 'term' as a whole word
:/term\c - Search case-insensitively
:/term\C - Search case-sensitively
:set hlsearch - Highlight all matches
:set nohlsearch - Turn off highlighting
:noh - Clear search highlights

### Telescope

\fg - fulltext search
\ff - search for filename

#### Practice part

one
two
three
four
five
six
