#!/usr/bin/env bash
# Plays the autoplay runs of scripts/tools/autoplay_expected.json, JOBS at a time, each headless
# with --fixed-fps 10 and its own scratch data folder (APPDATA on Windows, XDG_DATA_HOME on
# Linux; both are set), so the real saves are never touched. Then checks each log against the
# JSON: its end line, level, defeats, play time (within play_time_margin %), and no ERROR or
# WARNING line other than known_warnings. A run past its timeout_min (wall clock) is killed with
# its whole process tree. Prints a table; exits 1 if a run failed, 2 on a usage error. It only
# runs the game (no tests) and never deletes anything: the logs stay in AUTOPLAY_DIR.
#
#   scripts/tools/autoplay_all.sh            # every run
#   scripts/tools/autoplay_all.sh v3 save    # only those
#
# GODOT: the Godot executable (./tools/godot.cmd on Windows, ./godot elsewhere). JOBS: runs at
# once (3). AUTOPLAY_DIR: where each run's folder goes (default a new folder under the temp
# folder; if given it must be missing or empty). EXPECTED: another expected file (to try a
# failure on a copy). jq reads the JSON when present; without it, sed reads it line by line.
set -u

cd "$(dirname "$0")/../.." || exit 2

case "$(uname -s)" in
	MINGW* | MSYS* | CYGWIN*) windows=1 ;;
	*) windows=0 ;;
esac
if [ "$windows" = 1 ]; then
	GODOT=${GODOT:-./tools/godot.cmd}
else
	GODOT=${GODOT:-./godot}
fi
JOBS=${JOBS:-3}
EXPECTED=${EXPECTED:-scripts/tools/autoplay_expected.json}
POLL_S=5
# The lines Godot prints for an error or a warning.
ERROR_LINE='^(SCRIPT |USER )?(ERROR|WARNING):'

fail_usage() {
	echo "autoplay_all: $1" >&2
	exit 2
}

# A path as Godot and a reader on Windows want it (C:/...); unchanged elsewhere.
os_path() {
	if [ "$windows" = 1 ]; then cygpath -m "$1"; else printf '%s\n' "$1"; fi
}

command -v "$GODOT" > /dev/null 2>&1 || [ -f "$GODOT" ] || fail_usage "no existe GODOT=$GODOT"
[ -f "$EXPECTED" ] || fail_usage "no existe EXPECTED=$EXPECTED"
case "$JOBS" in '' | *[!0-9]* | 0) fail_usage "JOBS debe ser un número mayor que 0" ;; esac

have_jq=0
command -v jq > /dev/null 2>&1 && have_jq=1

#region Reading the JSON

# Every run as one compact JSON object per line, in the file's order. Without jq the file's
# layout is the contract: one run object per line, starting with {"name".
run_objects() {
	if [ "$have_jq" = 1 ]; then
		jq -c '.runs[]' "$EXPECTED" | tr -d '\r'
	else
		tr -d '\r' < "$EXPECTED" | sed -n 's/^[[:space:]]*\({"name".*}\),\{0,1\}[[:space:]]*$/\1/p'
	fi
}

# A top-level number of the file.
top_number() {
	if [ "$have_jq" = 1 ]; then
		jq -r ".$1" "$EXPECTED" | tr -d '\r'
	else
		tr -d '\r' < "$EXPECTED" | sed -n "s/^[[:space:]]*\"$1\": *\([0-9][0-9]*\).*/\1/p"
	fi
}

# A top-level list of strings of the file, one per line.
top_strings() {
	if [ "$have_jq" = 1 ]; then
		jq -r ".$1[]" "$EXPECTED" | tr -d '\r'
	else
		tr -d '\r' < "$EXPECTED" \
			| sed -n "s/^[[:space:]]*\"$1\": *\[\(.*\)\],\{0,1\}[[:space:]]*$/\1/p" \
			| sed -e 's/^ *"//' -e 's/" *$//' -e 's/" *, *"/\n/g' | grep -v '^$'
	fi
}

# A string field of a run object (nothing when absent).
str_field() {
	printf '%s\n' "$1" | sed -n "s/.*\"$2\": *\"\([^\"]*\)\".*/\1/p"
}

