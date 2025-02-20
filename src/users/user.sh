#!/bin/bash

function user_usage()
{
    echo "Usage:"
    echo "    ${cmd//_/:} [options] <username>"
    echo ""
    echo "Arguments:"
    echo "  username                 Username"
    echo ""
    echo "Options:"
    echo "  -h, --help              Display this help message"
    echo "      --uid               User ID"
    echo "      --gid               User's group ID"
    echo "      --home              User's home "
    echo "      --password          User's password"
    echo "      --group             Sets groups to user"
    echo "  -f, --update            Update user if already exist"
    echo ""
    echo "Help:"
    echo "  The ${cmd//_/:} Add or update user"
    echo ""
    echo "  $0 ${cmd//_/:} centos"
    echo "  $0 ${cmd//_/:} centos --uid=2000 --gid=2000 --password=pwd123 --group=wheel"
    echo ""
}

# Reads arguments options
function parse_user_arguments()
{
  # if [ $# -ne 0 ]; then
    local TEMP=`getopt -o p::,h --long help,uid::,gid::,home::,group::,password::,user:: -n "$0" -- "$@"`
    
	eval set -- "$TEMP"
    # extract options and their arguments into variables.
    while true ; do
        case "$1" in
            -h|--help) HELP=1 ; shift 1 ;;
            --uid) uid="-u ${2}" ; shift 2 ;;
            --gid) gid="${2}" ; shift 2 ;;
            --home) home="${2}" ; shift 2 ;;
            --password) password="${2}" ; shift 2 ;;
            --group) groups+="${2} "; shift 2 ;;
            --user) users+="${2} "; shift 2 ;;
            --) shift ; break ;;
            *) echo "Internal error! $1" ; exit 1 ;;
        esac
    done

    shift $(expr $OPTIND - 1 )
    _parameters=$@
    
    if [[ "1" == $HELP ]]; 
    then
        user_usage
        exit 0
    fi
}

# 
function user_add() 
{
    set -e
    local HELP=0
    local home=
    local uid=
    local gid=
    local password=
    local groups=

    local _parameters=
    parse_user_arguments $@ 
    if [ -n "$_parameters" ]; then set $_parameters; fi

    username=$1

        # echo "----> user_add ${username} "

    if [[ -z "$username" ]]; 
    then
        echo "Commande invalide!"
        echo "    Required username"
        user_usage
        exit 1
    fi

    
    if [ -n "${gid}" ]; then
        if [[ ! $(getent group ${username}) && ! $(getent group ${gid}) ]]; then 
            case `platform` in 
                alpine) echo "addgroup -g $gid ${username}" ;;
                *) 
                    groupadd -g $gid ${username}
                    
                ;;
            esac
        fi
        gid="-g $gid"
    fi

    if ! getent passwd ${username} > /dev/null 2>&1; then
        case `platform` in 
            alpine) 
                if [ -n "$home" ]; then home="-h $home"; fi
                echo "adduser -D --shell /bin/bash $uid $home ${username}"
                adduser -D --shell /bin/bash  $uid $home ${username}
            ;;
            debian) 
                if [ -n "$home" ]; then home="-d $home"; fi
                echo "useradd --shell /bin/bash -m  $uid $gid $home ${username}"
                useradd --shell /bin/bash -m $uid $gid $home ${username}
                id ${username}
            ;;
            *) 
                if [ -n "$home" ]; then home="-d $home"; fi
                echo "useradd --shell /bin/bash $uid $gid $home ${username}"
                useradd --shell /bin/bash $uid $gid  $home ${username}
                id ${username}
            ;;
        esac
        # if [[ -n "$home" && ! -d $home ]]; then sudo mkdir -p $home; fi
        # if [ -n "$home" && ! -d $home ]; then sudo mkdir -p $home; fi
    else
        echo "----> User ${username} already exists"
        case `platform` in 
            # alpine) moduser --shell /bin/bash $uid -g ${username} ${username};;
            *) usermod --shell /bin/bash $uid -g ${username} ${username};;
        esac
    fi
    
    for group in $groups
    do  
        # checks if user exit
        if ! $(getent group ${group})
        then
            case `platform` in 
                # alpine) addgroup $group;;
                *) groupadd $group;;
            esac
            
            # echo "Group '$group' does not exist: group created!"
        fi
        
        
        case `platform` in 
            alpine) usermod -aG $group ${username};;
            *) usermod -aG $group ${username};;
        esac
    done

    if [ -n "$password" ]; then
        case `platform` in 
            redhat) echo "${password}" | passwd $username --stdin ;;
            # debian|ubuntu) echo -e "${password}\n${password}" | passwd $username ;;
            # alpine) echo -e "${password}\n${password}" | passwd $username ;;
            *) echo -e "${password}\n${password}" | passwd $username ;;
        esac
    fi
