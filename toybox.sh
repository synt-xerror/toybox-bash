RED='\033[0;31m'
ORANGE='\033[38;5;214m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
LBLUE='\033[94m'
NC='\033[0m'

player_ok() {
    "$@" >/dev/null 2>&1
    return $?  # se rodou com sucesso -> ok
}

playaudio() {
    local file="$1"
    [[ -f "$file" ]] || return 1

    local player_cmds=("aplay" "paplay" "play" "ffplay")
    local cmd

    for cmd in "${player_cmds[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            if [[ "$cmd" == "ffplay" ]]; then
                ffplay -nodisp -autoexit -loglevel quiet "$file" &
                return 0
            else
                # testa se funciona
                "$cmd" "$file" >/dev/null 2>&1 &
                local pid=$!
                sleep 0.2
                if kill -0 "$pid" 2>/dev/null; then
                    return 0  # já está tocando, não inicia outro
                fi
            fi
        fi
    done

    return 2
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
    if command -v apt &> /dev/null; then
        BASE="debian"
    elif command -v dnf &> /dev/null; then
        BASE="fedora"
    elif command -v pacman &> /dev/null; then
        BASE="arch"
    elif command -v zypper &> /dev/null; then
        BASE="opensuse"
    elif command -v apk &> /dev/null; then
        BASE="alpine"
    else
        BASE=""
    fi

    # Leitura do /etc/os-release
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_ID="${ID}"
        OS_LIKE="${ID_LIKE}"
    fi
    OS_LIKE_MAIN=$(echo "$OS_LIKE" | awk '{print $1}')

    if [[ -z "$OS_LIKE_MAIN" && -n "$OS_ID" ]]; then
        OS_LIKE_MAIN="$OS_ID"
    fi

    LIKE_BASE=""
    case "$OS_LIKE_MAIN" in
        debian|ubuntu) LIKE_BASE="debian" ;;
        rhel|fedora)   LIKE_BASE="fedora" ;;
        arch)          LIKE_BASE="arch" ;;
        suse|opensuse) LIKE_BASE="opensuse" ;;
        alpine)        LIKE_BASE="alpine" ;;
    esac

    if [[ -z "$BASE" && -z "$LIKE_BASE" ]]; then
        echo "Erro: não foi possível determinar a base."
        return 1
    fi

    if [[ -n "$BASE" && -n "$LIKE_BASE" && "$BASE" != "$LIKE_BASE" ]]; then
        BASE="$LIKE_BASE"
    fi

    if [[ -z "$BASE" && -n "$LIKE_BASE" ]]; then
        BASE="$LIKE_BASE"
    fi
}

# echo -e "toybox.sh - detect_base: ${RED}NotFound${NC}: Could not detect distribution base."

detect_distro() {
    for f in /etc/os-release /usr/lib/os-release /etc/lsb-release; do
        if [ -r "$f" ]; then
            . "$f"
            DISTRO="${NAME:-$DISTRIB_ID}"
            return 0
        fi
    done

    echo "toybox.sh - detect_distro: NotFound: Could not detect distribution name."
    return 127
}

run() {
    "$@" &
    (( $(jobs -r | wc -l) >= 3 )) && wait -n
}