# A number field of a run object (nothing when absent).
num_field() {
	printf '%s\n' "$1" | sed -n "s/.*\"$2\": *\([0-9][0-9]*\).*/\1/p"
}

#endregion

margin=$(top_number play_time_margin)
[ -n "$margin" ] || fail_usage "falta play_time_margin en $EXPECTED"
mapfile -t known < <(top_strings known_warnings)
names=()
objects=()
while IFS= read -r obj; do
	name=$(str_field "$obj" name)
	for key in args quit_after timeout_min; do
		[ -n "$(str_field "$obj" "$key")$(num_field "$obj" "$key")" ] \
			|| fail_usage "a la carrera ${name:-?} le falta $key"
	done
	names+=("$name")
	objects+=("$obj")
done < <(run_objects)
[ "${#names[@]}" -gt 0 ] || fail_usage "no hay carreras en $EXPECTED"

# The runs asked for (all when none), each once, in the order given.
queue=()
if [ "$#" -eq 0 ]; then
	queue=("${!names[@]}")
else
	for want in "$@"; do
		found=-1
		for i in "${!names[@]}"; do
			[ "${names[$i]}" = "$want" ] && found=$i
		done
		[ "$found" -ge 0 ] || fail_usage "carrera desconocida: $want (hay: ${names[*]})"
		case " ${queue[*]} " in *" $found "*) ;; *) queue+=("$found") ;; esac
	done
fi

if [ -n "${AUTOPLAY_DIR:-}" ]; then
	out=$AUTOPLAY_DIR
	if [ -d "$out" ] && [ -n "$(ls -A "$out")" ]; then
		fail_usage "AUTOPLAY_DIR no está vacía: $out"
	fi
	mkdir -p "$out" || fail_usage "no se puede crear $out"
else
	out=$(mktemp -d "${TMPDIR:-/tmp}/villaclaro-autoplay.XXXXXX") \
		|| fail_usage "no se puede crear la carpeta temporal"
fi

# Per run (by its index in names): pid of its subshell, start (epoch s), real seconds, exit
# code, hung (1/0), result, reasons, level, play time, defeats, log path.
pids=()
started=()
real=()
codes=()
hung=()
results=()
why=()
level=()
play=()
defeats=()
logs=()