#     for user in $_USERS
#     do  
#     done


}

# 
function user_update() 
{
    set -e
    local help=0
    local home=
    local uid=
    local gid=
    local password=
    local groups=

    local _parameters=
    parse_user_arguments $@ 
    if [ -n "$_parameters" ]; then set $_parameters; fi

    username=$1

    if [[ -z "$username" ]]; 
    then
        echo "Commande invalide!"
        echo "    Required username"
        user_usage
        exit 1
    fi
    
    if getent passwd ${username} > /dev/null 2>&1; then
        echo "Commande invalide!"
        echo "    user '$username' not found"
        exit 1
    fi

    if [ -n "$uid" ] ; then
        case `platform` in 
            redhat) echo "${password}" | passwd $username --stdin ;;
            debian|ubuntu) echo -e "${password}" | passwd $username ;;
            *) echo -e "${password}" | passwd $username ;;
        esac
        usermod $uid ${username};
    fi
    if [ -n "$gid" ] ; then
        usermod $gid ${username};
    fi
    
    for group in $groups
    do  
        # checks if user exit
        if ! $(getent group ${group})
        then
            case `platform` in 
                # alpine) addgroup $group;;
                *) groupadd $group;;
            esac            
        fi
        usermod -aG $group ${username}
    done

    if [ -n "$password" ]; then
        echo "${password}" | passwd $username --stdin 
    fi
}
    
    
# # Configuration des comptes administrateurs

# # if [ -n "${ROOT_PASSWORD}" ];
# # then
# #     echo "${ROOT_PASSWORD}" | passwd "root" --stdin ; 
# # fi ;

# # # Sets user primary group
# # if [ ! $(getent group ${GROUP_ADMIN}) ]; 
# # then 
# #     groupadd ${GROUP_ADMIN}; 
# # fi 

# # usermod  -aG ${GROUP_ADMIN} root

# # if [ -n "$GROUP_ADMIN_UID" ]; 
# # then 
# #     groupmod -g $GROUP_ADMIN_UID ${GROUP_ADMIN}; 
# # fi


# _USER=${1}
# _USER_UID=${2}

# #
# # Create user account if not exist


# # ssh
# if ! getent passwd ${_USER} > /dev/null 2>&1; 
# then
        
#     if [ "$_USER" == "${GROUP_ADMIN}" ]; 
#     then
#         useradd -g ${_USER} ${_USER};
#     else
#         useradd ${_USER};
#     fi

    
# fi

# usermod $_USER -aG ${GROUP_ADMIN}

# if [ -n "$_USER_UID" ];
# then
#     usermod -u $_USER_UID ${_USER};
# fi
		
# # Sets user's password
# # if [ -n "${USER_PASSWORD}" ];
# # then 
# #     echo "${USER_PASSWORD}" | passwd "${_USER}" --stdin ;
# # fi;


# # ssh
# if getent passwd ${_USER} > /dev/null 2>&1; 
# then
#     if [[ -d $CONFIG_DIR/.${_USER}/.ssh ]]
#     then
#         mv $CONFIG_DIR/.${_USER}/.ssh /home/${_USER}/.ssh
#         chmod 600 /home/${_USER}/.ssh/*
#         chmod 700 /home/${_USER}/.ssh
#         if [ -f /home/${_USER}/.ssh/config ]; then chmod 644 /home/${_USER}/.ssh/config; fi
#     fi
    
#     if [ -f $CONFIG_DIR/.${_USER}/.gitconfig ]; then 
#         mv $CONFIG_DIR/.${_USER}/.gitconfig /home/${_USER}/;
#     fi

#     if [[ -d $CONFIG_DIR/.${_USER} ]]
#     then
#         rm -rf $CONFIG_DIR/.${_USER}
#     fi&_2(2Sotl/z!
# fi

# chown ${_USER}:${_USER} -R /home/${_USER}/