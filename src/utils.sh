
#!/bin/bash

# check to see if this file is being run or sourced from another script
is_sourced () {
  [[ "${FUNCNAME[1]}" == "source" ]]  && return 0
  return 1
}

# Checks if given string is an valid url
function is_url()
{
    # -- supported protocols (HTTP, HTTPS, FTP, FTPS, SCP, SFTP, TFTP, DICT, TELNET, LDAP or FILE) --
    regex='([a-z]{3,6})://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
    string=$1
    if [[ $string =~ $regex ]]
    then 
        true
    else
        false
    fi
}

# Transform snake words to camel
function snake_to_camel()
{
    echo $(echo $1 | sed -r 's/(^|_)(\w)/\U\2/g' )
}

# Transform camel words to snake
function camel_to_snake() 
{
    echo $(echo $1 | sed 's/\(.\)\([A-Z]\)/\1_\2/g' | tr '[:upper:]' '[:lower:]')
}

# get plateform
function plateform() 
{
    local value="debian"
    case `plateform_name` in
        centos|rhel|fedora)
            value="redhat";
            ;;
        *)
            value="debian"
        ;;
    esac

    echo $value
}

# get plateform name
function plateform_name() 
{
    local value=$(awk -F= '/^ID=/{print $2}' /etc/os-release)
    echo ${value//\"/}
}

# get plateform version
function plateform_version() 
{
    local value=$(awk -F= '/^VERSION_ID=/{print $2}' /etc/os-release)
    echo ${value//\"/}
}


# get plateform version
function os_type() 
{
    local value=$(awk -F= '/^ID_LIKE=/{print $2}' /etc/os-release)
    value=${value//\"/}
    regex="^(debian|ubuntu)$"
    if [[ $value =~ $regex ]]
    then 
        true
    else
        false
    fi
}
function is_alpine() 
{
    local value=$(plateform_name)
    regex="^(alpine)$"
    if [[ $value =~ $regex ]]
    then 
        true
    else
        false
    fi
}
function is_debian() 
{
    local value=$(awk -F= '/^ID_LIKE=/{print $2}' /etc/os-release)
    value=${value//\"/}
    regex="^(debian|ubuntu)$"
    if [[ $value =~ $regex ]]
    then 
        true
    else
        false
    fi
}

function is_redhat() 
{    
    local value=$(awk -F= '/^ID_LIKE=/{print $2}' /etc/os-release)
    value=${value//\"/}
    regex="^(rhel|centos|fedora)$"

    # echo $value
    if [[ $value =~ $regex ]]
    then 
        true
    else
        false
    fi
}

function install() 
{
    # echo "sudo yum install $@"
    case `plateform` in 
        debian)
            if [ "$EUID" -ne 0 ]; then 
                echo ">> sudo apt-get install $@"
                sudo apt-get install $@
            else
                echo ">> apt-get install $@"
                apt-get install $@
            fi
            ;;
            
        redhat)
            if [ "$EUID" -ne 0 ]; then
                echo ">> sudo yum install $@"
                sudo yum install $@
            else
                echo ">> yum install $@"
                yum install $@
            fi
            ;;
            
        alpine)
            if [ "$EUID" -ne 0 ]; then
                echo ">> sudo apk install $@"
                sudo apk install $@
            else
                echo ">> apk install $@"
                apk install $@
            fi
        ;;
    esac

}

