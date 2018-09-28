#!/bin/bash
#


# Definizione dei parametri di configurazione dello script
#
# Questi parametri devono essere modificati in base alla configurazione attuale del proprio sistema; il loro nome è autoesplicativo.
# 
# Nota riguardante i parametri PG_DBEXCLUDE, MY_DBEXCLUDE, PG_DBINCLUDE, MY_DBINCLUDE
#
#  1. MY_DBEXCLUDE e PG_DBEXCLUDE devono contenere l'elenco dei rispettivi database da escludere dall'operazione di backup, separati
#     da spazio (tipicamente i database di sistema che non necessitano di essere salvati): verrà quindi effettuato il backup
#     di tutti i database tranne quelli specificati
#
#  2. MY_DBINCLUDE e PG_DBINCLUDE, se impostati, devono contenere l'elenco dei soli database da includere nell'operazione di backup;
#     in tal caso verrà effettuato il dump ESCLUSIVAMENTE dei rispettivi database indicati, mentre il contenuto di MY_DBEXCLUDE e
#     PG_DBEXCLUDE verrà ignorato. Se MY_DBINCLUDE e PG_DBINCLUDE non sono impostati (oppure sono impostati con una stringa nulla),
#     verrà effettuato il backup di tutti i database tranne quelli specificati in MY_DBEXCLUDE e PG_DBEXCLUDE (vedi caso al punto 1)

DBDUMP_ROOT="/var/databases/db_dump"
DBDUMP_LOGDIR="${DBDUMP_ROOT}/logs"
MY_BACKUPROOT="${DBDUMP_ROOT}/mysql"
PG_BACKUPROOT="${DBDUMP_ROOT}/postgres"
MY_USER=root
PG_USER=postgres
MY_DBEXCLUDE="information_schema performance_schema"
PG_DBEXCLUDE="template0 template1"
MY_DBINCLUDE=""
PG_DBINCLUDE=""
MAIL_SENDER="TO,TO2"
MAIL_RECIPIENT="FROM"
MAIL_SMTP_HOST="SERVER"
COPIES_TO_KEEP="10"
MAIL_HOUR="12"


# Contatore degli errori verificatisi durante l'esecuzione dello script. Viene incrementato ad ogni errore dalla funzione "count_errors"
# impostata all'inizio del programma come error handler

let ERROR_COUNT=0


# Definisco i percorsi espliciti delle varie utilities richiamate nel programma

WHICH="`which which`"
AWK="`${WHICH} awk`"
DATE="`${WHICH} date`"
ECHO="`${WHICH} echo`"
GREP="`${WHICH} grep`"
GZIP="`${WHICH} gzip`"
PIGZ="`${WHICH} pigz`"
LS="`${WHICH} ls`"
MKDIR="`${WHICH} mkdir`"
MYSQL="`${WHICH} mysql`"
MYSQLDUMP="`${WHICH} mysqldump`"
NETSTAT="`${WHICH} netstat`"
PSQL="`${WHICH} psql`"
PG_DUMP="`${WHICH} pg_dump`"
PG_DUMPALL="`${WHICH} pg_dumpall`"
RM="`${WHICH} rm`"
SED="`${WHICH} sed`"
SENDEMAIL="`${WHICH} sendEmail`"
TAIL="`${WHICH} tail`"
TOUCH="`${WHICH} touch`"
XARGS="`${WHICH} xargs`"


# Error handler richiamato ad ogni errore

count_errors() {

#	Incremento il contatore d'errore

	let ERROR_COUNT++
}


# Qualora non esistesse, creo la root dove saranno memorizzate le sottocartelle con i backup di MySQL e PostgreSQL

if [ ! -e "${DBDUMP_ROOT}" ]
then
	${MKDIR} -p "${DBDUMP_ROOT}"
fi


# Qualora non esistesse, creo la cartella dove verranno memorizzati i files di log

if [ ! -e "${DBDUMP_LOGDIR}" ]
then
        ${MKDIR} -p "${DBDUMP_LOGDIR}"
