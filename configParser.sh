#!/bin/bash
#Shell版ConfigParser
##################################################
## Author     :  Dragon
## Create Date:  2010-01-14
## Modify Date:  2011-12-15 16:00
##################################################

##########################################################################################################
##########################################################################################################
######config文件格式如下:								            ######
######[apache]										            ######
######_SerName=apache									            ######
######_SerSourcePath=/data/src/LAMP/httpd-2.2.11					            ######
######_SerInsPath=/usr/local								            ######
######_apacheData=/usr/local/apache/conf/httpd.conf,/usr/local/apache/htdocs		            ######
######  										            ######
######  										            ######
######"[模块名]"下面的内容为对应模块的配置信息      			         	            ######
######允许有以"#"开头的注释行 								            ######
######建议不同模块下的变量使用不同的名称避免冲突，如果使用函数_SetVarAuto会导致同名变量值被覆盖     ######
##########################################################################################################
##########################################################################################################


#------------------------------  函数定义 ------------------------------

#分析配置文件内容
ConfigParser(){
  local _ConfigFile=$1
  _Modules=`awk '/^\[[^\/]/{gsub(/\[|].*|#.*/,"");print}' $_ConfigFile`
  _Awk(){
      local module=$1
      awk 'BEGIN{ORS="\t"}/\['$module'/{
	    getline;while($0!~/^\[/){if($0!~/^#|^$/){gsub(/#.*/,"");gsub(/^|$/,"\"");print $0};if(! getline || $0~/^\[/){exit;}}
	  }' $_ConfigFile
  }
  _ChkConfigFile(){
      for i in $_Modules;do
  	  local vars="`_Awk $i`"
  	  if [ -z "$vars" ]; then echo " Please check module: [$i]";exit 1; fi
      done
  }
  _ReadConfig() {
      for j in $_Modules;do eval ${j}_Array=\(`_Awk $j`\); done
  }

  _ChkConfigFile
  _ReadConfig
}

#生成变量，将指定的模块的配置转换成变量
_SetVar(){
  local module=$1
  local num=`eval echo \$\{\#${module}_Array[@]\}`
  for((h=0;h<$num;h++));do
      export `eval echo \$\{${module}_Array\[$h\]\}|awk '{gsub(/[[:blank:]]/,"");print}'`
      eval ${module%_*}_VarName[$h]=\$\{${module}_Array\[$h\]%=*\}
  done
}

#生成变量，将所有的模块的配置转换成变量
_SetVarAuto(){
  local h module
  for module in $_Modules;do
    local num=`eval echo \$\{\#${module}_Array[@]\}`
    for((h=0;h<$num;h++));do
        export `eval echo \$\{${module}_Array\[$h\]\}|awk '{gsub(/[[:blank:]]/,"");print}'`
        eval ${module%_*}_VarName[$h]=\$\{${module}_Array\[$h\]%=*\}
    done
  done
}

#------------------------------  函数定义 ------------------------------

 
#以下为程序执行部分
_File=ini
ConfigParser $_File

_DisplayModules() {
  for i in $_Modules;do
    echo "Module: $i"
  done
}

_DisplayModulesConf() {
  local i j
  for i in $_Modules;do
    echo "[$i]"
    local num=`eval echo \$\{\#${i}_Array[@]\}`
    for((j=0;j<$num;j++));do
      echo -n "  "
      eval echo \$\{${i}_Array[j]\}
    done
  done
}

#以下为输出测试 
#[在调用完函数ConfigParser、_SetVar、_SetVarAuto后，会生成:
#变量:"_Modules"	(由ConfigParser函数生成，存储所有的模块名)
#数组:"模块名_Array"	(由ConfigParser函数生成，存储对应模块的配置)
#数组:"模块名_VarName"	(由_SetVar函数生成，存储对应模块相关的选项名，也即变量名)
#变量:模块下配置对应的变量 (调用_SetVar/_SetVarAuto函数后会根据配置文件生成)

#使用方法一：
_Example1() {
  echo -e "\n=== Example 1 ==="
  for i in "apache" "mysql" "test"; do
    :|{
      _SetVar "$i"
      echo -e "\n[module $i]"
      printf "  %-15s : %s\n" "_SerName" $_SerName
      printf "  %-15s : %s\n" "_SerSourcePath" $_SerSourcePath
      printf "  %-15s : %s\n" "_SerInsPath" $_SerInsPath
      printf "  %-15s : %s\n" "_${i}Data" $(eval echo "\$_${i}Data")
      printf "  %-15s : %s\n" "test123" ${test123:=None}
    }
  done
}

#使用方法二：
_Example2() {
  echo -e "\n==== Example 2 ===="
  for i in $_Modules; do
    :|{
      _SetVar "$i"
      echo -e "\n[module $i]"
      for x in `eval echo \$\{${i}_VarName[@]\}`;do
        value=$(eval echo "\$$x")
        printf "  %-15s : %s\n" $x $value
      done
    }
  done
}

#使用方法三：
_Example3() {
  echo -e "\n==== Example 3 ===="
  for i in $_Modules; do
    _SetVar "$i"
    echo -e "\n[module $i]"
    for x in `eval echo \$\{${i}_VarName[@]\}`;do
      value=$(eval echo "\$$x")
      printf "  %-15s : %s\n" $x $value
    done
  done
}

_Usage() {
  echo 
  echo "  $0 <E1|E2|E3|DM|DMC|SVA>"
  echo 
  echo "    E1|e1    _Example1 "
  echo "    E2|e2    _Example2 "
  echo "    E3|e3    _Example3"
  echo "    DM|dm    _DisplayModules"
  echo "    DMC|dmc  _DisplayModulesConf"
  echo "    SVA|sva  _SetVarAuto"
  echo 
  
  exit 1
}

if [[ $# != 1 ]];then 
  _Usage
fi

case $1 in
  E1|e1) _Example1 ;;
  E2|e2) _Example2 ;;
  E3|e3) _Example3 ;;
  DM|dm) _DisplayModules ;;
  DMC|dmc) _DisplayModulesConf ;;
  SVA|sva) _SetVarAuto ; echo "ENV:";env 2>&1 |grep "^_" ;;
  *) _Usage ;;
esac
  