# Seconds of a "h:mm:ss" clock, and back.
seconds() {
	local h m s
	IFS=: read -r h m s <<< "$1"
	echo $(( 10#$h * 3600 + 10#$m * 60 + 10#$s ))
}

clock() {
	printf '%d:%02d:%02d' $(( $1 / 3600 )) $(( $1 / 60 % 60 )) $(( $1 % 60 ))
}

# Starts run i in a background subshell, which writes Godot's exit code to exit_code (through
# a temporary file, so a half-written code is never read).
start_run() {
	local i=$1 name=${names[$1]} obj=${objects[$1]}
	local dir="$out/$name" args
	mkdir -p "$dir/appdata" "$dir/xdg"
	logs[$i]="$dir/$name.log"
	read -r -a args <<< "$(str_field "$obj" args)"
	(
		APPDATA=$(os_path "$dir/appdata") XDG_DATA_HOME=$(os_path "$dir/xdg") \
			"$GODOT" --headless --path . --fixed-fps 10 \
			--quit-after "$(num_field "$obj" quit_after)" -- "${args[@]}" \
			< /dev/null > "${logs[$i]}" 2>&1
		code=$?
		echo "$code" > "$dir/exit_code.tmp" && mv "$dir/exit_code.tmp" "$dir/exit_code"
	) &
	pids[$i]=$!
	started[$i]=$(date +%s)
	echo "Empieza $name: $(os_path "${logs[$i]}")"
}

# The children of a pid in the shell's process table (Git Bash's ps: PID PPID PGID WINPID ...,
# with a status letter before PID at times, which sed drops).
ps_children() {
	if [ "$windows" = 1 ]; then
		ps | sed 's/^[^0-9]*//' | awk -v p="$1" 'NR > 1 && $2 == p { print $1 }'
	else
		ps -o pid= --ppid "$1"
	fi
}

# Every pid under a pid, parents before their children.
descendants() {
	local child
	for child in $(ps_children "$1"); do
		echo "$child"
		descendants "$child"
	done
}

# Kills a run's subshell and everything under it. On Windows a forked shell is no Windows child
# of its parent, so taskkill /T from the subshell alone misses the run: each pid of the shell's
# tree is killed, and taskkill /T from its Windows pid takes the native tree under it (cmd.exe,
# the console wrapper, Godot).
kill_tree() {
	local pid=$1 p w all
	all=$(descendants "$pid")
	for p in $all "$pid"; do
		if [ "$windows" = 1 ]; then
			w=$(ps | sed 's/^[^0-9]*//' | awk -v p="$p" 'NR > 1 && $1 == p { print $4 }')
			[ -n "$w" ] && taskkill //F //T //PID "$w" > /dev/null 2>&1
		fi
		kill -KILL "$p" > /dev/null 2>&1
	done
	wait "$pid" 2> /dev/null
}

# The error lines that are not known warnings.
drop_known() {
	if [ "${#known[@]}" -eq 0 ]; then
		cat
		return
	fi
	local args=() k
	for k in "${known[@]}"; do
		args+=(-e "$k")
	done
	grep -vF "${args[@]}"
}

# Checks run i's log against its object; sets results, why, level, play and defeats of i.
check_run() {
	local i=$1 obj=${objects[$1]} log=${logs[$1]}
	local reasons=() save_version result also line bad joined
	level[$i]=""
	play[$i]=""
	defeats[$i]=""
	if [ "${hung[$i]}" = 1 ]; then
		reasons+=("colgada a los $(num_field "$obj" timeout_min) min")
	elif [ "${codes[$i]}" != 0 ]; then
		reasons+=("Godot salió con el código ${codes[$i]}")
	fi
	save_version=$(num_field "$obj" save_version)
	if [ -n "$save_version" ]; then
		local saved loaded
		saved=$(tr -d '\r' < "$log" | sed -n 's/^Guardado: //p' | head -n 1)
		loaded=$(tr -d '\r' < "$log" | sed -n 's/^Cargado: //p' | head -n 1)
		if [ -z "$saved" ]; then
			reasons+=("falta la línea «Guardado:»")
		elif [ -z "$loaded" ]; then
			reasons+=("falta la línea «Cargado:»")
		elif [ "$saved" != "$loaded" ]; then
			reasons+=("«Guardado:» y «Cargado:» no son iguales")
		elif ! printf '%s\n' "$saved" | grep -qE "\"version\": ?$save_version[,}]"; then
			reasons+=("la partida guardada no es de la versión $save_version")
		fi
	else
		result=$(str_field "$obj" result)
		also=$(str_field "$obj" also)
		if [ -n "$also" ] && ! tr -d '\r' < "$log" | grep -qF -- "$also"; then
			reasons+=("falta «$also»")
		fi
		line=$(tr -d '\r' < "$log" \
			| awk -v p="$result" 'index($0, p) == 1 { last = $0 } END { print last }')
		if [ -z "$line" ]; then
			reasons+=("no acabó: falta «${result% }»")
		else
			local lmin lmax dmax want expected low high
			level[$i]=$(printf '%s\n' "$line" | sed -n 's/.*Nv \([0-9][0-9]*\).*/\1/p')
			play[$i]=$(printf '%s\n' "$line" \
				| sed -n 's/.*tiempo de juego \([0-9][0-9]*:[0-9][0-9]:[0-9][0-9]\).*/\1/p')
			defeats[$i]=$(tr -d '\r' < "$log" | sed -n 's/^Derrotas: \([0-9][0-9]*\)$/\1/p' \
				| tail -n 1)
			lmin=$(num_field "$obj" level_min)
			lmax=$(num_field "$obj" level_max)
			want=$lmin
			[ "$lmin" = "$lmax" ] || want="$lmin-$lmax"
			if [ -z "${level[$i]}" ] || [ "${level[$i]}" -lt "$lmin" ] \
					|| [ "${level[$i]}" -gt "$lmax" ]; then
				reasons+=("nivel ${level[$i]:-?}, se esperaba $want")
			fi
			dmax=$(num_field "$obj" defeats_max)
			if [ -z "${defeats[$i]}" ] || [ "${defeats[$i]}" -gt "$dmax" ]; then
				reasons+=("${defeats[$i]:-?} derrotas, como mucho $dmax")
			fi
			expected=$(seconds "$(str_field "$obj" play_time)")
			low=$(( expected * (100 - margin) / 100 ))
			high=$(( expected * (100 + margin) / 100 ))
			if [ -z "${play[$i]}" ]; then
				reasons+=("sin tiempo de juego en «${result% }»")
			elif [ "$(seconds "${play[$i]}")" -lt "$low" ] \
					|| [ "$(seconds "${play[$i]}")" -gt "$high" ]; then
				reasons+=("tiempo de juego ${play[$i]}, se esperaba $(clock "$low")-$(clock "$high")")
			fi
		fi
	fi
	bad=$(tr -d '\r' < "$log" | grep -nE "$ERROR_LINE" | drop_known | head -n 1)
	if [ -n "$bad" ]; then
		reasons+=("${bad#*:} en la línea ${bad%%:*} del registro")
	fi
	level[$i]=${level[$i]:--}
	play[$i]=${play[$i]:--}
	defeats[$i]=${defeats[$i]:--}
	if [ "${#reasons[@]}" -eq 0 ]; then
		results[$i]=OK
		why[$i]=""
	else
		results[$i]=FALLO
		[ "${hung[$i]}" = 1 ] && results[$i]="FALLO (colgada)"
		printf -v joined '%s; ' "${reasons[@]}"
		why[$i]=${joined%; }
	fi
}

stop_all() {
	local p
	for p in "${pids[@]}"; do
		kill_tree "$p"
	done
	echo "Cortado. Los registros están en $(os_path "$out")" >&2
	exit 130
}
trap stop_all INT TERM

run_names=()
for i in "${queue[@]}"; do
	run_names+=("${names[$i]}")
done
echo "Carreras: ${run_names[*]} ($JOBS a la vez). Registros en $(os_path "$out")"

next=0
while [ "$next" -lt "${#queue[@]}" ] || [ "${#pids[@]}" -gt 0 ]; do
	while [ "${#pids[@]}" -lt "$JOBS" ] && [ "$next" -lt "${#queue[@]}" ]; do
		start_run "${queue[$next]}"
		next=$(( next + 1 ))
	done
	sleep "$POLL_S"
	now=$(date +%s)
	for i in "${!pids[@]}"; do
		dir="$out/${names[$i]}"
		if [ -f "$dir/exit_code" ]; then
			wait "${pids[$i]}" 2> /dev/null
			codes[$i]=$(tr -d '\r\n ' < "$dir/exit_code")
			hung[$i]=0
		elif [ $(( now - started[i] )) -ge $(( $(num_field "${objects[$i]}" timeout_min) * 60 )) ]; then
			kill_tree "${pids[$i]}"
			codes[$i]=-
			hung[$i]=1
		else
			continue
		fi
		real[$i]=$(( now - started[i] ))
		unset 'pids[i]'
		check_run "$i"
		echo "Termina ${names[$i]}: ${results[$i]} ($(clock "${real[$i]}"))"
	done
done

summary() {
	local row='%-8s %-16s %-6s %-9s %-9s %-9s %s\n' i
	printf "$row" Carrera Resultado Nivel "T. juego" Derrotas "T. real" Registro
	for i in "${queue[@]}"; do
		printf "$row" "${names[$i]}" "${results[$i]}" "${level[$i]}" "${play[$i]}" \
			"${defeats[$i]}" "$(clock "${real[$i]}")" "$(os_path "${logs[$i]}")"
	done
	for i in "${queue[@]}"; do
		if [ -n "${why[$i]}" ]; then
			echo "${names[$i]}: ${why[$i]}"
		fi
	done
}

echo
summary | tee "$out/resumen.txt"
for i in "${queue[@]}"; do
	[ "${results[$i]}" = OK ] || exit 1
done
exit 0
