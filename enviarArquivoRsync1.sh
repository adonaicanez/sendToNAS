#!/bin/bash

export VELOCIDADE_UPLOAD
export DIR_INSTALL=/var/backupNAS
export DIRETORIO_LOGS_ENV=${DIR_INSTALL}/logsEnvio
export ARQUIVO_LOG_ENV=${DIRETORIO_LOGS_ENV}/logEnvioNAS

cd ${DIR_INSTALL}

RAND=$RANDOM
cp ${DIR_INSTALL}/NAS.txt ${DIR_INSTALL}/NAS_${RAND}.txt
ARQUIVO_CADASTRO_NAS=${DIR_INSTALL}/NAS_${RAND}.txt

${DIR_INSTALL}/finalizaEnviosAtivos.sh

find enviarNAS/ -type f -exec md5sum {} \; > ${DIR_INSTALL}/hashArquivos.txt
HASHARQUIVOSENVIO=`md5sum -b ${DIR_INSTALL}/hashArquivos.txt | awk '{print $1}'`
rm -f ${DIR_INSTALL}/hashArquivos.txt

if [ -z $1 ]
then
        VELOCIDADE_UPLOAD=0
else
        VELOCIDADE_UPLOAD=$1
fi

while read linha
do
        ZONA=$(echo ${linha} | awk -F "," '{print $1}' | cut -d a -f 2)
        IP_NAS=$(echo ${linha} | awk -F "," '{print $2}')
    DATA_ATIVO=$(echo ${linha} | awk -F "," '{print $3}')
    ULTIMO_ENVIO=$(echo ${linha} | awk -F "," '{print $4}')

    if [ "$HASHARQUIVOSENVIO" != "$ULTIMO_ENVIO" ]
    then
        ps aux | grep "enviarArquivoRsync2.sh" | grep "${IP_NAS}" | grep -v grep > /dev/null
            if [ $? -ne 0 ]
            then
            nping --tcp -p 873 ${IP_NAS} | grep -v "TTL=0" | grep RCVD 1> /dev/null 2> /dev/null
                    if [ $? -eq 0 ]
                    then
                            ${DIR_INSTALL}/enviarArquivoRsync2.sh ${ZONA} ${IP_NAS} ${DATA_ATIVO} ${HASHARQUIVOSENVIO} &
                    else
                            echo "`date "+%Y%m%d %H:%M:%S"` - Erro no envio dos arquivos para o NAS da Zona${ZONA} de IP ${IP_NAS} ele está inacessível" >> ${ARQUIVO_LOG_ENV}.log
                    fi
                    sleep 5
            fi
    fi
done < ${ARQUIVO_CADASTRO_NAS}
rm -f ${ARQUIVO_CADASTRO_NAS}

exit 0

