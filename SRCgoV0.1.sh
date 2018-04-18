#!/bin/bash

################log4s������#################
log4spath=`pwd`								#�����־Ŀ¼
log4sCategory=debug					#�����־�������ƣ�������debug=0��warn=1��info=2��error=3
logs4logname=root.log					#�����־����
isecho=0											#�������־��ͬʱ�Ƿ��ӡ����Ļ��0�ǲ���ӡ��1�Ǵ�ӡ
splittype=none								#��־�ָʽ��none���ָday�������ڷָ��׺��ΪYYYY-MM-DD��numΪ������ģʽ�ָ���ʹ��numģʽ�������дsplitnum���������û˼·�ݲ�֧��
splitnum=1000


################log4s����У�鲢��ʼ�����������ó�����Ϊ��ʼ��ֻ��Ҫһ��#############
log4scheck()
{
	if [ X$log4spath = X ]
	then
		echo "log4spath������Ҫ����"
		exit 1;
	fi
	if [ X$log4sCategory = X ]
	then
		echo "log4sCategory������Ҫ����"
		exit 1;
	fi
	if [ X$logs4logname = X ]
	then
		echo "logs4logname������Ҫ����"
		exit 1;
	fi
	if [ X$isecho = X ]
	then
		echo "isecho������Ҫ����"
		exit 1;
	fi
	if [ X$splittype = X ]
	then
		echo "splittype������Ҫ����"
		exit 1;
	fi
	if [ X$splittype = Xnum ]
	then
		if [ X$splitnum = X ]
		then
			echo "splitnum������Ҫ����"
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
################log4s������#################
log4slog=${log4spath}/${logs4logname}
log4scheck;
log4s()                       #$1�Ǽ���$2������
{
	nowdate=`date +"%Y-%m-%d %H:%M:%S"`
	######�ж����򣬱�֤�����Ͻ���
	#�ж�Ŀ¼����־�ļ������Զ�����Ŀ¼�����ǻ��Զ������ļ�
	if [ ! -d $log4spath ]
	then
		echo "$nowdate log4s���õ�Ŀ¼�����ڣ���ȷ�������Ƿ���ȷ"
		exit 1;
	fi
	if [ ! -f $log4slog ]
	then
		echo "$nowdate $logname�����ڣ�����log4s��־�ļ�"
		echo "$nowdate $logname�����ڣ�����log4s��־�ļ�" >> $log4slog
	fi
	
	#�жϲ�������
	if [ $# -ne 2 ]
	then
		echo "��������Ϊ2��"
		exit 1;
	fi
	log4sindex=0
	
	###�ָ���־��
	#���շָ�
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
	#�������ָ�
	if [ $splittype = num ]
	then
		if [ ! -f $log4slog ]
		then
			echo "��־�ļ������ڣ����������Ƿ���ȷ"
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

	######��������
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
XITONG=`echo $(uname)|tr '[a-z]' '[A-Z]'`  #ϵͳ����
xtong=`echo $(uname)|tr '[A-Z]' '[a-z]'`
XTBANBEN=`cat /etc/issue|head -1|awk '{print $7}'`  #��ȡϵͳ�汾
tXTBB=$(echo $XTBANBEN |awk '{print $1*100}')

if [ $# = 0 ]
then
	echo "������Ҫ������install�����а�װ��������������ϸ�Ķ�������"
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
#############����������1.ϵͳ���ͣ�SCPAS/CLAS/SCIM����2.�������ͣ�BEP/SIP/MS/RS/DB����3.IP��ַ��XXX.XXX.XXX.XXX����4.ͳһ�˻����룬5.��������IP
#SYSTYPE=`echo $1|tr '[a-z]' '[A-Z]'`
#HOSTYPE=`echo $2|tr '[a-z]' '[A-Z]'`
#IPADDR=$3
#PASSWD=$4
#ALARMIP="$5:3000"



##bep��װ��Ҫ7�������ֱ�Ϊ�����������ļ�����DOMAINID��CLUSTER������ip��INFORMIXDIR��INFORMIXSERVER��ONCONFIG
fun_bepinstall() {
if [ $# != 7 ]
then
log4s error "��̨��װ�����������󣡺�̨��װʧ��"
exit 1
fi
cd $HOME
mkdir cin
log4s info "��ʼ��ѹ��̨�����"
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
	log4s error "�Ҳ�����Ӧ�ĺ�̨���������װ��̨ʧ��"
	exit 1
fi
pacname=`ls|grep Package|grep -v tar|grep -v gz|grep -v zip|grep -v bak`
if [[ X$pacname = X ]]
then
	log4s error "Package�ļ��в����ڣ���ȷ����ѹ���Package*�ļ�����\$HOME��"
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
log4s info "��̨���������������"
. $HOME/$1
log4s info "��ʼ��װ��̨"
$HOME/Package*/makefifo
cp $HOME/Package*/install.sc $HOME 
chmod +x $HOME/install.sc
sleep 5
log4s info "��ʼ�����̨"
$HOME/install.sc -all $pacname << EOF
0
i
i
y
EOF
if [ $? -eq 0 ]
then
log4s info "��̨����ɹ�"
else
log4s error "��̨����ʧ��"
fi
sed -i "1s/SERVER.*/SERVER=$4:3000/" $CINDIR/etc/alarm.bep
sed -i "s/<addr.*port=\"1500\".*/<addr ip=\"$4\" port=\"1500\"\/>/" $CINDIR/etc/config.ne
log4s info "��̨��װ��ɣ����ֹ��޸�SDFDB��SMPDB����������config.comm��config.manager��sync.conf��config.sys�����ļ�"
}

##sip��װ��Ҫ4�������ֱ�Ϊ�����������ļ�����SIPDOMAINID��CLUSTER������IP
fun_sipinstall() {
if [ $# != 4 ]
then
	log4s error "sip��װ������������sip��װʧ��"
	exit 1
fi
echo 'SIPDIR=$HOME/sipserver' >> $1
echo 'PATH=$PATH:$SIPDIR/bin' >> $1
echo "SIPDOMAINID=$2" >> $1
echo "CLUSTER=$3" >> $1
echo 'export  SIPDIR PATH SIPDOMAINID CLUSTER' >> $1
log4s info "sip���������������"
cd $HOME
. $HOME/$1
log4s info "��ʼ��ѹsip�����"
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
	log4s error "�Ҳ�����Ӧ��sip�������sip��װʧ��"
	exit 1
fi
if [[ ! -d "sipserver" ]]
then
	log4s error "sipserver�ļ��в����ڣ���ȷ����ѹ���sipserver�ļ�����\$HOME��"
	exit 1
fi
log4s info "��ʼ��װsip"
chmod +x $HOME/sipserver/bin/sipmake
sleep 5
log4s info "��ʼ����sip"
sipmake
if [ $? -eq 0 ]
then
log4s info "sip����ɹ�"
else
log4s error "sip����ʧ��"
fi
chmod +x $HOME/sipserver/bin/*
sed -i "s/<inmsAlarmServer.*/<inmsAlarmServer ip=\"$4\" port=\"3000\"\/>/g" $HOME/sipserver/etc/config.alarm
log4s info "sip��װ��ɣ����ֹ��޸�config.sipserver��config.comm�����ļ�"
}

##gealarm��װ��Ҫ5����7�������ֱ�Ϊ�����������ļ�����DOMAINID��CLUSTER������ip�˿ڡ�root���롢��ѡ(INFORMIXDIR��INFORMIXSERVER)
fun_geinstall() {
if [ $# == 5 ]
then
	echo 'CINDIR=$HOME/genalarm' >> $1
	echo 'PATH=$PATH:.:$CINDIR/bin:/usr/vacpp/bin' >> $1
	echo "CLUSTER=$3" >> $1
	echo "DOMAINID=$2" >> $1
	echo 'export CINDIR PATH CLUSTER DOMAINID' >> $1
	geType='noDB'
	log4s info "gealarm���������������"
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
	log4s info "gealarm���������������"
else
	log4s error "gealarm��װ������������gealarm��װʧ��"
	exit 1	
fi
cd $HOME
. $HOME/$1
log4s info "��ʼ��ѹgealarm�����"
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
	log4s error "�Ҳ���gealarm���������װgealarmʧ��"
	exit 1
fi
if [[ ! -d "genalarm" ]]
then
	log4s error "genalarm�ļ��в����ڣ���ȷ����ѹ���genalarm�ļ�����\$HOME��"
	exit 1
fi
log4s info "��ʼ��װgealarm"
cd $CINDIR/src
sleep 5
log4s info "��ʼ����gealarm"
makeall $geType
if [ $? -eq 0 ]
then
log4s info "gealarm����ɹ�"
else
log4s error "gealarm����ʧ��"
fi
chmod +x $HOME/genalarm/bin/*
sed -i "1s/.*/SERVER=$4/" $CINDIR/etc/config.alarm
sed -i "s/<subnet name=\"ckpro\" fe=\"checkpro\".*/<subnet name=\"ckpro\" fe=\"checkpro\" startinstance=\"1\" number=\"1\" initialnumber=\"1\" \/>/g" $CINDIR/etc/config.comm
if [ $# == 7 ]
then
	sed -i "s/<subnet name=\"ckDB\" fe=\"checkDB\".*/<subnet name=\"ckDB\" fe=\"checkDB\" startinstance=\"1\" number=\"1\" initialnumber=\"1\" \/>/g" $CINDIR/etc/config.comm
fi
log4s info "�����־�ļ��ɶ�Ȩ��"
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
log4s info "���ֹ���gealarm�˻����dbaccessȨ��"
fi
log4s info "gealarm��װ���"
}

##omsan��װ��Ҫ4����6�������ֱ�Ϊ�����������ļ�����CLUSTER������ip���������˿ڣ���root���롢��ѡ(INFORMIXDIR��INFORMIXSERVER)
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
	log4s info "omsan���������������"
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
	log4s info "omsan���������������"
else
	log4s error "omsan��װ������������omsan��װʧ��"
	exit 1
fi
cd $HOME
. $HOME/$1
log4s info "��ʼ��ѹomsan�����"
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
	log4s error "�Ҳ���omsan���������װomsanʧ��"
	exit 1
fi
ansrcDir=`ls|grep ^oms|grep -v tar|grep -v gz|grep -v zip`
mv $ansrcDir oms
if [[ ! -d "oms" ]]
then
	log4s error "oms�ļ��в����ڣ���ȷ����ѹ���oms�ļ�����\$HOME��"
	exit 1
fi
log4s info "��ʼ��װomsan"
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
log4s info "omsan����ɹ�"
else
log4s error "omsan����ʧ��"
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
log4s info "omsan��װ���"
}

##pfmcapi��װ��Ҫ1���������������ļ���
fun_pfmcinstall() {
if [ $# != 1 ]
then
log4s error "pfmcapi��װ�����������󣡺�̨��װʧ��"
exit 1
fi
echo 'PFMCAPIDIR=$HOME/pfmcapi' >> $1
echo 'export PFMCAPIDIR' >> $1
echo 'LD_LIBRARY_PATH=$PFMCAPIDIR/lib:$LD_LIBRARY_PATH' >> $1
echo 'export LD_LIBRARY_PATH' >> $1
echo 'LIBPATH=$PFMCAPIDIR/lib:$LIBPATH' >> $1
echo 'export LIBPATH' >> $1
log4s info "pfmcapi���������������"
cd $HOME
. $HOME/$1
if [[ ! -d "pfmcapi" ]]
then
	log4s error "pfmcapi�ļ��в����ڣ���ȷ����ѹ���pfmcapi�ļ�����\$HOME��"
	log4s error "pfmcapi��װʧ��"
	exit 1
fi
log4s info "��ʼ��װpfmcapi"
cd $PFMCAPIDIR/src/
make
if [ $? -eq 0 ]
then
log4s info "pfmcapi����ɹ�"
else
log4s error "pfmcapi����ʧ��"
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
log4s info "pfmcapi��װ�ɹ�"
}

##alarmAPI��װ��Ҫ3�������ֱ�Ϊ�����������ļ�����CLUSTER������ip�˿�
fun_apiinstall()
{
if [ $# == 3 ]
then
	sed -i "s/^PATH.*/&:./g" $1
	log4s info "alarmAPI���������������"
else
	log4s error "alarmAPI��װ������������alarmAPI��װʧ��"
	exit 1	
fi
cd $HOME
. $HOME/$1
tarNum=`ls|grep alarmAPI.tar|wc -l`
if [ $tarNum -eq 0 ]
then
	log4s error "�Ҳ���alarmAPI���������װalarmAPIʧ��"
	exit 1
fi
cp $HOME/alarmAPI.tar $INFORMIXDIR/
cd $INFORMIXDIR
ls alarmAPI.tar | xargs -n1 tar xf
if [[ ! -d "$INFORMIXDIR/alarmAPI" ]]
then
	log4s error "alarmAPI�ļ��в����ڣ���ȷ����ѹ���galarmAPI�ļ�����\$INFORMIXDIR��"
	exit 1
fi
log4s info "��ʼ��װalarmAPI"
cd $INFORMIXDIR/alarmAPI
sleep 5
log4s info "��ʼ����alarmAPI"
make -f makefile.$xtong
if [ $? -eq 0 ]
then
log4s info "alarmAPI����ɹ�"
else
log4s error "alarmAPI����ʧ��"
fi
log4s info "��ʼ�޸�alarmAPI�����ļ�"
sed -i "s/^SERVER.*/SERVER=$3/g" $INFORMIXDIR/alarmAPI/alarmcfg
sed -i "29a\CLUSTER=$2\nexport CLUSTER" $INFORMIXDIR/alarmAPI/log_full.sh
sed -i "s/^instance.*/instance=\'$HOSTNAME.$2.DB\'/g" $INFORMIXDIR/alarmAPI/log_full.sh
sed -i "s!^ALARMPROGRAM.*!ALARMPROGRAM    ${INFORMIXDIR}/alarmAPI/log_full.sh!g" $INFORMIXDIR/etc/$ONCONFIG
chmod +x $INFORMIXDIR/alarmAPI/log_full.sh
log4s info "alarmAPI�����ļ��޸����"
log4s info "alarmAPI��װ���"
}

##n7server��װ��Ҫ3�������ֱ�Ϊ�����������ļ�����CLUSTER������ip�˿�
fun_ss7install() {
if [ $# != 3 ]
then
	log4s error "n7server��װ������������n7server��װʧ��"
	exit 1
fi
cd $HOME
log4s info "��ʼ��ѹn7server�����"
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
	log4s error "�Ҳ���n7server���������װn7serverʧ��"
	exit 1
fi
if [[ ! -d "No7_IPS_n7server" ]]
then
	log4s error "No7_IPS_n7server�ļ��в����ڣ���ȷ����ѹ���No7_IPS_n7server�ļ�����\$HOME��"
	exit 1
fi
cd $HOME/No7_IPS_n7server
sleep 5
log4s info "��ʼ��װn7server"
./install -all <<-EOF
y
s
n
n
y
EOF
if [ $? -eq 0 ]
then
log4s info "n7server����ɹ�"
else
log4s error "n7server����ʧ��"
fi
log4s info "��ʼ�޸Ļ��������������ļ�"
sed -i "s/CLUSTER.*/CLUSTER=$2/g" $HOME/$1
. $HOME/$1
sed -i "s/SERVER.*/SERVER=$3/" $CINDIR/etc/config.udp.alarm
log4s info "n7server��װ��ɣ����ֹ��޸�N7SERVERNUM����������config.n7server�����ļ�"
}

fun_ftphost()#####��Ҫ������������HOSTYPE��IP��ַIPADDR��ͳһ�˻�����PASSWD
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
log4s info "��ʼ�ϴ�$userName�����Լ����ű���$2"
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
log4s info "����ϴ�$userName�����Լ����ű���$2"
done
}


fun_install()
{
ANSWER=n
while [ "$ANSWER" != "y" -a "$ANSWER" != "Y" ]
do
	echo -e "���������밲װ��ϵͳ���ͣ�SCPAS/CLAS/SCIM����\c"
	read SYSTYPE
	SYSTYPE=`echo $SYSTYPE|tr '[a-z]' '[A-Z]'`
	while [ $SYSTYPE != "SCPAS" -a $SYSTYPE != "CLAS" -a $SYSTYPE != "SCIM" ] 
	do
		echo -e "��������ȷ��ϵͳ���ͣ�SCPAS/CLAS/SCIM����\c"
		read SYSTYPE
		SYSTYPE=`echo $SYSTYPE|tr '[a-z]' '[A-Z]'`
	done
	case $SYSTYPE in
	SCPAS)
		echo -e "�밴˳���������밲װSIP���������IP��ַ����̨�������ÿո��������10.175.48.1 10.175.48.2 10.175.48.3����\c"
		read -a ARRAY_SIPADDR
		echo -e "�밴˳���������밲װ��̨���������IP��ַ����̨�������ÿո��������10.175.48.4 10.175.48.5 10.175.48.6����\c"
		read -a ARRAY_BEPADDR
		echo -e "�밴˳���������밲װMS���������IP��ַ����̨�������ÿո��������10.175.48.7 10.175.48.8����\c"
		read -a ARRAY_MSADDR
		echo -e "�밴˳�����������ݿ�����IP��ַ����̨�������ÿո��������10.175.48.9 10.175.48.10����\c"
		read -a ARRAY_DBADDR
		;;
	CLAS)
		echo -e "�밴˳���������밲װSIP���������IP��ַ����̨�������ÿո��������10.175.48.1 10.175.48.2 10.175.48.3����\c"
		read -a ARRAY_SIPADDR
		echo -e "�밴˳���������밲װ��̨���������IP��ַ����̨�������ÿո��������10.175.48.4 10.175.48.5 10.175.48.6����\c"
		read -a ARRAY_BEPADDR
		echo -e "�밴˳���������밲װMS���������IP��ַ����̨�������ÿո��������10.175.48.7 10.175.48.8����\c"
		read -a ARRAY_MSADDR
		echo -e "�밴˳��������RS����IP��ַ����̨�������ÿո��������10.175.48.11 10.175.48.12����\c"
		read -a ARRAY_RSADDR
		echo -e "�밴˳�����������ݿ�����IP��ַ����̨�������ÿո��������10.175.48.9 10.175.48.10����\c"
		read -a ARRAY_DBADDR
		;;
	SCIM)
		echo -e "�밴˳���������밲װSIP���������IP��ַ����̨�������ÿո��������10.175.48.1 10.175.48.2 10.175.48.3����\c"
		read -a ARRAY_SIPADDR
		echo -e "�밴˳���������밲װ��̨���������IP��ַ����̨�������ÿո��������10.175.48.4 10.175.48.5 10.175.48.6����\c"
		read -a ARRAY_BEPADDR
		echo -e "�밴˳�����������ݿ�����IP��ַ����̨�������ÿո��������10.175.48.9 10.175.48.10����\c"
		read -a ARRAY_DBADDR
		;;
	*)
		echo "ϵͳ���ʹ���"
		exit 1
	esac
	echo -e "�������������½�ϵͳinformix�ͻ��˵�INFORMIXDIR����/home/informix����\c"
	read INFDIR
	echo -e "�������������½�ϵͳinformix����˵�INFORMIXDIR����/ids����\c"
	read DBDIR
	echo -e "�������������½�ϵͳ��INFORMIXSERVER����db11����\c"
	read INFSER
	echo -e "�������������½�ϵͳ�����ݿ�ONCONFIG�ļ�������onconfig.hdr11����\c"
	read INFCONF
	echo -e "�������������½�ϵͳ�ļ�Ⱥ���ƣ�\c"
	read CLUSTER
	echo -e "�������������½�ϵͳ�����루��ϵͳ���������˻�����ͳһ����\c"
	read PASSWD
	echo -e "����������������IP��ַ��\c"
	read OMSIP
	
	echo "��ȷ������ѡ��"
	echo "##################################################################################################"
		echo "ϵͳ����          = $SYSTYPE"
	case $SYSTYPE in
	SCPAS)
		echo "SIP����IP��ַ     = ${ARRAY_SIPADDR[*]}"
		echo "��̨����IP��ַ    = ${ARRAY_BEPADDR[*]}"
		echo "MS����IP��ַ      = ${ARRAY_MSADDR[*]}"
		echo "���ݿ�����IP��ַ  = ${ARRAY_DBADDR[*]}"
		;;
	CLAS)
		echo "SIP����IP��ַ     = ${ARRAY_SIPADDR[*]}"
		echo "��̨����IP��ַ    = ${ARRAY_BEPADDR[*]}"
		echo "MS����IP��ַ      = ${ARRAY_MSADDR[*]}"
		echo "RS����IP��ַ      = ${ARRAY_RSADDR[*]}"
		echo "���ݿ�����IP��ַ  = ${ARRAY_DBADDR[*]}"
		;;
	SCIM)
		echo "SIP����IP��ַ     = ${ARRAY_SIPADDR[*]}"
		echo "��̨����IP��ַ    = ${ARRAY_BEPADDR[*]}"
		echo "���ݿ�����IP��ַ  = ${ARRAY_DBADDR[*]}"
		;;
	esac
		echo "�ͻ���INFORMIXDIR = $INFDIR"
		echo "�����INFORMIXDIR = $DBDIR"
		echo "INFORMIXSERVER    = $INFSER"
		echo "ONCONFIG          = $INFCONF"
		echo "��Ⱥ����          = $CLUSTER"
		echo "�����˻�ͳһ����  = $PASSWD"
		echo "��������IP��ַ    = $OMSIP"
		echo "##################################################################################################"
	echo -e "���ȷ��������Y��y��\c"
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
		log4s info "��ʼ����$LOOP@$sipaddr��װ�ű�"
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
		log4s info "$LOOP@$sipaddr��װ����"
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
		log4s info "��ʼ����$LOOP@$bepaddr��װ�ű�"
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
		log4s info "$LOOP@$bepaddr��װ����"
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
		log4s info "��ʼ����$LOOP@$bepaddr��װ�ű�"
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
		log4s info "$LOOP@$bepaddr��װ����"
	done
done

if [ $SYSTYPE = "SCPAS" ]
then
for ss7addr in ${ARRAY_BEPADDR[@]}
do
	fun_ftphost SS7 $bepaddr $PASSWD
	parass7="ss7 $CLUSTER $OMSIP:3000"
	log4s info "��ʼ����ss7@$ss7addr��װ�ű�"
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
	log4s info "ss7@$ss7addr��װ����"
done
log4s info "SCPASϵͳ���ڽ��а�װ���Ժ���鿴��̨�������н��"
elif [ $SYSTYPE = "CLAS" ]
then
	echo 2222
elif [ $SYSTYPE = "SCIM" ]
then
	log4s info "SCIMϵͳ���ڽ��а�װ���Ժ���鿴��̨�������н��"
fi	
}

###########�˲������˻������װ�Ƿ�ִ�����#####
######1.�˲��ļ�ȫ·����2.���һ�к˲���־���ݣ�3.ѭ��������4.ÿ��ѭ������ʱ��
checkprosess()
{
if [ ! -f "$1" ]
then
touch $1
chmod 777 $1
log4s info "�����ļ�$1"
fi
runntimes=0
while [ X"`tail -1 $1`" != X"$2" -a X"`tail -1 $1`" != X ]
do
	if [ $runntimes -lt $3 ]
	then
	sleep $4
	runntimes=`expr $runntimes + 1`
	log4s debug "��${runntimes}��ѭ��"
	else
	log4s info "�����ȶ�ִ��ʱ����δ��ʼ���г����˳��ýű�"
	exit 0
	fi
done
}

if [ $# = 1 -a $1 = install ]
then
	log4s debug "��ʼ����install����"
	fun_install
	log4s debug "install�����������"
elif [ $# = 4 -a $1 = sip ]
then
	log4s info "��ʼ��װsip���"
	log4s debug "��ʼ����checkprosess����"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start sip install" >> /tmp/install.log
	log4s info "start sip installд��/tmp/install.log�ļ�"
	log4s debug "��ʼ����sipinstall����"
	fun_sipinstall $envprofile $2 $3 $4
	log4s info "install completedд��/tmp/install.log�ļ�"
	echo "install completed" >> /tmp/install.log
	log4s info "sip�����װ���"
elif [ $# = 5 -a $1 = gealarm ]
then
	log4s info "��ʼ��װgealarm���"
	log4s debug "��ʼ����checkprosess����"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start gealarm install" >> /tmp/install.log
	log4s info "start gealarm installд��/tmp/install.log�ļ�"
	log4s debug "��ʼ����geinstall����"
	fun_geinstall $envprofile $2 $3 $4 $5
	log4s info "install completedд��/tmp/install.log�ļ�"
	echo "install completed" >> /tmp/install.log
	log4s info "gealarm�����װ���"
elif [ $# = 7 -a $1 = gealarm ]
then
	log4s info "��ʼ��װgealarm���"
	log4s debug "��ʼ����checkprosess����"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start gealarm install" >> /tmp/install.log
	log4s info "start gealarm installд��/tmp/install.log�ļ�"
	log4s debug "��ʼ����geinstall����"
	fun_geinstall $envprofile $2 $3 $4 $5 $6 $7
	log4s info "install completedд��/tmp/install.log�ļ�"
	echo "install completed" >> /tmp/install.log
	log4s info "gealarm�����װ���"
elif [ $# = 4 -a $1 = omsan ]
then
	log4s info "��ʼ��װomsan���"
	log4s debug "��ʼ����checkprosess����"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start omsan install" >> /tmp/install.log
	log4s info "start omsan installд��/tmp/install.log�ļ�"
	log4s debug "��ʼ����aninstall����"
	fun_aninstall $envprofile $2 $3 $4
	log4s debug "��ʼ����pfmcinstall����"
	fun_pfmcinstall $envprofile
	log4s info "install completedд��/tmp/install.log�ļ�"
	echo "install completed" >> /tmp/install.log
	log4s info "omsan�����װ���"
elif [ $# = 6 -a $1 = omsan ]
then
	log4s info "��ʼ��װomsan���"
	log4s debug "��ʼ����checkprosess����"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start omsan install" >> /tmp/install.log
	log4s info "start omsan installд��/tmp/install.log�ļ�"
	log4s debug "��ʼ����aninstall����"
	fun_aninstall $envprofile $2 $3 $4 $5 $6
	log4s debug "��ʼ����pfmcinstall����"
	fun_pfmcinstall $envprofile
	log4s info "install completedд��/tmp/install.log�ļ�"
	echo "install completed" >> /tmp/install.log
	log4s info "omsan�����װ���"
elif [ $# = 7 -a $1 = min ]
then
	log4s info "��ʼ��װ��̨���"
	log4s debug "��ʼ����checkprosess����"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start min install" >> /tmp/install.log
	log4s info "start bep installд��/tmp/install.log�ļ�"
	log4s debug "��ʼ����bepinstall����"
	fun_bepinstall $envprofile $2 $3 $4 $5 $6 $7
	log4s info "install completedд��/tmp/install.log�ļ�"
	echo "install completed" >> /tmp/install.log
	log4s info "��̨�����װ���"
elif [ $# = 3 -a $1 = informix ]
then
	log4s info "��ʼ��װ���ݿ�alarmAPI���"
	log4s debug "��ʼ����checkprosess����"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start alarmAPI install" >> /tmp/install.log
	log4s info "start alarmAPI installд��/tmp/install.log�ļ�"
	log4s debug "��ʼ����apiinstall����"
	fun_apiinstall $envprofile $2 $3
	log4s info "install completedд��/tmp/install.log�ļ�"
	echo "install completed" >> /tmp/install.log
	log4s info "���ݿ�alarmAPI�����װ���"
elif [ $# = 3 -a $1 = ss7 ]
then
	log4s info "��ʼ��װn7server���"
	log4s debug "��ʼ����checkprosess����"
	checkprosess "/tmp/install.log" "install completed" 100 60
	echo "start n7server install" >> /tmp/install.log
	log4s info "start n7server installд��/tmp/install.log�ļ�"
	log4s debug "��ʼ����ss7install����"
	fun_ss7install $envprofile $2 $3
	log4s info "install completedд��/tmp/install.log�ļ�"
	echo "install completed" >> /tmp/install.log
	log4s info "n7server�����װ���"
fi
