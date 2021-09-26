#/usr/bin/env bash

_milxc_completions()
{
  if [ "${#COMP_WORDS[@]}" == "2" ]; then
      #COMPREPLY=($(compgen -W "$(./mi-lxc.py | grep usage | cut -d':' -f 2 | sed 's/[,.]/ /g' | sed 's/\[[a-z@]*\]//g' | sed 's/<[a-z]*>//g')" "${COMP_WORDS[1]}"))
      COMPREPLY=($(compgen -W "create renet destroy destroymaster updatemaster start stop attach display print" "${COMP_WORDS[1]}"))
      # ./mi-lxc.py | grep usage | cut -d' ' -f 6- | sed 's/, / /g' | sed 's/\[[a-z@]*\]//g' | sed 's/<[a-z]*>//g'
  fi

  if [ "${#COMP_WORDS[@]}" == "3" ]; then
      COMPREPLY=($(compgen -W "$(./mi-lxc.py | grep names | cut -d':' -f 2 | sed '{s/, / /g;s/\.$//g}')" "${COMP_WORDS[2]}"))
  fi


}

complete -F _milxc_completions ./mi-lxc.py
