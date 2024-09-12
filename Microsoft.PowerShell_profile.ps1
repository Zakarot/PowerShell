function update (){
    Start-Process powershell Update-Help -Verb runAs -WindowStyle Hidden
    bash -c "\
        sudo apt update && \
        sudo apt upgrade -y && \
        sudo apt autoremove -y \
        "
}

function setup (){
    #Configure WSL
    bash -c '\
        echo 'zadmin  ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/zadmin && \
        touch /home/zadmin/.hushlogin && \
    '
    #Import PowerShell scripts and profile from github
    bash -c '\
        cd /mnt/c/Users/Zadmin/Documents/WindowsPowerShell && \
        sudo git init && \
        git pull https://github.com/Zakarot/PowerShell-Scripts.git \
    '
    #Import Bash scripts from github
        bash -c '\
        echo \$PATH:~/bash/ >> .bashrc && \
        mkdir  ~/bash/ && \
        cd  ~/bash/ && \
        sudo git init && \
        git pull https://github.com/Zakarot/Bash-Scripts.git \
    '
}

function nano ($File){
    $File = $File -replace "\\", "/" -replace " ", "\ "
    bash -c "nano $File"
}

