# `colorlover` - Get palettes from colourlovers.com

SYNOPSIS
--------
`colorlover` [`-f`|`--foreground` FG_COLOR] [`-b`|`--background` BG_COLOR] [ID|URL|PALETTE]  
`colorlover` `-r`|`--random` [`-f`|`--foreground` FG_COLOR] [`-b`|`--background` BG_COLOR]  
`colorlover` `-c`|`--current`  
`colorlover` `-l`|`--list`  
`colorlover` `-v`|`--version`  
`colorlover` `-h`|`--help`  

DESCRIPTION
-----------

If `colorlover` is executed without arguments
(except options) the  current top palettes will
get  downloaded to *COLOR_LOVER_TMP_FILE*, if the
file doesn't exist. A random PALETTE from the
downloaded file will be generated, set and saved
to *COLOR_LOVER_DIR/PALETTE*.  

if the last argument is a URL to a  palette or a 6
digit ID number, that palette will get downloaded.  

if the last argument is the name of a PALETTE
already in *COLOR_LOVER_DIR*, that PALLETTE will
get applied.


OPTIONS
-------
`-f`|`--foreground` FG_COLOR  
Sets the foreground color to FG_COLOR.  
FG_COLOR will also get applied to color7 and color15.
FG_COLOR is a 6 character long hexadecimal colorcode.  

`-b`|`--background` BG_COLOR  
Sets the background color to BG_COLOR.  
BG_COLOR will also get applied to color0 and color8.
BG_COLOR is a 6 character long hexadecimal colorcode.  

`-r`|`--random`  
If set a 6 digit ID number will get generated and
the palette with that ID will get downloaded, set
and saved.  

`-c`|`--current`  
Prints the path to the last set theme to `stdout`  

`-l`|`--list`  
Prints a list of the content of *COLOR_LOVER_DIR*  

`-v`|`--version`  
Print version and exit.  

`-h`|`--help`  
Print help (this) and exit.  


FILES
-----

Themes will get saved to *COLOR_LOVER_DIR/THEME*, 
and when a theme is set, a symbolic link to that theme
will get created to: *COLOR_LOVER_DIR/.current*  

Top palettes will get downloaded to *COLOR_LOVER_TMP_FILE* 
if the file doesn't exist.  

ENVIRONMENT
-----------

COLOR_LOVER_DIR  
Directory where themes get saved to.  
Default: *$HOME/.config/colorlover*  

COLOR_LOVER_TMP_FILE  
Temporary file where the top palettes get downloaded to.  
Defaul: /tmp/cl`YY-MM-DD`.xml  


DEPENDENCIES
------------

bash>4  
gawk  
getopt  
