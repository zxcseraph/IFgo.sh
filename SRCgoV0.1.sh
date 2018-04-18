#!/bin/bash

################log4s配置区#################
log4spath=`pwd`								#输出日志目录
log4sCategory=debug					#输出日志级别名称，级别按照debug=0，warn=1，info=2，error=3
logs4logname=root.log					#输出日志名称
isecho=0											#输出到日志的同时是否打印到屏幕，0是不打印，1是打印
splittype=none								#日志分割方式，none不分割，day按照日期分割后缀名为YYYY-MM-DD，num为按照行模式分割，如果使用num模式则必须填写splitnum参数，这个没思路暂不支持
splitnum=1000


################log4s配置校验并初始化区，单独拿出来是为初始化只需要一次#############
log4scheck()
{
	if [ X$log4spath = X ]
	then
		echo "log4spath参数需要配置"
		exit 1;
	fi
	if [ X$log4sCategory = X ]
	then
		echo "log4sCategory参数需要配置"
		exit 1;
	fi
	if [ X$logs4logname = X ]
	then
		echo "logs4logname参数需要配置"
		exit 1;
	fi
	if [ X$isecho = X ]
	then
		echo "isecho参数需要配置"
		exit 1;
	fi
	if [ X$splittype = X ]
	then
		echo "splittype参数需要配置"
		exit 1;
	fi
	if [ X$splittype = Xnum ]
	then
		if [ X$splitnum = X ]
		then
			echo "splitnum参数需要配置"
			exit 1;
		fi
	fi
	log4sCategoryToU=`echo $log4sCategory|tr '[a-z]' '[A-Z]'`
	case $log4sCategoryToU in
		DEBUG)
			log4sCategorylevel=0
			;;
		WARN)
			log4sCategorylevel=1
			;;
		INFO)
			log4sCategorylevel=2
			;;
		ERROR)
			log4sCategorylevel=3
			;;
		*)
			log4sCategorylevel=3
			;;
	esac
}
################log4s代码区#################
log4slog=${log4spath}/${logs4logname}
log4scheck;
log4s()                       #$1是级别，$2是内容
{
	nowdate=`date +"%Y-%m-%d %H:%M:%S"`
	######判断区域，保证参数严谨性
	#判断目录及日志文件，不自动创建目录，但是会自动创建文件
	if [ ! -d $log4spath ]
	then
		echo "$nowdate log4s配置的目录不存在，请确认配置是否正确"
		exit 1;
	fi
	if [ ! -f $log4slog ]
	then
		echo "$nowdate $logname不存在，创建log4s日志文件"
		echo "$nowdate $logname不存在，创建log4s日志文件" >> $log4slog
	fi
	
	#判断参数个数
	if [ $# -ne 2 ]
	then
		echo "参数个数为2个"
		exit 1;
	fi
	log4sindex=0
	
	###分割日志区
	#按日分割
	if [ $splittype = day ]
	then
		lastlineday=`tail -1 $log|awk  '{print $1}'`
		if [ X$lastlineday = X ]
		then
			lastlineday=`tail -2 $log|head -1|awk  '{print $1}'`
			if [ X$lastlineday = X ]
			then
				lastlineday=`tail -3 $log|head -1|awk  '{print $1}'`
			fi
		fi
		nowday=`echo $nowdate|awk '{print $1}'`
		if [ X$lastlineday != X$nowday ] && [ X$lastlineday != X ]
		then
			mv ${log4slog} ${log4slog}.$lastlineday
			touch $log4slog
		fi
	fi
	#按行数分割
	if [ $splittype = num ]
	then
		if [ ! -f $log4slog ]
		then
			echo "日志文件不存在，请检查配置是否正确"
			exit 1;
		fi
		lognum=`wc -l $log4slog|awk '{print $1}'`
		if [ $lognum -ge $splitnum ]
		then
			temptag=`date +"%Y%m%d%H%M%S"`
			mv ${log4slog} ${log4slog}.${temptag}
			touch $log4slog
		fi
	fi

	######功能区域
	log4sinlevel=`echo $1|tr '[a-z]' '[A-Z]'`
	case $log4sinlevel in
		DEBUG)
			log4snowlevel=0
			;;
		WARN)
			log4snowlevel=1
			;;
		INFO)
			log4snowlevel=2
			;;
		ERROR)
			log4snowlevel=3
			;;
		*)
			log4snowlevel=3
			;;
	esac
	if [ $log4snowlevel -ge $log4sCategorylevel ]
	then
		if [ $isecho = 1 ]
		then
			echo "$nowdate log4s.${log4sinlevel}   $2"
		fi
		echo "$nowdate log4s.${log4sinlevel}   $2" >> $log4slog
	fi
}


X86=`uname -m`
XITONG=`echo $(uname)|tr '[a-z]' '[A-Z]'`  #系统类型
xtong=`echo $(uname)|tr '[A-Z]' '[a-z]'`
XTBANBEN=`cat /etc/issue|head -1|awk '{print $7}'`  #获取系统版本
tXTBB=$(echo $XTBANBEN |awk '{print $1*100}')

