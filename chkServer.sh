#!/bin/bash
##################################################
## Author     :  OPSTime
## GitHub     :  https://github.com/OPSTime
## Create Date:  2009-12-30 14:30 
## Modify Date:  2010-01-21 11:45
##################################################


FRed="\E[31;40m"; FGreen="\E[32;40m"; FBlue="\E[34;40m"; FGrey="\E[38;40m"; St0="\033[1m"; Ed="\033[0m"

Usage() {
    echo "
    -p|-P  CheckProductInfo
    -c|-C  CheckCpu
    -m|-M  CheckMemory
    -n|-N  CheckNetwork
    -d|-D  CheckDisk 
    -s|-S  CheckSys 
       ''  CheckAll
"
}


PrintOut() {
    Str='----------------------------------------'
    printf "\n$FGreen$St0%s$Ed" $1
    printf "\n%s%s\n" "$Str" "$Str" 
}

CheckProductInfo() {
    PrintOut "ProductInfo"
    /usr/sbin/dmidecode|grep -E -m2  'Manufacturer|Product Name'|sed 's/^[ \t]*//' ; 
}

CheckCpu() {
    PrintOut "CpuInfo"
    cat /proc/cpuinfo|awk -F: '/model name/{i++;type=$2}END{printf "Count: "i"\nType :"type"\n"}'
}

CheckMemory() {
    PrintOut "MemoryInfo"
    /usr/sbin/dmidecode|awk '
        /Memory Device$/{ 
            do{
                getline name;
                if(name~/Size|Speed/){
                    if(name~/No Module Installed/){break};
                    sub(/[ \t]*/,"",name);
                    datearray[i++]=name;
                }
            } while(name!~/^Handle/);
        }END{
            print "Count:",i/2;
            for(n=0;n<i;n++){
                printf datearray[n]"\t\t";
                if(n%2 == 1||n == i-1){print ""}
            }
        }
'
}

CheckDisk() {
    PrintOut "DiskInfo"
    DiskInfo=($(fdisk -l|awk -F'[: ]' '/Disk \//{print $2}'))  
    DiskSize=($(fdisk -l|awk -F'[:,]' '/Disk \//{print $2}'))  
    echo -e "Count: ${#DiskInfo[*]}"
    for((i=0;i<${#DiskInfo[*]};i++));do
    	PartInfo=($(fdisk -l ${DiskInfo[$i]}|awk '/^\/dev/{print $1}'))  
    	echo "${DiskInfo[$i]} ${DiskSize[$((i*2))]} ${DiskSize[$((i*2+1))]}"
    	for ((j=0;j<${#PartInfo[*]};j++));do
    		PartSize=$(fdisk -l ${PartInfo[$j]} 2>&1|awk -F'[:,]' '/^Disk.*:/{print $2}')  
    		echo -e "      |-- ${PartInfo[$j]} ${PartSize}"
    	done
    done
}

CheckNetwork() {
    PrintOut "NetworkInfo"
    #统计有多少个网络接口
    EthNums=`lspci|grep -c "Ethernet"`; max=0
    for i in `seq $EthNums`;do
        #将每个网卡的IP存储到对应的数组内（IP0、...）
        eval IP$((i-1))=\(`ip add ls dev eth$((i-1)) | awk '/inet\>/{print $2}'`\)
        #取得当前网卡绑定IP个数（数组元素个数）
        local tmp=`eval echo \$\{\#IP$((i-1))[@]\}`
        #取最大值给max（接口绑定的IP数）
        if [ "$tmp" -gt "$max" ];then max=$tmp;fi	
        #存储网卡工作速率和工作模式数组(Eth0、Eth1 ...)
        eval Eth$((i-1))=\(`ethtool "eth$((i-1))"|awk '/Speed|Duplex/{gsub(/ |\t/,"");gsub(/^|$/,"\"");print }'`\)
    done
    #输出网卡名（并排输出）
    for((i=0;i<$EthNums;i++));do  printf "%-25s" "<Eth$i>"; done
    echo
    #输出对应网卡的IP（并排输出,对应网卡每行仅显示一个,多个IP多行显示）
    for((i=$(($max-1));i>=0;i--));do
        for((j=0;j<$EthNums;j++));do
            printf "%-25s" $(eval echo \${IP$j[$i]})
        done
        echo 
    done
    #输出对应网卡的工作速率和工作模式（并排输出）
    for((n=0;n<=2;n++));do
        for i in `seq $EthNums`;do
            printf "%-25s" "$(eval echo -e \${Eth$(($i-1))[$n]})";
        done
        [ "$n" -ne 2 ] && echo
    done
}

CheckSys() { 
    PrintOut "SystemInfo"
    lsb_release -idr; 
}

CheckAll() {
    CheckProductInfo
    CheckCpu
    CheckMemory
    CheckDisk
    CheckNetwork
    CheckSys
}



case $1 in 
    -p|-P) CheckProductInfo ;;
    -c|-C) CheckCpu ;;
    -m|-M) CheckMemory ;;
    -n|-N) CheckNetwork ;;
    -d|-D) CheckDisk ;;
    -s|-S) CheckSys ;;
       '') CheckAll ;;
        *) Usage ;;
esac
echo 
