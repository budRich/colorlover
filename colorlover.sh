#!/usr/bin/env bash

__name="colorlover"
__version="0.006"
__author="budRich"
__contact='robstenklippa@gmail.com'
__created="2018-08-25"
__updated="2018-08-26"

# files from environment variables:
: "${COLOR_LOVER_DIR:=$HOME/.config/colorlover}"
: "${COLOR_LOVER_TMP_FILE:=/tmp/cl$(date +'%y-%m-%d').xml}"

# default foreground/background colors:
__fgc='#222222'
__bgc='#EEEEEE'

main(){

  local url

  eval set -- "$(getopt --name "$__name" \
    --options vh::f:b:lcr \
    --longoptions random,current,list,foreground:,background:,version,help:: \
    -- "$@"
  )"

  while true; do
    case "$1" in
      -v | --version ) printinfo version ; exit ;;
      -h | --help ) printinfo "${2:-}" ; exit ;;

      -c | --current )
        [[ -f "${COLOR_LOVER_DIR}/.current" ]] \
          && readlink -f "${COLOR_LOVER_DIR}/.current"
        exit
      ;;

      -l | --list ) 
        [[ -d "${COLOR_LOVER_DIR}" ]] \
          && ls "${COLOR_LOVER_DIR}"
          exit 
      ;;

      -r | --random ) 
        nran=$(printf '%06d' $(( (RANDOM * 27) + 10000 )))
        shift
      ;;

      -f | --foreground ) __fgc="${2:-}" ; shift 2 ;;
      -b | --background ) __bgc="${2:-}" ; shift 2 ;;

      -- ) shift; break ;;
      * ) break ;;
    esac
  done

  __lastarg=""
  eval __lastarg="\${$#}"

  [[ -n ${nran:-} ]] && __lastarg="$nran"
  # if background color is defined, start will be 0
  __start=1

  declare -A __scheme

  if [[ $__lastarg = "$0" ]]; then
    setrandom
  elif [[ $__lastarg =~ .*colourlovers.com ]]; then
    setfromurl "$__lastarg"
    setterm
    writetheme
  elif ((${#__lastarg}==6)) && [[ $__lastarg =~ ^[0-9]*$ ]]; then
    url="http://www.colourlovers.com/palette/$__lastarg"
    setfromurl "$url"
    setterm
    writetheme
  elif [[ -f "$COLOR_LOVER_DIR/$__lastarg" ]]; then
    __schemefile="$COLOR_LOVER_DIR/$__lastarg"
    source "$__schemefile"
    setterm
  else
    ERX "Unkown command $__lastarg"
  fi
}

setrandom(){
  local url

  # download top palettes if needed:
  [[ -f $COLOR_LOVER_TMP_FILE ]] || {
    url="http://www.colourlovers.com/api/palettes/top"
    curl -s "$url" > "$COLOR_LOVER_TMP_FILE" \
      || ERX "curl failed"
  }

  eval "$(awk '
    BEGIN{npal=0}
    /<title>/ {
      sub(/.*A[[]/,"")
      sub(/[]]+.*/,"")
      pals[++npal]["title"]=$0
      colors=0
    }
    /<userName>/ {
      sub(/.*A[[]/,"")
      sub(/[]]+.*/,"")
      pals[npal]["author"]=$0
    }
    /<hex>/ {
      sub(/<hex>/,"")
      sub(/<.*/,"")
      sub(/^[[:space:]]*/,"")
      pals[npal]["colors"][colors++]=$0
    }

    END {
      srand()
      numba=1 + int(rand() * npal)
      print "__scheme[title]=\"" pals[numba]["title"] "\""
      print "__scheme[author]=\"" pals[numba]["author"] "\""
      i=1
      while (i < 16) {
        for (c in pals[numba]["colors"]) {
          if (i ~ "7|8|15") i++
          if (i > 15) break
          print "__scheme[color" i++ "]=\"#" pals[numba]["colors"][c] "\""
        }

      }
    }
  ' "$COLOR_LOVER_TMP_FILE")"
  

  if [[ -f $__schemefile ]]; then
    source "$__schemefile"
    setterm
  else
    setterm
    writetheme
  fi

  ln -sf "$__schemefile" "${__schemefile%/*}/.current" &
}

setterm(){
  local start os

  # os="$(uname)"

  __schemefile="$COLOR_LOVER_DIR/${__scheme[title]:-cl$(date +'%y-%m-%d')}"
  # [[ -n ${__fgc:-} ]] && [[ $os != Darwin ]] && {
  [[ -n ${__fgc:-} ]] && {
    __scheme[colorFG]="$__fgc"
    __scheme[color7]="$__fgc"
    __scheme[color15]="$__fgc"

    >&2 echo -ne "\033]10;$__fgc\007"
  }

  __start=1

  # [[ -n ${__bgc:-} ]] && [[ $os != Darwin ]] && {
  [[ -n ${__bgc:-} ]] && {
    __scheme[colorBG]="$__bgc"
    __scheme[color0]="$__bgc"
    __scheme[color8]="$__bgc"
    __start=0
    >&2 echo -ne "\033]11;$__bgc\007"
  }

  for (( i = __start; i < 16; i++ )); do
    ((i==7)) && [[ -z $__fgc ]] && ((i++))
    # if [[ $os = Darwin ]]; then
    #   >&2 printf "\033]P%1x%s\033\\" "$i" "${__scheme[color$i]:1}"
    # else
      >&2 printf "\033]4;%s;%s\033\\" "$i" "${__scheme[color$i]}"
    # fi
  done

  echo "$__schemefile"
}

writetheme(){
  mkdir -p "$COLOR_LOVER_DIR"
{
  echo "__scheme[title]='${__scheme[title]}'"
  echo "__scheme[author]='${__scheme[author]}'"
  echo
  [[ -n $__bgc ]] && echo "__scheme[colorBG]='${__scheme[colorBG]}'"
  [[ -n $__fgc ]] && echo "__scheme[colorFG]='${__scheme[colorFG]}'"
  echo
  for (( i = __start; i < 16; i++ )); do
    ((i==7)) && [[ -z $__fgc ]] && ((i++))
    echo "__scheme[color$i]='${__scheme[color$i]}'"
  done
} > "$__schemefile"
}

setfromurl(){
  url="${1}"

  eval "$(curl -s "$url" | awk '
    /<meta name="description"/ {
      sub(/.*content="/,"")
      sub(/[.] I-MOO.*/,"")
      author=$0
      sub(" color.*","")
      print "__scheme[title]=\"" $0 "\""
      sub(".*palette by ","",author)
      print "__scheme[author]=\"" author "\""
      print ""
    }
    start==1 && /\/\/<![[]CDATA[[]/ {exit}
    start==1 && /<h5>Hex/ {
      sub(/<h4>/,"")
      sub(/<.*/,"")
      pals[colors++]=$0
    }
    /<h2>Colors<\/h2>/ {start=1;color=0}

    END {
      i=1
      while (i < 16) {
        for (c in pals) {
          if (i ~ "7|8|15") i++
          if (i > 15) break
          print "__scheme[color" i++ "]=\"#" pals[c] "\""
        }

      }
    }
  ')"
}

printinfo(){
about='`colorlover` - Get palettes from colourlovers.com

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
file doesn'"'"'t exist. A random PALETTE from the
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
if the file doesn'"'"'t exist.  

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
'

bouthead="
${__name^^} 1 ${__created} Linux \"User Manuals\"
=======================================

NAME
----
"

boutfoot="
AUTHOR
------

${__author} <${__contact}>
<https://budrich.github.io>

SEE ALSO
--------

bar(1), foo(5), xyzzy(1), [Linux Man Page Howto](
http://www.schweikhardt.net/man_page_howto.html)
"


  case "$1" in
    # print version info to stdout
    version )
      printf '%s\n' \
        "$__name - version: $__version" \
        "updated: $__updated by $__author"
      exit
      ;;
    # print help in markdown format to stdout
    md ) printf '%s' "# ${about}" ;;

    # print help in markdown format to README.md
    mdg ) printf '%s' "# ${about}" > "${__dir}/README.md" ;;
    
    # print help in troff format to __dir/__name.1
    man ) 
      printf '%s' "${bouthead}" "${about}" "${boutfoot}" \
      | go-md2man > "${__dir}/${__name}.1"
    ;;

    # print help to stdout
    * ) 
      printf '%s' "${about}" | awk '
         BEGIN{ind=0}
         $0~/^```/{
           if(ind!="1"){ind="1"}
           else{ind="0"}
           print ""
         }
         $0!~/^```/{
           gsub("[`*]","",$0)
           if(ind=="1"){$0="   " $0}
           print $0
         }
       '
    ;;
  esac
}

ERR(){ >&2 echo "[WARNING]" "$*"; }
ERX(){ >&2 echo "[ERROR]" "$*" && exit 1 ; }

init(){
  set -o errexit
  set -o pipefail
  set -o nounset
  # set -o xtrace

  __source="$(readlink -f "${BASH_SOURCE[0]}")"
  __dir="$(cd "$(dirname "${__source}")" && pwd)"
  __file="${__dir}/$(basename "${__source}")"
  __base="$(basename ${__file} .sh)"
  __root="$(cd "$(dirname "${__dir}")" && pwd)" # <-- change this as it depends on your app
}

init

main "${@}"