if [ $# = 0 ]
then
	echo "启动需要参数，install，进行安装，具体配置请详细阅读配置区"
	echo "SecureCRT need defult"
	echo "ru guo zhong wen luan ma ,qing geng gai SecureCRT bian ma wei defult"
	exit 0;
fi


if [ $XITONG = "LINUX" ]
then
	envprofile='.bash_profile'
else
	envprofile='.profile'
fi
#############参数解析：1.系统类型（SCPAS/CLAS/SCIM），2.主机类型（BEP/SIP/MS/RS/DB），3.IP地址（XXX.XXX.XXX.XXX），4.统一账户密码，5.网管主机IP
#SYSTYPE=`echo $1|tr '[a-z]' '[A-Z]'`
#HOSTYPE=`echo $2|tr '[a-z]' '[A-Z]'`
#IPADDR=$3
#PASSWD=$4
#ALARMIP="$5:3000"



##bep安装需要7个参数分别为：环境变量文件名、DOMAINID、CLUSTER、网管ip、INFORMIXDIR、INFORMIXSERVER、ONCONFIG
fun_bepinstall() {
if [ $# != 7 ]
then
log4s error "后台安装参数数量错误！后台安装失败"
exit 1
fi
cd $HOME
mkdir cin
log4s info "开始解压后台软件包"
gzNum=`ls|grep gz$|wc -l`
zipNum=`ls|grep zip$|wc -l`
tarNum=`ls|grep tar$|wc -l`
if [ $gzNum -gt 0 ]
then
	ls *.tar.gz | xargs -n1 tar xzf
elif [ $zipNum -gt 0 ]
then
	ls *.zip | xargs -n1 unzip
elif [ $tarNum -gt 0 ]
then
	ls *.tar | xargs -n1 tar xf
else
	log4s error "找不到相应的后台软件包！安装后台失败"
	exit 1
fi
pacname=`ls|grep Package|grep -v tar|grep -v gz|grep -v zip|grep -v bak`
if [[ X$pacname = X ]]
then
	log4s error "Package文件夹不存在，请确保解压后的Package*文件夹在\$HOME中"
	exit 1
fi
cat $HOME/Package*/profile >> $HOME/$1
sed -i "s/^INFORMIXDIR.*/INFORMIXDIR=$5/g" $HOME/$1
sed -i "s/^INFORMIXSERVER.*/INFORMIXSERVER=$6/g" $HOME/$1
sed -i "s/^ONCONFIG.*/ONCONFIG=$7/g" $HOME/$1
sed -i "s/^DOMAINID.*/DOMAINID=$2/g" $HOME/$1
echo "CLUSTER=$3" >> $HOME/$1
echo 'export CLUSTER' >> $HOME/$1
echo 'ulimit -c 2' >> $HOME/$1
log4s info "后台环境变量配置完成"
. $HOME/$1
log4s info "开始安装后台"
$HOME/Package*/makefifo
cp $HOME/Package*/install.sc $HOME 
chmod +x $HOME/install.sc
sleep 5
log4s info "开始编译后台"
$HOME/install.sc -all $pacname << EOF
0
i
i
y
EOF
if [ $? -eq 0 ]
then
log4s info "后台编译成功"
else
log4s error "后台编译失败"
fi
sed -i "1s/SERVER.*/SERVER=$4:3000/" $CINDIR/etc/alarm.bep
sed -i "s/<addr.*port=\"1500\".*/<addr ip=\"$4\" port=\"1500\"\/>/" $CINDIR/etc/config.ne
log4s info "后台安装完成，请手工修改SDFDB、SMPDB环境变量和config.comm、config.manager、sync.conf、config.sys配置文件"
}

##sip安装需要4个参数分别为：环境变量文件名、SIPDOMAINID、CLUSTER、网管IP
fun_sipinstall() {
if [ $# != 4 ]
then
	log4s error "sip安装参数数量错误！sip安装失败"
	exit 1
fi
echo 'SIPDIR=$HOME/sipserver' >> $1
echo 'PATH=$PATH:$SIPDIR/bin' >> $1
echo "SIPDOMAINID=$2" >> $1
echo "CLUSTER=$3" >> $1
echo 'export  SIPDIR PATH SIPDOMAINID CLUSTER' >> $1
log4s info "sip环境变量配置完成"
cd $HOME
. $HOME/$1
log4s info "开始解压sip软件包"
gzNum=`ls|grep gz$|wc -l`
zipNum=`ls|grep zip$|wc -l`
tarNum=`ls|grep tar$|wc -l`
if [ $gzNum -gt 0 ]
then
	ls *.tar.gz | xargs -n1 tar xzf
elif [ $zipNum -gt 0 ]
then
	ls *.zip | xargs -n1 unzip
elif [ $tarNum -gt 0 ]
then
	ls *.tar | xargs -n1 tar xf
else
	log4s error "找不到相应的sip软件包！sip安装失败"
	exit 1
fi
if [[ ! -d "sipserver" ]]
then
	log4s error "sipserver文件夹不存在，请确保解压后的sipserver文件夹在\$HOME中"
	exit 1
fi
log4s info "开始安装sip"
chmod +x $HOME/sipserver/bin/sipmake
sleep 5
log4s info "开始编译sip"
sipmake
if [ $? -eq 0 ]
then
log4s info "sip编译成功"
else
log4s error "sip编译失败"
fi
chmod +x $HOME/sipserver/bin/*
sed -i "s/<inmsAlarmServer.*/<inmsAlarmServer ip=\"$4\" port=\"3000\"\/>/g" $HOME/sipserver/etc/config.alarm
log4s info "sip安装完成，请手工修改config.sipserver和config.comm配置文件"
}

##gealarm安装需要5个或7个参数分别为：环境变量文件名、DOMAINID、CLUSTER、网管ip端口、root密码、可选(INFORMIXDIR、INFORMIXSERVER)
fun_geinstall() {
if [ $# == 5 ]
then
	echo 'CINDIR=$HOME/genalarm' >> $1
	echo 'PATH=$PATH:.:$CINDIR/bin:/usr/vacpp/bin' >> $1
	echo "CLUSTER=$3" >> $1
	echo "DOMAINID=$2" >> $1
	echo 'export CINDIR PATH CLUSTER DOMAINID' >> $1
	geType='noDB'
	log4s info "gealarm环境变量配置完成"
elif [ $# == 7 ]
then
	echo "INFORMIXDIR=$6" >> $1 
	echo "INFORMIXSERVER=$7" >> $1
	echo 'PATH=$PATH:$INFORMIXDIR/bin:$INFORMIXDIR/lib/esql' >> $1
	echo 'LD_LIBRARY_PATH=$INFORMIXDIR/lib:$INFORMIXDIR/lib/esql:/usr/local/lib' >> $1
	echo 'export INFORMIXDIR PATH INFORMIXSERVER LD_LIBRARY_PATH' >> $1
	echo 'CINDIR=$HOME/genalarm' >> $1
	echo 'PATH=$PATH:.:$CINDIR/bin:/usr/vacpp/bin' >> $1
	echo "CLUSTER=$3" >> $1
	echo "DOMAINID=$2" >> $1
	echo 'export CINDIR PATH CLUSTER DOMAINID' >> $1
	geType='DB'
	log4s info "gealarm环境变量配置完成"
else
	log4s error "gealarm安装参数数量错误！gealarm安装失败"
	exit 1	
fi
cd $HOME
. $HOME/$1
log4s info "开始解压gealarm软件包"
gzNum=`ls|grep gz$|wc -l`
zipNum=`ls|grep zip$|wc -l`
tarNum=`ls|grep tar$|wc -l`
if [ $gzNum -gt 0 ]
then
	ls *.tar.gz | xargs -n1 tar xzf
elif [ $zipNum -gt 0 ]
then
	ls *.zip | xargs -n1 unzip
elif [ $tarNum -gt 0 ]
then
	ls *.tar | xargs -n1 tar xf
else
	log4s error "找不到gealarm软件包，安装gealarm失败"
	exit 1
fi
if [[ ! -d "genalarm" ]]
then
	log4s error "genalarm文件夹不存在，请确保解压后的genalarm文件夹在\$HOME中"
	exit 1
fi
log4s info "开始安装gealarm"
cd $CINDIR/src
sleep 5
log4s info "开始编译gealarm"
makeall $geType
if [ $? -eq 0 ]
then
log4s info "gealarm编译成功"
else
log4s error "gealarm编译失败"
fi
chmod +x $HOME/genalarm/bin/*
sed -i "1s/.*/SERVER=$4/" $CINDIR/etc/config.alarm
sed -i "s/<subnet name=\"ckpro\" fe=\"checkpro\".*/<subnet name=\"ckpro\" fe=\"checkpro\" startinstance=\"1\" number=\"1\" initialnumber=\"1\" \/>/g" $CINDIR/etc/config.comm
if [ $# == 7 ]
then
	sed -i "s/<subnet name=\"ckDB\" fe=\"checkDB\".*/<subnet name=\"ckDB\" fe=\"checkDB\" startinstance=\"1\" number=\"1\" initialnumber=\"1\" \/>/g" $CINDIR/etc/config.comm
fi
log4s info "添加日志文件可读权限"
if [ $XITONG = "LINUX" ]
then
/usr/bin/expect <<-EOF
set timeout 5
spawn su - root
expect "*password:"
send "$5\r"
expect {
"*>" {}
"*]" {}
}
send "chmod +x /home/*;chmod 644 /var/log/messages\r"
expect {
"*>" {}
"*]" {}
}
send "exit\r"
expect eof
EOF
elif [ $XITONG = "AIX" ]
then
/usr/bin/expect <<-EOF
set timeout 5
spawn su - root
expect "*password:"
send "$5\r"
expect {
"*>" {}
"*]" {}
}
send "chmod +rx /usr/bin/svmon;chmod u+s /usr/bin/svmon;chmod +r /var/spool/mail/root\r"
expect {
"*>" {}
"*]" {}
}
send "exit\r"
expect eof
EOF
elif [ $XITONG = "HPUX" ]
then
/usr/bin/expect <<-EOF
set timeout 5
spawn su - root
expect "*password:"
send "$5\r"
expect {
"*>" {}
"*]" {}
}
send "chmod +r /var/adm/syslog/syslog.log;chmod +r /var/mail/root\r"
expect {
"*>" {}
"*]" {}
}
send "exit\r"
expect eof
EOF
fi
if [ $# == 7 ]
then
log4s info "请手工给gealarm账户添加dbaccess权限"
fi
log4s info "gealarm安装完成"
}

##omsan安装需要4个或6个参数分别为：环境变量文件名、CLUSTER、网管ip（不包含端口）、root密码、可选(INFORMIXDIR、INFORMIXSERVER)
fun_aninstall() {
if [ $# == 4 ]
then
	echo '########OMS########' >> $1
	echo 'export OMSDOMAINID=3' >> $1
	echo 'export OMSDIR=$HOME/oms' >> $1
	echo "export CLUSTER=$2" >> $1
	echo 'export PATH=$PATH:$OMSDIR/bin:/usr/bin:/usr/local/bin:/usr/sbin:/sbin' >> $1
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$OMSDIR/lib' >> $1
	echo 'export LANG=zh_CN.GB18030' >> $1
	log4s info "omsan环境变量配置完成"
elif [ $# == 6 ]
then
	echo '########INFORMIX########' >> $1 
	echo "export INFORMIXDIR=$5" >> $1
	echo "export INFORMIXSERVER=$6" >> $1
	echo 'export LD_LIBRARY_PATH=$INFORMIXDIR/lib:$INFORMIXDIR/lib/esql' >> $1
	echo 'export INFORMIXCONTIME=2' >> $1
	echo 'export INFORMIXCONRETRY=1' >> $1
	echo 'export PATH=$PATH:$INFORMIXDIR/bin:$INFORMIXDIR/lib/esql' >> $1
	echo '########OMS########' >> $1
	echo 'export OMSDOMAINID=3' >> $1
	echo 'export OMSDIR=$HOME/oms' >> $1
	echo "export CLUSTER=$2" >> $1
	echo 'export PATH=$PATH:$OMSDIR/bin:/usr/bin:/usr/local/bin:/usr/sbin:/sbin' >> $1
	echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$OMSDIR/lib' >> $1
	echo 'export LANG=zh_CN.GB18030' >> $1
	log4s info "omsan环境变量配置完成"
else
	log4s error "omsan安装参数数量错误！omsan安装失败"
	exit 1
fi
cd $HOME
. $HOME/$1
log4s info "开始解压omsan软件包"
gzNum=`ls|grep gz$|wc -l`
zipNum=`ls|grep zip$|wc -l`
tarNum=`ls|grep tar$|wc -l`
if [ $gzNum -gt 0 ]
then
	ls *.tar.gz | xargs -n1 tar xzf
elif [ $zipNum -gt 0 ]
then
	ls *.zip | xargs -n1 unzip
elif [ $tarNum -gt 0 ]
then
	ls *.tar | xargs -n1 tar xf
else
	log4s error "找不到omsan软件包，安装omsan失败"
	exit 1
fi
ansrcDir=`ls|grep ^oms|grep -v tar|grep -v gz|grep -v zip`
mv $ansrcDir oms
if [[ ! -d "oms" ]]
then
	log4s error "oms文件夹不存在，请确保解压后的oms文件夹在\$HOME中"
	exit 1
fi
log4s info "开始安装omsan"
sed -i "1s/.*/SERVER=$3:3000/" $OMSDIR/etc/alarmcfg
sed -i "/<process feId=\"230\"/{n;n;s/<serverAddr>.*/<serverAddr>$3<\/serverAddr>/g}" $OMSDIR/etc/config.outcomm
sed -i "s/<Subsystem>.*/<Subsystem>agent<\/Subsystem>/g" $OMSDIR/etc/config.oms
sleep 5
config << EOF
1
EOF
build -nc
if [ $? -eq 0 ]
then
log4s info "omsan编译成功"
else
log4s error "omsan编译失败"
fi
if [ $XITONG = "LINUX" ]
then
/usr/bin/expect <<-EOF
set timeout 5
spawn su - root
expect "*password:"
send "$4\r"
expect {
"*>" {}
"*]" {}
}
send "cd /home/omsan/oms/bin;chown root:root superexe;chmod 6755 superexe\r"
expect {
"*>" {}
"*]" {}
}
send "exit\r"
expect eof
EOF
elif [ $XITONG = "AIX" ]
then
/usr/bin/expect <<-EOF
set timeout 5
spawn su - root
expect "*password:"
send "$4\r"
expect {
"*>" {}
"*]" {}
}
send "cd /home/omsan/oms/bin;chown root:system superexe;chmod 6755 superexe\r"
expect {
"*>" {}
"*]" {}
}
send "exit\r"
expect eof
EOF
fi
log4s info "omsan安装完成"
}

##pfmcapi安装需要1个参数环境变量文件名
fun_pfmcinstall() {
if [ $# != 1 ]
then
log4s error "pfmcapi安装参数数量错误！后台安装失败"
exit 1
fi
echo 'PFMCAPIDIR=$HOME/pfmcapi' >> $1
echo 'export PFMCAPIDIR' >> $1
echo 'LD_LIBRARY_PATH=$PFMCAPIDIR/lib:$LD_LIBRARY_PATH' >> $1
echo 'export LD_LIBRARY_PATH' >> $1
echo 'LIBPATH=$PFMCAPIDIR/lib:$LIBPATH' >> $1
echo 'export LIBPATH' >> $1
log4s info "pfmcapi环境变量配置完成"
cd $HOME
. $HOME/$1
if [[ ! -d "pfmcapi" ]]
then
	log4s error "pfmcapi文件夹不存在，请确保解压后的pfmcapi文件夹在\$HOME中"
	log4s error "pfmcapi安装失败"
	exit 1
fi
log4s info "开始安装pfmcapi"
cd $PFMCAPIDIR/src/
make
if [ $? -eq 0 ]
then
log4s info "pfmcapi编译成功"
else
log4s error "pfmcapi编译失败"
fi
cd $HOME
cd ..
chmod a+x omsan
cd $HOME
if [ $XITONG = "LINUX" ]
then
chmod 777 -R pfmcapi
elif [ $XITONG = "HPUX" ]
then
chmod -R 777 pfmcapi
fi
log4s info "pfmcapi安装成功"
}

##alarmAPI安装需要3个参数分别为：环境变量文件名、CLUSTER、网管ip端口
fun_apiinstall()
{
if [ $# == 3 ]
then
	sed -i "s/^PATH.*/&:./g" $1
	log4s info "alarmAPI环境变量配置完成"
else
	log4s error "alarmAPI安装参数数量错误！alarmAPI安装失败"
	exit 1	
fi
cd $HOME
. $HOME/$1
tarNum=`ls|grep alarmAPI.tar|wc -l`
if [ $tarNum -eq 0 ]
then
	log4s error "找不到alarmAPI软件包，安装alarmAPI失败"
	exit 1
fi
cp $HOME/alarmAPI.tar $INFORMIXDIR/
cd $INFORMIXDIR
ls alarmAPI.tar | xargs -n1 tar xf
if [[ ! -d "$INFORMIXDIR/alarmAPI" ]]
then
	log4s error "alarmAPI文件夹不存在，请确保解压后的galarmAPI文件夹在\$INFORMIXDIR中"
	exit 1
fi
log4s info "开始安装alarmAPI"
cd $INFORMIXDIR/alarmAPI
sleep 5
log4s info "开始编译alarmAPI"
make -f makefile.$xtong
if [ $? -eq 0 ]
then
log4s info "alarmAPI编译成功"
else
log4s error "alarmAPI编译失败"
fi
log4s info "开始修改alarmAPI配置文件"
sed -i "s/^SERVER.*/SERVER=$3/g" $INFORMIXDIR/alarmAPI/alarmcfg
sed -i "29a\CLUSTER=$2\nexport CLUSTER" $INFORMIXDIR/alarmAPI/log_full.sh
sed -i "s/^instance.*/instance=\'$HOSTNAME.$2.DB\'/g" $INFORMIXDIR/alarmAPI/log_full.sh
sed -i "s!^ALARMPROGRAM.*!ALARMPROGRAM    ${INFORMIXDIR}/alarmAPI/log_full.sh!g" $INFORMIXDIR/etc/$ONCONFIG
chmod +x $INFORMIXDIR/alarmAPI/log_full.sh
log4s info "alarmAPI配置文件修改完成"
log4s info "alarmAPI安装完成"
}

##n7server安装需要3个参数分别为：环境变量文件名、CLUSTER、网管ip端口
fun_ss7install() {
if [ $# != 3 ]
then
	log4s error "n7server安装参数数量错误！n7server安装失败"
	exit 1
fi
cd $HOME
log4s info "开始解压n7server软件包"
gzNum=`ls|grep gz$|wc -l`
zipNum=`ls|grep zip$|wc -l`
tarNum=`ls|grep tar$|wc -l`
if [ $gzNum -gt 0 ]
then
	ls *.tar.gz | xargs -n1 tar xzf
elif [ $zipNum -gt 0 ]
then
	ls *.zip | xargs -n1 unzip
elif [ $tarNum -gt 0 ]
then
	ls *.tar | xargs -n1 tar xf
else
	log4s error "找不到n7server软件包，安装n7server失败"
	exit 1
fi
if [[ ! -d "No7_IPS_n7server" ]]
then
	log4s error "No7_IPS_n7server文件夹不存在，请确保解压后的No7_IPS_n7server文件夹在\$HOME中"
	exit 1
fi
cd $HOME/No7_IPS_n7server
sleep 5
log4s info "开始安装n7server"
./install -all <<-EOF
y
s
n
n
y
EOF
if [ $? -eq 0 ]
then
log4s info "n7server编译成功"
else
log4s error "n7server编译失败"
fi
log4s info "开始修改环境变量及配置文件"
sed -i "s/CLUSTER.*/CLUSTER=$2/g" $HOME/$1
. $HOME/$1
sed -i "s/SERVER.*/SERVER=$3/" $CINDIR/etc/config.udp.alarm
log4s info "n7server安装完成，请手工修改N7SERVERNUM环境变量和config.n7server配置文件"
}

fun_ftphost()#####需要参数主机类型HOSTYPE，IP地址IPADDR，统一账户密码PASSWD
{
if [ $1 = SIP ]
then
srcFile=`ls sip/* gealarm/* omsan/*`
elif [ $1 = BEP ]
then
srcFile=`ls min/* gealarm/* omsan/*`
elif [ $1 = DB ]
then
srcFile=`ls informix/* gealarm/* omsan/*`
elif [ $1 = SS7 ]
then
srcFile=`ls ss7/*`
fi
for file in $srcFile
do
userName=`echo $file|awk -F "/" '{print $1}'`
log4s info "开始上传$userName代码以及本脚本至$2"
/usr/bin/expect <<-EOF
set timeout 60
spawn scp -oPort=19222 -r $file $userName@$2:./
expect {
"*yes/no" { send "yes\r"; exp_continue }
"*password:" { send "$3\r" }
}
expect eof
EOF
/usr/bin/expect <<-EOF
set timeout 60
spawn scp -oPort=19222 -r $0 $userName@$2:./
expect {
"*yes/no" { send "yes\r"; exp_continue }
"*password:" { send "$3\r" }
}
expect eof
EOF
log4s info "完成上传$userName代码以及本脚本至$2"
done
}


fun_install()
{
ANSWER=n
while [ "$ANSWER" != "y" -a "$ANSWER" != "Y" ]
do
	echo -e "请输入您想安装的系统类型（SCPAS/CLAS/SCIM）：\c"
	read SYSTYPE
	SYSTYPE=`echo $SYSTYPE|tr '[a-z]' '[A-Z]'`
	while [ $SYSTYPE != "SCPAS" -a $SYSTYPE != "CLAS" -a $SYSTYPE != "SCIM" ] 
	do
		echo -e "请输入正确的系统类型（SCPAS/CLAS/SCIM）：\c"
		read SYSTYPE
		SYSTYPE=`echo $SYSTYPE|tr '[a-z]' '[A-Z]'`
	done
	case $SYSTYPE in
	SCPAS)
		echo -e "请按顺序输入您想安装SIP软件的主机IP地址，多台主机请用空格隔开（如10.175.48.1 10.175.48.2 10.175.48.3）：\c"
		read -a ARRAY_SIPADDR
		echo -e "请按顺序输入您想安装后台软件的主机IP地址，多台主机请用空格隔开（如10.175.48.4 10.175.48.5 10.175.48.6）：\c"
		read -a ARRAY_BEPADDR
		echo -e "请按顺序输入您想安装MS软件的主机IP地址，多台主机请用空格隔开（如10.175.48.7 10.175.48.8）：\c"
		read -a ARRAY_MSADDR
		echo -e "请按顺序输入您数据库主机IP地址，多台主机请用空格隔开（如10.175.48.9 10.175.48.10）：\c"
		read -a ARRAY_DBADDR
		;;
	CLAS)
		echo -e "请按顺序输入您想安装SIP软件的主机IP地址，多台主机请用空格隔开（如10.175.48.1 10.175.48.2 10.175.48.3）：\c"
		read -a ARRAY_SIPADDR
		echo -e "请按顺序输入您想安装后台软件的主机IP地址，多台主机请用空格隔开（如10.175.48.4 10.175.48.5 10.175.48.6）：\c"
		read -a ARRAY_BEPADDR
		echo -e "请按顺序输入您想安装MS软件的主机IP地址，多台主机请用空格隔开（如10.175.48.7 10.175.48.8）：\c"
		read -a ARRAY_MSADDR
		echo -e "请按顺序输入您RS主机IP地址，多台主机请用空格隔开（如10.175.48.11 10.175.48.12）：\c"
		read -a ARRAY_RSADDR
		echo -e "请按顺序输入您数据库主机IP地址，多台主机请用空格隔开（如10.175.48.9 10.175.48.10）：\c"
		read -a ARRAY_DBADDR
		;;
	SCIM)
		echo -e "请按顺序输入您想安装SIP软件的主机IP地址，多台主机请用空格隔开（如10.175.48.1 10.175.48.2 10.175.48.3）：\c"
		read -a ARRAY_SIPADDR
		echo -e "请按顺序输入您想安装后台软件的主机IP地址，多台主机请用空格隔开（如10.175.48.4 10.175.48.5 10.175.48.6）：\c"
		read -a ARRAY_BEPADDR
		echo -e "请按顺序输入您数据库主机IP地址，多台主机请用空格隔开（如10.175.48.9 10.175.48.10）：\c"
		read -a ARRAY_DBADDR
		;;
	*)
		echo "系统类型错误"
		exit 1
	esac
	echo -e "请输入您即将新建系统informix客户端的INFORMIXDIR（如/home/informix）：\c"
	read INFDIR
	echo -e "请输入您即将新建系统informix服务端的INFORMIXDIR（如/ids）：\c"
	read DBDIR
	echo -e "请输入您即将新建系统的INFORMIXSERVER（如db11）：\c"
	read INFSER
	echo -e "请输入您即将新建系统的数据库ONCONFIG文件名（如onconfig.hdr11）：\c"
	read INFCONF
	echo -e "请输入您即将新建系统的集群名称：\c"
	read CLUSTER
	echo -e "请输入您即将新建系统的密码（该系统所有主机账户密码统一）：\c"
	read PASSWD
	echo -e "请输入您网管主机IP地址：\c"
	read OMSIP
	
	echo "请确认您的选择"
	echo "##################################################################################################"
		echo "系统类型          = $SYSTYPE"
	case $SYSTYPE in
	SCPAS)
		echo "SIP主机IP地址     = ${ARRAY_SIPADDR[*]}"
		echo "后台主机IP地址    = ${ARRAY_BEPADDR[*]}"
		echo "MS主机IP地址      = ${ARRAY_MSADDR[*]}"
		echo "数据库主机IP地址  = ${ARRAY_DBADDR[*]}"
		;;
	CLAS)
		echo "SIP主机IP地址     = ${ARRAY_SIPADDR[*]}"
		echo "后台主机IP地址    = ${ARRAY_BEPADDR[*]}"
		echo "MS主机IP地址      = ${ARRAY_MSADDR[*]}"
		echo "RS主机IP地址      = ${ARRAY_RSADDR[*]}"
		echo "数据库主机IP地址  = ${ARRAY_DBADDR[*]}"
		;;
	SCIM)
		echo "SIP主机IP地址     = ${ARRAY_SIPADDR[*]}"
		echo "后台主机IP地址    = ${ARRAY_BEPADDR[*]}"
		echo "数据库主机IP地址  = ${ARRAY_DBADDR[*]}"
		;;
	esac
		echo "客户端INFORMIXDIR = $INFDIR"
		echo "服务端INFORMIXDIR = $DBDIR"
		echo "INFORMIXSERVER    = $INFSER"
		echo "ONCONFIG          = $INFCONF"
		echo "集群名称          = $CLUSTER"
		echo "所有账户统一密码  = $PASSWD"
		echo "网管主机IP地址    = $OMSIP"
		echo "##################################################################################################"
	echo -e "如果确认请输入Y或y：\c"
	read ANSWER
done

sipdomainid='118'
for sipaddr in ${ARRAY_SIPADDR[@]}
do
	fun_ftphost SIP $sipaddr $PASSWD
	para[0]="sip $sipdomainid $CLUSTER $OMSIP"
	para[1]="omsan $CLUSTER $OMSIP $PASSWD"
	para[2]="gealarm 16 $CLUSTER $OMSIP:3000 $PASSWD"
	i="0"
	for LOOP in sip omsan gealarm
	do
		log4s info "开始运行$LOOP@$sipaddr安装脚本"
		/usr/bin/expect <<-EOF
		set timeout 5
		spawn ssh -p 19222 $LOOP@$sipaddr
		expect {
		"*yes/no" { send "yes\r"; exp_continue }
		"*password:" { send "$PASSWD\r" }
		}
		expect {
		"*>" {}
		"*]" {}
		}
		send "nohup ./SRCgo.sh ${para[$i]} &\r"
		expect {
		"*>" {}
		"*]" {}
		}
		send "exit\r"
		expect eof
		EOF
		i=`expr $i + 1`
		sleep 13
		log4s info "$LOOP@$sipaddr安装结束"
	done
	sipdomainid=`expr $sipdomainid + 1`
done

bepdomainid='1'
for bepaddr in ${ARRAY_BEPADDR[@]}
do
	fun_ftphost BEP $bepaddr $PASSWD
	para[0]="min $bepdomainid $CLUSTER $OMSIP $INFDIR $INFSER $INFCONF"
	para[1]="omsan $CLUSTER $OMSIP $PASSWD"
	para[2]="gealarm 16 $CLUSTER $OMSIP:3000 $PASSWD"
	i="0"
	for LOOP in min omsan gealarm
	do
		log4s info "开始运行$LOOP@$bepaddr安装脚本"
		/usr/bin/expect <<-EOF
		set timeout 5
		spawn ssh -p 19222 $LOOP@$bepaddr
		expect {
		"*yes/no" { send "yes\r"; exp_continue }
		"*password:" { send "$PASSWD\r" }
		}
		expect {
		"*>" {}
		"*]" {}
		}
		send "nohup ./SRCgo.sh ${para[$i]} &\r"
		expect {
		"*>" {}
		"*]" {}
		}
		send "exit\r"
		expect eof
		EOF
		i=`expr $i + 1`
		sleep 13
		log4s info "$LOOP@$bepaddr安装结束"
	done
	bepdomainid=`expr $bepdomainid + 1`
done

for dbaddr in ${ARRAY_DBADDR[@]}
do
	fun_ftphost DB $dbaddr $PASSWD
	para[0]="informix $CLUSTER $OMSIP:3000"
	para[1]="omsan $CLUSTER $OMSIP $PASSWD $DBDIR $INFSER"
	para[2]="gealarm 16 $CLUSTER $OMSIP:3000 $PASSWD $DBDIR $INFSER"
	i="0"
	for LOOP in informix omsan gealarm
	do
		log4s info "开始运行$LOOP@$bepaddr安装脚本"
		/usr/bin/expect <<-EOF
		set timeout 5
		spawn ssh -p 19222 $LOOP@$dbaddr
		expect {
		"*yes/no" { send "yes\r"; exp_continue }
		"*password:" { send "$PASSWD\r" }
		}
		expect {
		"*>" {}
		"*]" {}
		}
		send "nohup ./SRCgo.sh ${para[$i]} &\r"
		expect {
		"*>" {}
		"*]" {}
		}
		send "exit\r"
		expect eof
		EOF
		i=`expr $i + 1`
		sleep 13
		log4s info "$LOOP@$bepaddr安装结束"
	done
done

if [ $SYSTYPE = "SCPAS" ]
then
for ss7addr in ${ARRAY_BEPADDR[@]}
do
	fun_ftphost SS7 $bepaddr $PASSWD
	parass7="ss7 $CLUSTER $OMSIP:3000"
	log4s info "开始运行ss7@$ss7addr安装脚本"
	/usr/bin/expect <<-EOF
	set timeout 5
	spawn ssh -p 19222 ss7@$ss7addr
	expect {
	"*yes/no" { send "yes\r"; exp_continue }
	"*password:" { send "$PASSWD\r" }
	}
	expect {
	"*>" {}
	"*]" {}
	}
	send "nohup ./SRCgo.sh ${parass7} &\r"
	expect {
	"*>" {}
	"*]" {}
	}
	send "exit\r"
	expect eof
	EOF
	log4s info "ss7@$ss7addr安装结束"
done
log4s info "SCPAS系统正在进行安装，稍后请查看各台主机运行结果"
elif [ $SYSTYPE = "CLAS" ]
then
	echo 2222
elif [ $SYSTYPE = "SCIM" ]
then
	log4s info "SCIM系统正在进行安装，稍后请查看各台主机运行结果"
fi	
}

###########核查其他账户软件安装是否执行完毕#####
######1.核查文件全路径；2.最后一行核查日志内容；3.循环次数；4.每次循环控制时间
checkprosess()
{
if [ ! -f "$1" ]
then
touch $1
chmod 777 $1
log4s info "创建文件$1"
fi
runntimes=0
while [ X"`tail -1 $1`" != X"$2" -a X"`tail -1 $1`" != X ]
do
	if [ $runntimes -lt $3 ]
	then
	sleep $4
	runntimes=`expr $runntimes + 1`
	log4s debug "第${runntimes}次循环"
	else
	log4s info "超出既定执行时间仍未开始运行程序，退出该脚本"
	exit 0
	fi
done
}

if [ $# = 1 -a $1 = install ]
then
	log4s debug "开始调用install函数"
	fun_install
	log4s debug "install函数运行完成"
elif [ $# = 4 -a $1 = sip ]
then
	log4s info "开始安装sip软件"
	log4s debug "开始调用checkprosess函数"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start sip install" >> /tmp/install.log
	log4s info "start sip install写入/tmp/install.log文件"
	log4s debug "开始调用sipinstall函数"
	fun_sipinstall $envprofile $2 $3 $4
	log4s info "install completed写入/tmp/install.log文件"
	echo "install completed" >> /tmp/install.log
	log4s info "sip软件安装完成"
elif [ $# = 5 -a $1 = gealarm ]
then
	log4s info "开始安装gealarm软件"
	log4s debug "开始调用checkprosess函数"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start gealarm install" >> /tmp/install.log
	log4s info "start gealarm install写入/tmp/install.log文件"
	log4s debug "开始调用geinstall函数"
	fun_geinstall $envprofile $2 $3 $4 $5
	log4s info "install completed写入/tmp/install.log文件"
	echo "install completed" >> /tmp/install.log
	log4s info "gealarm软件安装完成"
elif [ $# = 7 -a $1 = gealarm ]
then
	log4s info "开始安装gealarm软件"
	log4s debug "开始调用checkprosess函数"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start gealarm install" >> /tmp/install.log
	log4s info "start gealarm install写入/tmp/install.log文件"
	log4s debug "开始调用geinstall函数"
	fun_geinstall $envprofile $2 $3 $4 $5 $6 $7
	log4s info "install completed写入/tmp/install.log文件"
	echo "install completed" >> /tmp/install.log
	log4s info "gealarm软件安装完成"
elif [ $# = 4 -a $1 = omsan ]
then
	log4s info "开始安装omsan软件"
	log4s debug "开始调用checkprosess函数"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start omsan install" >> /tmp/install.log
	log4s info "start omsan install写入/tmp/install.log文件"
	log4s debug "开始调用aninstall函数"
	fun_aninstall $envprofile $2 $3 $4
	log4s debug "开始调用pfmcinstall函数"
	fun_pfmcinstall $envprofile
	log4s info "install completed写入/tmp/install.log文件"
	echo "install completed" >> /tmp/install.log
	log4s info "omsan软件安装完成"
elif [ $# = 6 -a $1 = omsan ]
then
	log4s info "开始安装omsan软件"
	log4s debug "开始调用checkprosess函数"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start omsan install" >> /tmp/install.log
	log4s info "start omsan install写入/tmp/install.log文件"
	log4s debug "开始调用aninstall函数"
	fun_aninstall $envprofile $2 $3 $4 $5 $6
	log4s debug "开始调用pfmcinstall函数"
	fun_pfmcinstall $envprofile
	log4s info "install completed写入/tmp/install.log文件"
	echo "install completed" >> /tmp/install.log
	log4s info "omsan软件安装完成"
elif [ $# = 7 -a $1 = min ]
then
	log4s info "开始安装后台软件"
	log4s debug "开始调用checkprosess函数"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start min install" >> /tmp/install.log
	log4s info "start bep install写入/tmp/install.log文件"
	log4s debug "开始调用bepinstall函数"
	fun_bepinstall $envprofile $2 $3 $4 $5 $6 $7
	log4s info "install completed写入/tmp/install.log文件"
	echo "install completed" >> /tmp/install.log
	log4s info "后台软件安装完成"
elif [ $# = 3 -a $1 = informix ]
then
	log4s info "开始安装数据库alarmAPI软件"
	log4s debug "开始调用checkprosess函数"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start alarmAPI install" >> /tmp/install.log
	log4s info "start alarmAPI install写入/tmp/install.log文件"
	log4s debug "开始调用apiinstall函数"
	fun_apiinstall $envprofile $2 $3
	log4s info "install completed写入/tmp/install.log文件"
	echo "install completed" >> /tmp/install.log
	log4s info "数据库alarmAPI软件安装完成"
elif [ $# = 3 -a $1 = ss7 ]
then
	log4s info "开始安装n7server软件"
	log4s debug "开始调用checkprosess函数"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start n7server install" >> /tmp/install.log
	log4s info "start n7server install写入/tmp/install.log文件"
	log4s debug "开始调用ss7install函数"
	fun_ss7install $envprofile $2 $3
	log4s info "install completed写入/tmp/install.log文件"
	echo "install completed" >> /tmp/install.log
	log4s info "n7server软件安装完成"
fi
