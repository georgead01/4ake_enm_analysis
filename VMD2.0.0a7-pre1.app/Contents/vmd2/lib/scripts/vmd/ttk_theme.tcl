# Diego Gomes <dgomes@auburn.edu>
# The VMD2 theme 
ttk::setTheme "clam"

array set colors {
	fg             "#313131"
	bg             "#ffffff"
	disabledfg     "#595959"
	disabledbg     "#ff0066"
	selectfg       "#313131"
	selectbg       "#e6e6e6"
}
#	disabledbg     "#ffffff"


# Settings
ttk::style configure . \
		-background $colors(bg) \
		-foreground $colors(fg) \
		-troughcolor $colors(bg) \
		-focuscolor $colors(selectbg) \
		-selectbackground $colors(selectbg) \
		-selectforeground $colors(selectfg) \
		-insertwidth 1 \
		-insertcolor $colors(fg) \
		-fieldbackground $colors(selectbg) \
		-font {TkDefaultFont 10} \
		-borderwidth 1 \
		-relief flat



ttk::style map . -foreground [list disabled $colors(disabledfg)]

tk_setPalette background [ttk::style lookup . -background] \
	foreground [ttk::style lookup . -foreground] \
	highlightColor [ttk::style lookup . -focuscolor] \
	selectBackground [ttk::style lookup . -selectbackground] \
	selectForeground [ttk::style lookup . -selectforeground] \
	activeBackground [ttk::style lookup . -selectbackground] \
	activeForeground [ttk::style lookup . -selectforeground]

option add *font [ttk::style lookup . -font]

# Configure the style for all tabs
ttk::style configure TNotebook.Tab \
	-background #ffffff -foreground #000000

# Change the style for selected and unselected tabs
ttk::style map TNotebook.Tab \
    -background [list selected #2D5FF5 active #2D5FF5] \
    -foreground [list selected #ffffff active #ffffff]

# Configure the style for all dropdown menus (comboboxes)
ttk::style configure TCombobox \
    -background #f0f0f0 \
    -foreground #333333 \
    -fieldbackground #ffffff \
    -arrowcolor #2D5FF5 \
    -padding {5 3}

# Change the dropdown list items' colors
ttk::style map TCombobox \
    -background [list focus #e0e0e0] \
    -foreground [list focus #333333] \
    -fieldbackground [list focus #ffffff]

# Configure the style for the table
ttk::style configure Treeview \
    -background #f9f9f9 \
    -foreground #333333 \
    -fieldbackground #ffffff \
    -font {Helvetica 14} \
    -rowheight 25 \
    -padding {5 5}

# Customize the header style
ttk::style configure Treeview.Heading \
    -background #4CAF50 \
    -foreground #ffffff \
    -font {Helvetica 14 bold} \
    -relief flat

# Set style for selected rows
ttk::style map Treeview \
    -background [list selected #ffffff] \
    -foreground [list selected #2D5FF5]
    