fi


# Recupero l'ora corrente (mi servira' per determinare se inviare o meno il log via email)

START_HOUR="`${DATE} +%H`"


# Recupero la specifica completa di data e ora in formato YYYYMMDD_HHMMSS (mi servirà per identificare la sottocartella dove verranno
# memorizzati i dump dei database)

START_DATETIME="`${DATE} +%Y%m%d_%H%M%S`"


# Stabilisco i nomi dei file di log in base alla data e ora corrente

LOGFILE="${DBDUMP_LOGDIR}/db_dump_${START_DATETIME}.log"
MAILLOGFILE="${DBDUMP_LOGDIR}/mail_send_${START_DATETIME}.log"


# Effettuo la ridirezione di stdout e stderr sul file di log

${TOUCH} ${LOGFILE}

exec 6>&1
exec > ${LOGFILE}
exec 7>&2
exec 2>&1


# Imposto l'error handler che da questo momento in poi verra' richiamato automaticamente ad ogni errore

trap count_errors ERR


# Determino se i database MySQL e Postgres sono avviati, esaminando se sono aperti i relativi socket

MY_RUNNING="`${NETSTAT} -tlnp | ${GREP} -q mysqld; ${ECHO} $?`"
PG_RUNNING="`${NETSTAT} -tlnp | ${GREP} -q postgres; ${ECHO} $?`"


# Determino l'elenco dei database MySQL di cui effettuare il dump

if [ $MY_RUNNING -eq 0 ]
then

	# Determino se effettuare la copia per inclusione o per esclusione

	if [ -z "$MY_DBINCLUDE" ]
	then

		# Copia per esclusione: effettuo il backup di tutti i database tranne quelli specificati in MY_DBEXCLUDE

		# Recupero i nomi dei database MySQL presenti sull'host

		MY_DBNAMES="`${MYSQL} --user=${MY_USER} --batch --skip-column-names -e "show databases" | ${SED} 's/ /%/g'`"

		# Rimuovo dalla lista dei database MySQL da salvare gli eventuali database specificati dalla variabile MY_DBEXCLUDE

		for exclude in ${MY_DBEXCLUDE}
		do
        		MY_DBNAMES=`${ECHO} ${MY_DBNAMES} | ${SED} "s/\b${exclude}\b//g"`
		done

	else

		# Copia per inclusione: effettuo il backup dei soli database specificati in MY_DBINCLUDE

		MY_DBNAMES="${MY_DBINCLUDE}"

	fi

	# Qualora non esistesse, creo la root dove saranno memorizzati i backup di MySQL

	if [ ! -e "${MY_BACKUPROOT}" ]
	then
        	${MKDIR} -p "${MY_BACKUPROOT}"
	fi

fi


# Determino l'elenco dei database PostgreSQL di cui effettuare il dump

if [ $PG_RUNNING -eq 0 ]
then

        # Determino se effettuare la copia per inclusione o per esclusione

        if [ -z "$PG_DBINCLUDE" ]
        then

		# Copia per esclusione: effettuo il backup di tutti i database tranne quelli specificati in PG_DBEXCLUDE

		# Recupero i nomi dei database PostgreSQL presenti sull'host

		PG_DBNAMES=`${PSQL} -l -t -U ${PG_USER} | ${AWK} '{print $1}' | ${GREP} -v "|"`

		# Rimuovo dalla lista dei database PostgreSQL da salvare gli eventuali database specificati dalla variabile PG_DBEXCLUDE

		for exclude in ${PG_DBEXCLUDE}
		do
        		PG_DBNAMES=`${ECHO} ${PG_DBNAMES} | ${SED} "s/\b${exclude}\b//g"`
		done

        else

                # Copia per inclusione: effettuo il backup dei soli database specificati in PG_DBINCLUDE

                PG_DBNAMES="${PG_DBINCLUDE}"

        fi

	# Qualora non esistesse, creo la root dove saranno memorizzati i backup di PostgreSQL

	if [ ! -e "${PG_BACKUPROOT}" ]
	then
        	${MKDIR} -p "${PG_BACKUPROOT}"
	fi

