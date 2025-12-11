RED='\033[0;31m'
ORANGE='\033[38;5;214m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
LBLUE='\033[94m'
NC='\033[0m'

cmd_ok() {
    "$@" >/dev/null 2>&1 &
    local pid=$!

    # espera 0.2s para saber se o processo morreu (erro) ou continua (ok)
    sleep 0.2

    if ! kill -0 "$pid" 2>/dev/null; then
        return 1  # morreu -> falhou
    fi

    kill "$pid" 2>/dev/null
    return 0  # funciona
}

playaudio() {
    local file="$1"

    [[ -f "$file" ]] || return 1

    # aplay
    if command -v aplay >/dev/null 2>&1; then
        if cmd_ok aplay "$file"; then
            nohup aplay "$file" >/dev/null 2>&1 &
            return 0
        fi
    fi

    # paplay
    if command -v paplay >/dev/null 2>&1; then
        if cmd_ok paplay "$file"; then
            nohup paplay "$file" >/dev/null 2>&1 &
            return 0
        fi
    fi

    # play (SoX)
    if command -v play >/dev/null 2>&1; then
        if cmd_ok play "$file"; then
            nohup play "$file" >/dev/null 2>&1 &
            return 0
        fi
    fi

    # ffplay
    if command -v ffplay >/dev/null 2>&1; then
        if cmd_ok ffplay -nodisp -autoexit -loglevel quiet "$file"; then
            ffplay -nodisp -autoexit -loglevel quiet "$file"
            return 0
        fi
    fi

    return 2  # nenhum player funcional
}


anime() {
    frames=("$@")
    time=${frames[-1]}

    for frame in "${frames[@]:0:${#frames[@]}-1}"; do 
        if [[ $frame != $time  ]]; then
            printf "$frame"
            sleep $time
            clear
        fi
    done
}
s=0

