#!/bin/bash

ZONA=$1
IP_NAS=$2
DATA_ATIVO=$3
HASHARQUIVOSENVIO=$4
PORTA_NAS=873
DATA=$(date +%Y%m%d-%H%M)

DIRETORIO_LOG_ZONA=${DIR_INSTALL}/backups/zona${ZONA}/logs

EXCLUDES_ENV=${DIR_INSTALL}/excludesEnvio
PASTA_ORIGEM=/var/backupNAS/enviarNAS/

export PATH=$PATH:/bin:/usr/bin:/usr/local/bin

OPTS="--bwlimit=${VELOCIDADE_UPLOAD}KiB --progress --stats --partial --partial-dir=.rsynctmp/ --delete-after -a -h"

#
# Testa a conexão com os NAS da Lenovo
#
USER_RSYNC=XXXXX
export RSYNC_PASSWORD=XXXXXX

rsync -a /var/backupNAS/testersync.txt rsync://${USER_RSYNC}@${IP_NAS}:${PORTA_NAS}/zona${ZONA} 2> /dev/null

if [ $? -eq 0 ]
then
        echo "`date "+%Y%m%d %H:%M:%S"` - Iniciado o envio dos arquivos para a Zona${ZONA} no NAS ${IP_NAS}" >> ${ARQUIVO_LOG_ENV}.log
        rsync ${OPTS} ${PASTA_ORIGEM} rsync://${USER_RSYNC}@${IP_NAS}:${PORTA_NAS}/TRE_Suporte/ > ${DIRETORIO_LOGS_ENV}/${DATA}-logEnvioZona${ZONA}.log 2> ${DIRETORIO_LOGS_ENV}/${DATA}-logEnvioZona${ZONA}.err
else
    #
    # Testa a conexão com os NAS da WD
    #
    USER_RSYNC=XXXXX
    export RSYNC_PASSWORD=XXXXX
    rsync -a /var/backupNAS/testersync.txt rsync://${USER_RSYNC}@${IP_NAS}:${PORTA_NAS}/zona${ZONA} 2> /dev/null
    if [ $? -eq 0 ]
    then
            echo "`date "+%Y%m%d %H:%M:%S"` - Iniciado o envio dos arquivos para a Zona${ZONA} no NAS ${IP_NAS}" >> ${ARQUIVO_LOG_ENV}.log
            rsync ${OPTS} ${PASTA_ORIGEM} rsync://${USER_RSYNC}@${IP_NAS}:${PORTA_NAS}/TRE_Suporte/ > ${DIRETORIO_LOGS_ENV}/${DATA}-logEnvioZona${ZONA}.log 2> ${DIRETORIO_LOGS_ENV}/${DATA}-logEnvioZona${ZONA}.err
    else
        echo "`date "+%Y%m%d %H:%M:%S"` - Erro ao conectar no servidor rsync da Zona${ZONA} no NAS ${IP_NAS}" >> ${ARQUIVO_LOG_ENV}.log
    fi
fi

cat ${DIRETORIO_LOGS_ENV}/${DATA}-logEnvioZona${ZONA}.log | grep "total size is" > /dev/null
if [ $? -eq 0 ]
then
        ARQ_CRIADOS=$(cat ${DIRETORIO_LOGS_ENV}/${DATA}-logEnvioZona${ZONA}.log | grep "Number of created files:" | awk -F ":" '{print $2}' | awk -F "(" '{print $1}' | sed 's/ //g')
        BYTES_TRANSF=$(cat ${DIRETORIO_LOGS_ENV}/${DATA}-logEnvioZona${ZONA}.log | sed -n -r 's/Total transferred file size: (.*) bytes/\1/p')
        BYTES_SEC=$(cat ${DIRETORIO_LOGS_ENV}/${DATA}-logEnvioZona${ZONA}.log | sed -n -r 's/sent .* (.*) bytes\/sec/\1/p')
    echo "`date "+%Y%m%d %H:%M:%S"` - Termino do Envio dos arquivos para a Zona${ZONA} no NAS ${IP_NAS} - Arq criados: ${ARQ_CRIADOS} - Bytes transf: ${BYTES_TRANSF}" - "Bytes/sec: ${BYTES_SEC}" >> ${ARQUIVO_LOG_ENV}.log

        DATAATIVO=$(echo ${linha} | awk -F "," '{print $3}')
    sed -i "s/^${ZONA},${IP_NAS},.*/${ZONA},${IP_NAS},${DATA_ATIVO},${HASHARQUIVOSENVIO}/" ${DIR_INSTALL}/NAS.txt
else
        echo "`date "+%Y%m%d %H:%M:%S"` - Ocorreu um Erro durante o envio dos arquivos para a Zona${ZONA} no NAS ${IP_NAS}" >> ${ARQUIVO_LOG_ENV}.log
fi

mkdir -p ${DIRETORIO_LOG_ZONA}
mv ${DIRETORIO_LOGS_ENV}/${DATA}-logEnvioZona${ZONA}.log ${DIRETORIO_LOGS_ENV}/${DATA}-logEnvioZona${ZONA}.err ${DIRETORIO_LOG_ZONA}
chown -R rsync: ${DIRETORIO_LOG_ZONA}

exit 0