fi


# Scrivo banner iniziale sul file di log

${ECHO} =======================================================================================================================================
${ECHO}

if [ $MY_RUNNING -eq 0 ]
then

	if [ -z "$MY_DBINCLUDE" ]
	then
		${ECHO} MySQL databases EXCLUDED from backup: ${MY_DBEXCLUDE}
	else
		${ECHO} MySQL databases INCLUDED in backup: ${MY_DBINCLUDE}
	fi

	${ECHO}

fi

if [ $PG_RUNNING -eq 0 ]
then

        if [ -z "$PG_DBINCLUDE" ]
        then
		${ECHO} PostgreSQL databases EXCLUDED from backup: ${PG_DBEXCLUDE}
	else
		${ECHO} PostgreSQL databases INCLUDED in backup: ${PG_DBINCLUDE}
	fi

	${ECHO}
fi

${ECHO} ============================================= BACKUP STARTED AT `${DATE} +%d/%m/%Y\ %H:%M:%S` ===================================================


# Loop per il backup dei database MySQL (effettuato solo se MySQL è attivo). Ogni dump viene compresso.

if [ $MY_RUNNING -eq 0 ]
then

        # Costruisco il pathname completo della sottocartella che conterrà i dump effettuati in questa sessione e la creo

        MY_BACKUPDIR="${MY_BACKUPROOT}/${START_DATETIME}"
        ${MKDIR} -p "${MY_BACKUPDIR}"

	# Effettuo il loop su tutti i database MySQL selezionati

	for DB in ${MY_DBNAMES}
	do
        	DB="`${ECHO} ${DB} | ${SED} 's/%/ /g'`"

        	${ECHO}
        	${ECHO} `${DATE} +%d/%m/%Y\ %H:%M:%S`: Dump of MySQL database \"${DB}\" to \"${MY_BACKUPDIR}/${DB}.sql.gz\"
        	${ECHO}

        	${MYSQLDUMP} --user=${MY_USER} --quote-names --single-transaction --events --opt "${DB}" > "${MY_BACKUPDIR}/${DB}.sql"

        	#${GZIP} -f "${MY_BACKUPDIR}/${DB}.sql"
        	#${GZIP} -l "${MY_BACKUPDIR}/${DB}.sql.gz"
          ${PIGZ} -f "${MY_BACKUPDIR}/${DB}.sql"
        	${PIGZ} -l "${MY_BACKUPDIR}/${DB}.sql.gz"
	done
fi


# Loop per il backup dei database PostgreSQL (effettuato solo se PostgreSQL è attivo). Ogni dump viene compresso.

if [ $PG_RUNNING -eq 0 ]
then

    # Costruisco il pathname completo della sottocartella che conterrà i dump effettuati in questa sessione e la creo

    PG_BACKUPDIR="${PG_BACKUPROOT}/${START_DATETIME}"
    ${MKDIR} -p "${PG_BACKUPDIR}"

    # Effettuo il dump delle configurazioni globali (ruoli e tablespaces)

    ${PG_DUMPALL} --username=${PG_USER} -g > "${PG_BACKUPDIR}/globals.sql"
    ${GZIP} -f "${PG_BACKUPDIR}/globals.sql"
    ${GZIP} -l "${PG_BACKUPDIR}/globals.sql.gz"

    # Effettuo il loop su tutti i database PostgreSQL selezionati

    for DB in ${PG_DBNAMES}
    do
            ${ECHO}
            ${ECHO} `${DATE} +%d/%m/%Y\ %H:%M:%S`: Dump of PostgreSQL database \"${DB}\" to \"${PG_BACKUPDIR}/${DB}.sql.gz\"
            ${ECHO}

            ${PG_DUMP} --username=${PG_USER} "${DB}" > "${PG_BACKUPDIR}/${DB}.sql"

            #${GZIP} -f "${PG_BACKUPDIR}/${DB}.sql"
            #${GZIP} -l "${PG_BACKUPDIR}/${DB}.sql.gz"
            ${PIGZ} -f "${PG_BACKUPDIR}/${DB}.sql"
            ${PIGZ} -l "${PG_BACKUPDIR}/${DB}.sql.gz"

    done