menu() {
    local titles=()
    local footer=""
    local options=()

    # parser de parâmetros
    while (( $# > 0 )); do
        case "$1" in
            @title)
                titles+=( "$2" )
                shift 2
                ;;
            @footer)
                footer="$2"
                shift 2
                ;;
            @circular)
                circular=1
                shift
                ;;
            *)
                options+=( "$1" )
                shift
                ;;
        esac
    done

    while true; do
        clear

        # comportamento circular
        if [[ $circular ]]; then
            (( s < 0 )) && s=$((${#options[@]} - 1))
            (( s >= ${#options[@]} )) && s=0
        else
            (( s < 0 )) && s=0
            (( s >= ${#options[@]} )) && s=$((${#options[@]} - 1))
        fi

        # imprimir todos os títulos
        for t in "${titles[@]}"; do
            echo -e "$t"
        done
        [[ ${#titles[@]} -gt 0 ]] && echo

        # imprimir opções
        for i in "${!options[@]}"; do
            if [[ $s == $i ]]; then
                echo -e "\e[30;47m> ${options[i]}\e[0m"
            else
                echo -e "  ${options[i]}"
            fi
        done

        [[ -n "$footer" ]] && echo -e "\n$footer"

        # leitura de teclas
        read -rsn1 key
        if [[ -z $key ]]; then
            key=$'\n'
        elif [[ $key == $'\e' ]]; then
            read -rsn2 -t 0.01 rest
            key+="$rest"
        fi

        case $key in
            $'\e[A') s=$((s-1)) ;;
            $'\e[B') s=$((s+1)) ;;
            $'\e') clear; exit 0;;
            $'\n'|$'\r') selected="$s"; break ;;
        esac
    done
}

lecho() {
    if [[ -z "$lang" ]]; then
        echo -e "toybox.sh - lecho: ${RED}TypeError:${NC} Cannot read properties of null (reading 'lang')"
        exit 1
    fi

    local prompt
    [[ "$lang" == "0" ]] && prompt="$1"
    [[ "$lang" == "1" ]] && prompt="$2"

    echo "$prompt"
}

lechoe() {
    if [[ -z "$lang" ]]; then
        echo -e "toybox.sh - lechoe: ${RED}TypeError:${NC} Cannot read properties of null (reading 'lang')"
        exit 1
    fi

    local prompt
    [[ "$lang" == "0" ]] && prompt="$1"
    [[ "$lang" == "1" ]] && prompt="$2"

    echo -e "$prompt"
}

lprintf() {
    if [[ -z "$lang" ]]; then
        echo -e "toybox.sh - lprintf: ${RED}TypeError:${NC} Cannot read properties of null (reading 'lang')"
        exit 1
    fi

    local prompt
    [[ "$lang" == "0" ]] && prompt="$1"
    [[ "$lang" == "1" ]] && prompt="$2"

    printf "$prompt"
}

lreadp() {
    if [[ -z "$lang" ]]; then
        echo -e "toybox.sh - lreadp: ${RED}TypeError:${NC} Cannot read properties of null (reading 'lang')"
        exit 1
    fi

    local prompt
    [[ "$lang" == "0" ]] && prompt="$1"
    [[ "$lang" == "1" ]] && prompt="$2"

    if [[ -n $3 ]]; then
        declare -g "$3"
        read -r -p "$prompt" "$3"
    else
        read -r -p "$prompt"
    fi
}

lmenu() {
    if [[ -z "$lang" ]]; then
        echo "toybox.sh - lreadp: ${RED}TypeError${NC}: missing 'lang'."
        return 1
    fi

    local args=( "$@" )
    local titles=()
    local options=()
    local footer=""

    local i=0
    while (( i < ${#args[@]} )); do
        local key="${args[i]}"
        local pt="${args[i+1]:-}"
        local en="${args[i+2]:-}"

        # ---------------------------------------------------------------------
        # @title (multiplos)
        # ---------------------------------------------------------------------
        [[ "$key" == "@title" ]] && {
            # normalização para ":" e campos ausentes
            [[ "$pt" == ":" ]] && pt="$en"
            [[ "$en" == ":" ]] && en="$pt"
            [[ -z "$en" ]] && en="$pt"
            [[ -z "$pt" ]] && pt="$en"

            [[ "$lang" == "1" ]] && titles+=( "$en" ) || titles+=( "$pt" )

            ((i+=3))
            continue
        }        

        # ---------------------------------------------------------------------
        # @footer (único)
        # ---------------------------------------------------------------------
        [[ "$key" == "@footer" ]] && {
            [[ "$pt" == ":" ]] && pt="$en"
            [[ "$en" == ":" ]] && en="$pt"
            [[ -z "$en" ]] && en="$pt"
            [[ -z "$pt" ]] && pt="$en"

            [[ "$lang" == "1" ]] && footer="$en" || footer="$pt"

            ((i+=3))
            continue
        }

        # ---------------------------------------------------------------------
        # Opções normais (PT EN)
        # ---------------------------------------------------------------------
        local o_pt="$key"
        local o_en="$pt"

        [[ "$o_pt" == ":" ]] && o_pt="$o_en"
        [[ "$o_en" == ":" ]] && o_en="$o_pt"
        [[ -z "$o_pt" ]] && o_pt="$o_en"
        [[ -z "$o_en" ]] && o_en="$o_pt"
            
        [[ "$lang" == "1" ]] && options+=( "$o_en" ) || options+=( "$o_pt" )

        ((i+=2))
    done

    # Montar lista final para menu()
    local final=()

    for t in "${titles[@]}"; do
        final+=( "@title" "$t" )
    done

    final+=( "${options[@]}" )

    [[ -n "$footer" ]] && final+=( "@footer" "$footer" )

    menu "${final[@]}"
}

loading() {
    [[ ! $1 ]] && echo -e "toybox.sh - loading: ${RED}SyntaxError${NC}: missing 'type' argument." && exit 1
    [[ ! $2 ]] && echo -e "toybox.sh - loading: ${RED}SyntaxError${NC}: missing 'interval' argument." && exit 1
    [[ ! $3 ]] && echo -e "toybox.sh - loading: ${RED}SyntaxError${NC}: missing 'times' argument." && exit 1

    local type="$1"
    local interval="$2"
    local times="$3"
    local color="${4:-0}" # cor padrão 0 se não passada
    local spinner=("|" "/" "-" "\\") # frames do spinner

    if [[ "$type" == "spin" ]]; then
        for ((i=0; i<times; i++)); do
            for frame in "${spinner[@]}"; do
                clear
                echo -e "\033[;${color};0m $frame \033[0m"
                sleep "$interval"
            done
        done
    else
        echo -e "toybox.sh - loading: ${RED}ValueError${NC}: unknown type '$type'."
        exit 127
    fi
}

set_status() {
    local key="$1"
    local value="$2"

    if grep -q "^$key=" status; then
        sed -i "s|^$key=.*|$key=$value|" status
    else
        echo "$key=$value" >> status
    fi
}

detect_base() {
    # Detecta pela pkgbase (se nada mais funcionar)
    if command -v apt &> /dev/null; then
        PKG="debian"
    elif command -v dnf &> /dev/null; then
        PKG="fedora"
    elif command -v pacman &> /dev/null; then
        PKG="arch"
    elif command -v zypper &> /dev/null; then
        PKG="suse"
    elif command -v apk &> /dev/null; then
        PKG="alpine"
    else
        PKG="none"
    fi

    # 1) Prioriza os-release
    if [ -f /etc/os-release ]; then
        . /etc/os-release

        if [ -n "$ID_LIKE" ]; then
            read -r -a like_arr <<< "$ID_LIKE"
            BASE="${like_arr[0]}"
            return
        fi

        if [ -n "$ID" ]; then
            BASE="$ID"
            return
        fi
    fi

    # 2) Fallback para outros arquivos
    for file in /etc/*release /etc/*_version /etc/*-release; do
        [ -f "$file" ] || continue
        . "$file"

        if [ -n "$ID_LIKE" ]; then
            read -r -a like_arr <<< "$ID_LIKE"
            BASE="${like_arr[0]}"
            return
        elif [ -n "$ID" ]; then
            BASE="$ID"
            return
        elif [ -n "$DISTRIB_ID" ]; then
            BASE="$DISTRIB_ID"
            return
        else
            BASE="$(head -n1 "$file")"
            return
        fi
    done

    # 3) Ajustes baseados no PKG
    if [[ "$ID" == "ubuntu" && "$PKG" == "debian" ]]; then
        BASE="debian"
        return
    fi

    if [[ "$ID" != "$PKG" ]]; then
        BASE="unknown"
        return
    fi

    if [[ "$ID" == "$PKG" ]]; then
        BASE="$ID"
        return
    fi

    return 127
}
# Result:
#detect_base
#echo $BASE
#> arch

detect_distro() {
    # 1) Prioriza os-release
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO="${NAME:-$PRETTY_NAME}"
        return
    fi

    # 2) Fallback para arquivos específicos
    shopt -s nullglob
    for file in /etc/*release /etc/*_version /etc/*-release; do
        [ -e "$file" ] || continue

        . "$file"

        if [ -n "${NAME:-}" ]; then
            DISTRO="$NAME"
            shopt -u nullglob
            return

        elif [ -n "${DISTRIB_ID:-}" ]; then
            DISTRO="$DISTRIB_ID"
            shopt -u nullglob
            return

        else
            DISTRO="$(head -n1 "$file")"
            shopt -u nullglob
            return
        fi
    done
    shopt -u nullglob

    return 127

}
# Result
# detect_distro
# echo "$NAME"
# > Arch Linux

detect_windows() {
    # 1) Git Bash / MSYS2 / MinGW
    case "$(uname -s)" in
        MINGW*|MSYS*)
            windows_env="Git Bash / MSYS2"
            return 0
            ;;
    esac

    # 2) Windows environment variable (Git Bash, MSYS, Cygwin)
    if [ "$is_windows" = false ] && [ "$OS" = "Windows_NT" ]; then
        windows_env="Windows_NT (Git Bash/Cygwin/MSYS)"
        return 0
    fi

    # 3) WSL
    if [ "$is_windows" = false ] && grep -qi microsoft /proc/version 2>/dev/null; then
        windows_env="Windows Subsystem for Linux"
        return 0
    fi

    # 4) cmd.exe (fallback)
    if [ "$is_windows" = false ] && command -v cmd.exe >/dev/null 2>&1; then
        windows_env="Windows (via cmd.exe)"
        return 0
    fi

    return 1

    # Result
    # if detect_windows; then
    #     echo "Windows detected ($windows_env)"
    # else
    #     echo "Isn't windows."
    # fi
}

detect_android() {
    # 1) build.prop
    if grep -qi android /system/build.prop 2>/dev/null; then
        android_env="build.prop"
        return 0
    fi

    # 2) getprop
    if command -v getprop >/dev/null 2>&1; then
        if [ -n "$(getprop ro.build.version.release 2>/dev/null)" ]; then
            android_env="getprop"
            return 0
        fi
    fi

    # 3) common directories
    if [ -d /sdcard ] && [ -d /system ]; then
        android_env="paths típicos"
        return 0
    fi

    # 4) Termux
    if [[ "$PREFIX" == /data/data/*com.termux* ]]; then
        android_env="Termux"
        return 0
    fi

    # 5) kernel
    if uname -a | grep -qi android; then
        android_env="kernel string"
        return 0
    fi

    return 1

    # Result
    # if detect_android; then
    #     echo "Android detected ($android_env)"
    # else
    #     echo "Isn't Android"
    # fi
}