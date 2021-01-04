#!/usr/bin/env bash

source ShellBot.sh

bot_token='SUA_TOKEN'

ShellBot.init --token "$bot_token" --return map

enviar() {

    mensagem=${mensagem//+/%2B}

    ShellBot.sendMessage --chat_id ${message_chat_id[$id]} --text "$1" $2

}

editar(){

    ShellBot.editMessageText --chat_id ${message_chat_id[$id]} --message_id ${return[message_id]} --text "$1"

}

guardaredicao(){

    edicao=${return[message_id]}

}

editaredicao(){

    ShellBot.editMessageText --chat_id ${message_chat_id[$id]} --message_id "$edicao" --text "$1"

}

while :

do

ShellBot.getUpdates --limit 100 --offset $(ShellBot.OffsetNext) --timeout 30

for id in $(ShellBot.ListUpdates) 

        do

            (

            [[ ${message_caption[$id]} ]] && {

                [[ ${message_audio_file_id[$id]} ]] && file_id=${message_audio_file_id[$id]} && {

                    file_id=($file_id)

                    enviar "baixando ..."

                    guardaredicao

                    file_id=$(echo $file_id | cut -d "|" -f1)

                    ShellBot.getFile --file_id $file_id

                    ShellBot.downloadFile --file_path ${return[file_path]} --dir "$(pwd)/sons"

                    file_id=''

                    legenda=${message_caption[$id]}

                    audio=${return[file_path]##*/}

                    caminho=${return[file_path]%/*}

                    mv "${return[file_path]}" "$caminho/${legenda// /_}.${audio##*.}"

                    echo "${return[file_path]}" "$caminho/${legenda// /_}.${audio##*.}"

                    editaredicao "adicionado com sucesso!, mande /list para ver ele"

                } || {

                enviar "envie o arquivo com a legenda 'nome de identificação'"

            }

            }                

            comando=${message_text[$id],,}

            [[ "${comando%@*}" = "/lista" || "${comando%@*}" = "/list" ]] && {

                for audios in $(ls sons);do

                    primeira+='[ "'

                    primeira+="🎵 ${audios}"

                    primeira+='" ],'

                done

                primeira=${primeira%,*}

                ShellBot.sendMessage --chat_id ${message_chat_id[$id]} --text "selecione o audio que deseja tocar, o teclado se manterá disponível sempre que precisar" --reply_markup "$(ShellBot.ReplyKeyboardMarkup --button 'primeira' --one_time_keyboard 'true')"

            } || {

                [[ "${message_text[$id]%@*}" = *"🎵"* ]] && {

                    enviar "tocando ..."

                    pkill mplayer

                    mplayer "sons/${message_text[$id]#* }"

                    enviar "reprodução finalizada."

                }

            }

            [[ "${comando%@*}" = *"/down"* ]] && {

                enviar "analisando ..."

                link=${comando#* }

                tratar=$(curl -s "https://soundcloudtomp3.app/download/?url=${link}" | egrep -o 'downloadFile(.)*\)')

                tratar=${tratar##*\(\'}

                tratar=${tratar%\',\'*}

                [[ $tratar ]] && {

                guardaredicao

                editaredicao "baixando ..."

                curl -s "${tratar}" -o "sons/${link##*/}.mp3"

                guardaredicao

                editaredicao "arquivo adicionado para reprodução!"

            }

            }

            [[ "${comando%@*}" = "/parar" || "${comando%@*}" = "/stop" ]] && {

                pkill mplayer

                enviar "musica parada"

            }

            [[ "${comando%@*}" = "/limpar" || "${comando%@*}" = "/clear" ]] && {

                rm -rf sons

                mkdir sons

                enviar "audios da campanha limpos com sucesso"

            }

            )&

        done

done