fi


# Scrivo banner finale sul file di log

${ECHO}
${ECHO} ============================================ BACKUP TERMINATED AT `${DATE} +%d/%m/%Y\ %H:%M:%S` =================================================


# Backup terminato. Se non ci sono stati errori, effettuo il cleanup delle vecchie copie di backup e dei vecchi files di log

if [ ${ERROR_COUNT} == 0 ]
then

	# Cleanup dump di MySQL

	if [ $MY_RUNNING -eq 0 ]
	then
		${ECHO}
        	${ECHO} Cleaning up old MySQL dumps...

		${LS} -d -r ${MY_BACKUPROOT}/*/ | ${TAIL} -n +$(($COPIES_TO_KEEP+1)) | ${XARGS} -I {} ${RM} -f -r -- {}
	fi

	# Cleanup dump di PostgreSQL

	if [ $PG_RUNNING -eq 0 ]
	then
		${ECHO}
        	${ECHO} Cleaning up old PostgreSQL dumps...

		${LS} -d -r ${PG_BACKUPROOT}/*/ | ${TAIL} -n +$(($COPIES_TO_KEEP+1)) | ${XARGS} -I {} ${RM} -f -r -- {}
	fi

	# Cleanup files di log

	${ECHO}
	${ECHO} Cleaning up old log files...

	${LS} -r ${DBDUMP_LOGDIR}/db_dump_*.log | ${TAIL} -n +$(($COPIES_TO_KEEP+1)) | ${XARGS} -I {} ${RM} -f -- {}
	${LS} -r ${DBDUMP_LOGDIR}/mail_send_*.log | ${TAIL} -n +$(($COPIES_TO_KEEP+1)) | ${XARGS} -I {} ${RM} -f -- {}

else

        ${ECHO}
        ${ECHO} "***** WARNING ***** - Database backup on ${HOSTNAME} completed with ${ERROR_COUNT} errors - No cleanup done"

fi


# Cleanup terminato. Verifico la presenza di eventuali errori (che potrebbero essersi verificati anche in fase di cleanup)

if [ ${ERROR_COUNT} != 0 ]
then
	MAIL_SUBJECT="***** WARNING ***** - Database backup on ${HOSTNAME} completed with ${ERROR_COUNT} errors"
	STATUS=1
else
	MAIL_SUBJECT="Database backup on ${HOSTNAME} completed succesfully"
	STATUS=0
fi

MAIL_BODY="See attached log for more information"


# Chiusura del file di log

${ECHO}
${ECHO} =======================================================================================================================================


# Elimino la ridirezione di stdout e stderr, ripristinando i puntamenti precedenti
# In questo modo chiudo il file di log prima di procedere con il suo invio via email

exec 1>&6 6>&-
exec 2>&7 7>&-


# Invio email di riscontro, ridirigendo il relativo stdout e stderr su un altro file di log, in modo da poter avere un riscontro in caso di errore.
# La mail viene inviata sempre in caso di errore, oppure solo una volta al giorno in assenza di errore (all'ora indicata dalla variabile MAIL_HOUR)

if [ ${ERROR_COUNT} != 0 ] || [ ${MAIL_HOUR} == ${START_HOUR} ]
then
	${SENDEMAIL} -o tls=no -f ${MAIL_SENDER} -t ${MAIL_RECIPIENT} -s ${MAIL_SMTP_HOST} -u "${MAIL_SUBJECT}" -m "${MAIL_BODY}" -a "${LOGFILE}" > "${MAILLOGFILE}" 2>&1
fi


# Termino l'esecuzione restituendo il codice di stato

exit ${STATUS}
