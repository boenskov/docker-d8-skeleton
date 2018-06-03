#!/bin/bash

# настройки по-умолчанию
# uid проекта (формируется из названия директории. Необходим для идентификации контейнеров)
DD8S_PROJECT_NAME=$(pwd|tr / "\n"|tail -1|head -1)
DD8S_PROJECT_NAME=${DD8S_PROJECT_NAME//[_ -]/}

# конфиг БД
DB_DATABASE_NAME="tendertech"
DB_USER_NAME="tendertech"
DB_USER_PAS="tendertech"

# Some utilities
_COLORS=${BS_COLORS:-$(tput colors 2>/dev/null || echo 0)}
__detect_color_support() {
    if [ $? -eq 0 ] && [ "$_COLORS" -gt 2 ]; then
        RC="\033[1;31m" #red
        GC="\033[1;32m" # green
        BC="\033[1;34m" #blue
        WC="\033[1;37m" #white
        YC="\033[1;33m" # yellow
        EC="\033[0m" # default

        BOLD="\033[1m"
        BOLD_OFF="\033[22m"
        ITALIC="\033[3m"
        ITALIC_OFF="\033[23m"
        UNDERLINE="\033[4m"
        UNDERLINE_OFF="\033[24m"
        INVERSE="\033[7m"
        INVERSE_OFF="\033[7m"
        STRIKE="\033[9m"
        STRIKE_OFF="\033[9m"
        BE=${BOLD}
        BD=${BOLD_OFF}
    fi
}
__detect_color_support

printf "
*******************************************
**  ${GC}Установка и настройка контейнера${EC}  **
*******************************************

"

if [[ $# == 0 ]]
then
  #${BC}install all      ${EC}полная установка и настройка сайта (все шаги: code+config)
  #${BC}install docker   ${EC}установка docker и docker-compose

printf "
${BE}Доступные команды${BD}

  ${YC}Развертывание кода и конфигов:${EC}
  ${BE}prepare          ${EC}подготовка путей и установка основного необходимого софта: git, docker, docker-compose
  ${BE}clone            ${EC}склонирует основной код из репозитария
                   [!] перед установкой кода необходимо установить git, сгенерировать .ssh ключ и прописать его в GitLab
                   [!] папка www/site должна быть пуста
  ${BE}add_config       ${EC}создает дефолтный файл конфига

  ${YC}Операции с контейнером:${EC}
  ${BE}start            ${EC}запустить контейнер
  ${BE}stop             ${EC}остановить контейнер
  ${BE}status           ${EC}узнать состояние контейнеров

  ${YC}Операции с mysql (выполнять при запущенных контейнерах):${EC}
  ${BE}mysql_init       ${EC}добавление пользователя и базы данных
  (пока нормально не реализовано!!!)${BE}mysql_import <database.sql>
                        ${EC}импорт файла с дампом базы

  ${YC}Операции с docker:${EC}
  ${BE}fpm              ${EC}войти в контейнер fpm
  ${BE}mysql            ${EC}войти в контейнер mysql
  ${BE}nginx            ${EC}войти в контейнер nginx
  ${BE}logs             ${EC}посмотреть лог инициализации контейнера
  ${BE}stats            ${EC}показать текущую нагрузку контейнеров по CPU, памяти, сети и диску (^C - завершить)
                        
  Идентификатор проекта: ${BOLD}${DD8S_PROJECT_NAME}${BOLD_OFF}

"
exit
fi


# цветные сообщения
echoinfo() { printf "${GC}[ ИНФО ]${EC}: %s\n" "$@"; }
echook() { printf "${GC}[ OK ]${EC}: %s\n" "$@"; }
echoerror() { printf "${RC}[ ОШИБКА ]${EC}: %s\n" "$@" 1>&2; }
echowarn() { printf "${YC}[ ПРЕДУПРЕЖДЕНИЕ ]${EC}: %s\n" "$@"; }


basedir=$DIRSTACK

function install_code()
{
    echoinfo "Выполняется установка кода....."
    # проверим существования ключа...
    if ! [[ -f ~/.ssh/id_rsa ]]
    then
        echoerror "Не найден приватный ключ  ~/.ssh/id_rsa ... его необходимо сгенерировать и прописать публичную часть в GitLab"
        exit 1
    fi

    if ! [ `ls www/site | wc -l` -eq 0 ]
    then
        echoerror "Каталог www/site должен быть пустым"
        exit 1
    fi

    #install_git
    cd www/site
    echoinfo "Выполняется получение кода из репозитария..."
    # TODO добавить сюда свою строку клонирования репозитария
#    git clone git@192.168.1.25:all/tt.git .
    if [[ $? -eq 0 ]]
    then
        echook "Код из репозитария получен. ${BE}Не забудь сделать в папке www git checkout на нужную ветку.${BD}"
    else
        echoerror "Что-то пошло не так!"
        exit 1
    fi
}

function install_config()
{
    cd $basedir
    echoinfo "Установка конфигов....."

    echo "<?php
\$databases = array (
  'default' =>
  array (
    'default' =>
    array (
      'database' => '${DB_DATABASE_NAME}',
      'username' => '${DB_USER_NAME}',
      'password' => '${DB_USER_PAS}',
      'host' => 'sql',
      'port' => '',
      'driver' => 'mysql',
      'prefix' => '',
    ),
  ),
);

\$drupal_hash_salt = 'lRD5iFjAcUi6FwrV4M-b2E__jC9BiuLcaHngjKIGsVg';

ini_set('session.gc_probability', 1);
ini_set('session.gc_divisor', 100);

ini_set('session.gc_maxlifetime', 200000);
ini_set('session.cookie_lifetime', 2000000);
/* настройки заявок */
#\$conf['base-mod-conf']=array(
#  'zayavkasabspathtofilesdir'=>'/var/www/tender-files',
#  'userabspathtofilesdir'=>'/var/www/user-files',
#);
" > www/site/sites/default/settings.php

    echook "Выполнено"

}

function start_docker(){
    echoinfo "Стартуем контейнер для ${DD8S_PROJECT_NAME}..."
    docker-compose -p "${DD8S_PROJECT_NAME}" up -d --build
    if [[ $? -eq 0 ]]
    then
        echook "Контейнеры запущены"
        echoinfo "Должно быть 4 запущенных контейнера: (nginx, mysql, fpm, phpmyadmin)"
        #docker ps |grep ${DD8S_PROJECT_NAME}_
        status_docker
    else
        echoerror "Что-то пошло не так!"
        exit 1
    fi
}

function stop_docker(){
    echoinfo "Останавливаем контейнер для ${DD8S_PROJECT_NAME}..."
    docker-compose -p ${DD8S_PROJECT_NAME} down
    if [[ $? -eq 0 ]]
    then
        echook "Контейнеры остановлены"
        status_docker
        #docker ps |grep ${DD8S_PROJECT_NAME}_
    else
        echoerror "Что-то пошло не так!"
        exit 1
    fi
}

function status_docker(){
    echoinfo "Запущенные контейнеры для ${DD8S_PROJECT_NAME}..."
    docker ps | grep ${DD8S_PROJECT_NAME}_
    ccnt=$(docker ps | grep ${DD8S_PROJECT_NAME}_ | wc -l)
    echoinfo "Найдено запущенных контейнеров: $ccnt"
}

function mysql_init(){
    container_name=${DD8S_PROJECT_NAME}_tt_mysql_1
    echoinfo "Контейнер MYSQL ${container_name}"
    echoinfo "Создаем базу '${DB_DATABASE_NAME}'.."
    set -x
    docker exec ${container_name} mysql -pqwerty -e "CREATE DATABASE IF NOT EXISTS ${DB_DATABASE_NAME} CHARACTER SET='utf8'"
    set +x
    if ! [[ $? -eq 0 ]]
    then
        echoerror "Что-то пошло не так!"
        exit 1
    fi
    echoinfo "Добавляем пользователя базы с логином '${DB_USER_NAME}' и паролем '${DB_USER_PAS}'..."
    set -x
    docker exec ${container_name} mysql -pqwerty -D ${DB_DATABASE_NAME} -e "GRANT ALL PRIVILEGES ON ${DB_DATABASE_NAME}.* to ${DB_USER_NAME}@'%' identified by '${DB_USER_PAS}'"
    set +x
    if ! [[ $? -eq 0 ]]
    then
        echoerror "Что-то пошло не так!"
        exit 1
    fi
    echook "Создание БД и пользователя выполнено успешно"
}

function mysql_import(){
    container_name=${DD8S_PROJECT_NAME}_tt_mysql_1
    echoinfo "Контейнер MYSQL ${container_name}"
    echoinfo "Импортируем файл '$1' в базу '${DB_DATABASE_NAME}'..."
    if ! [[ -f $1 ]]
    then
        echoerror "файл $1 не существует"
        exit 1
    fi

    START=$(date +%s)

    echowarn "Эта процедура может занять дохренища времени! Терпи!
"
    read
    sudo cp $1 init_sql/import.sql
    set -x
    docker exec ${container_name} mysql -pqwerty  -D ${DB_DATABASE_NAME}  -e "source /init_sql/import.sql"
    #docker exec tt_mysql mysql -pqwerty -v -D ${TT_DATABASE_NAME} < $1
    set +x
    if ! [[ $? -eq 0 ]]
    then
        echoerror "Что-то пошло не так!"
        exit 1
    fi

    END=$(date +%s)
    DIFF=$(( $END - $START ))
    echook "Импорт выполнен успешно. Спасибо что дотерпел! Ты терпел $DIFF секунд"
}

function prepare(){
    echoinfo "Создание недостающих путей..."
    mkdir -p www/{site,tender-files,user-files,html}
    #mkdir -p www/tender-files/{bi_logs,demka,dhl,logs}
    mkdir -p {database,logs,init_sql}

}

function exec_bash(){
  container_name=${DD8S_PROJECT_NAME}_dd8s_${1}_1
  echoinfo "Входим в контейнер $1 (${container_name})" 
  docker exec -it ${container_name} bash  
  echoinfo "Сеанс в контейнере ${container_name} завершен"
}

# основной маршрутизатор

case $1 in
"prepare") prepare ;;
"clone") install_code ;;
"add_config") install_config ;;

"start") start_docker ;;
"stop")  stop_docker ;;
"status") status_docker ;;

"mysql_init") mysql_init ;;
"mysql_import")
    if [[ $# == 1 ]]
    then
        echoerror "необходимо указать имя файла с дампом для импорта"
        exit 1
    fi
    mysql_import $2
    ;;
"mysql") 
    exec_bash $1 
    ;;
"nginx") 
    exec_bash $1
    ;;
"fpm") 
    exec_bash $1
    ;;
"logs") 
    docker-compose logs
    ;;
"stats") 
    docker stats
    ;;

*)
    echoerror "Команда не найдена"

esac



#mysql -pqwerty
#create database sitesb;
#grant all privileges on ttt.* to ttt@'%' identified by 'ttt';
#source /init_sql/