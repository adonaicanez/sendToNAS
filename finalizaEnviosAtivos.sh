#!/bin/bash
#
# Interrompe apenas os backups ativos
#
/bin/kill -15 $(ps aux | grep rsync | grep -v grep | grep TRE_Suporte | awk '{print $2}') 2>/dev/null

