#!/bin/sh


#�ܹ����ð�
#############################################
#�����ű��Ͱ�װ���ŵ�/tmp��
#��ʱֻ֧��linux
#############################################

#���Ա�־λ��1��Ϊ���������0��Ϊ��ʽ������
testflag=1
#ģ�壬����չ
muban=cl
#Ϊ0��ʹ�������ļ���Ϊ1��ʹ�����뷽ʽ
peizhiflag=1
#�Ƿ���Ҫȥ�����Զ�ִ�У�0��1��
prionly=1



if [ $# = 0 ]
then
	echo "������Ҫ������anzhuang�����а�װ��������������ϸ�Ķ�������"
	echo "SecureCRT need defult"
	echo "ru guo zhong wen luan ma ,qing geng gai SecureCRT bian ma wei defult"
	exit 0;
fi


#############�������������������ϸ�Ķ�##############
isinformixid=0								#�Ƿ�ָ��informix�û�id����id���ݲ�֧�֣�����û��
informixgroupid=200
informixuserid=200
informixhome=/home/informix		#informix��homeĿ¼
idshome=/ids									#�����װĿ¼
INFORMIXDIR=/ids
log=/ids/rizhi.log
alreadyornolog=/ids/instalready.log
anzhuangbao=Informix_Enterprise_12.10.FC8W1_LIN-x86_64_IFix.tar
jiaobenming=`echo $0|awk -F'/' '{print $NF}'`
tongxinduankou1=36925					#������ͨ�ŵĶ˿ڣ�ϵͳĬ�ϵ�36925����ռ�ã���������������ֶ����ġ�
tongxinduankou2=36926

#dbs�������ø�dbs��С������chunk����д�����õ�λΪG
#ע����Ҫ���õ�dbs����lv�Ĵ�Сһ��Ҫ�������õ�dbs��С
#���԰��С����
if [ $testflag = 1 ]
then
	tsizerootdbs1G=2
	tsizetempdbs1G=4
	tsizetempdbs2G=4
	tsizelogdbs1G=4
	tsizephydbs1G=4
	tsizeuserdbs1G=20
else
	tsizerootdbs1G=4
	tsizetempdbs1G=8
	tsizetempdbs2G=8
	tsizelogdbs1G=8
	tsizephydbs1G=8
	tsizeuserdbs1G=50
fi


#############������������Ҫ��###############################
log4spath=$idshome								#�����־Ŀ¼
log4sCategory=info				#�����־�������ƣ�������debug=0��warn=1��info=2��error=3
logs4logname=root.log					#�����־����
isecho=1											#�������־��ͬʱ�Ƿ��ӡ����Ļ��0�ǲ���ӡ��1�Ǵ�ӡ
splittype=none								#��־�ָʽ��none���ָday�������ڷָ��׺��ΪYYYY-MM-DD��numΪ������ģʽ�ָ���ʹ��numģʽ�������дsplitnum���������û˼·�ݲ�֧��
splitnum=1000

X86=`uname -m`
XITONGTEMP=`uname`
XITONG=`echo $XITONGTEMP|tr '[a-z]' '[A-Z]'`  #ϵͳ����
XTBANBEN=`cat /etc/issue|head -1|awk '{print $7}'`  #��ȡϵͳ�汾
tXTBB=$(echo $XTBANBEN |awk '{print $1*100}')
cpunumtemp=`cat /proc/cpuinfo|grep processor|wc -l`
let cpunum=cpunumtemp-1
kernel_shmmax="kernel.shmmax = 4398046511104"
kernel_shmmni="kernel.shmmni = 4096"
kernel_shmall="kernel.shmall = 67108864"
kernel_sem="kernel.sem = 250 32000 32 4096"
stty erase ^H;


################log4s����У�鲢��ʼ�����������ó�����Ϊ��ʼ��ֻ��Ҫһ��#############
log4scheck()
{
	if [ ! -d $log4spath ]
	then
		mkdir $log4spath
	fi
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
		echo "log4s���õ�Ŀ¼�����ڣ���ȷ�������Ƿ���ȷ"
		exit 1;
	fi
	if [ ! -f $log4slog ]
	then
		#echo "$nowdate $logname�����ڣ�����log4s��־�ļ�"
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
			echo "$2"
		fi
		echo "$nowdate log4s.${log4sinlevel}   $2" >> $log4slog
	fi
}

SendAlarm()
{
	echo "$1";
	if [ ! -d $INFORMIXDIR ]
	then
		mkdir $INFORMIXDIR;
	fi
	if [ ! -f $log ]
	then
		touch $log;
	fi
	echo "$1" >> $log
}
tihuanbasic()
{
	sed "s#$1#$2#g" $3> $3.temp
	mv $3.temp $3
}
gai59()
{
	#����������$1λlvĿ¼����$lvrootdbs1��$2λlv�Ĵ�С
	if [ $2 != 0 ]
	then
		log4s debug "ENV{DM_NAME}==\"$1\", OWNER:=\"informix\", GROUP:=\"informix\", MODE:=\"660\""
		echo "ENV{DM_NAME}==\"$1\", OWNER:=\"informix\", GROUP:=\"informix\", MODE:=\"660\"" >> /etc/udev/rules.d/93-application-devices.rules
	fi
}
gai65()
{
	#3��������$1λ$vgname��$2��lv���Ʊ���rootdbs1��,3��lv�Ĵ�С
	if [ $3 != 0 ]
	then
		log4s debug "ENV{DM_VG_NAME}==\"$1\", ENV{DM_LV_NAME}==\"$2\", OWNER:=\"informix\", GROUP:=\"informix\""
		echo "ENV{DM_VG_NAME}==\"$1\", ENV{DM_LV_NAME}==\"$2\", OWNER:=\"informix\", GROUP:=\"informix\"" >> /etc/udev/rules.d/93-application-devices.rules
	fi
}
makeonspace()
{
	#onspaces -c -d logdbs -p /ids/dbfiles/logdbs1 -o 0 -s $sizelogdbs1;
	#$1��logdbs��$2��/ids/dbfiles/logdbs1��$3��$sizelogdbs1��$4�Ǿ�����-c -d ����-a
	if [ $3 != 0 ]
	then
		let onspacetempsize=$3*1000000
		if [ X$4 = Xc ]
		then
			log4s debug "��ʼ����dbspace  $1"
			onsapcetempflag=`echo $1|grep temp|wc -l|awk '{print $1}'`
			if [ X$onsapcetempflag = X0 ]
			then
				onspaces -c -d $1 -p $2 -o 0 -s $onspacetempsize;
				onresult=$?
			else
				onspaces -c -d $1 -t -p $2 -o 0 -s $onspacetempsize;
				onresult=$?
			fi
			sleep 3;
			if [ $onresult = 0 ]
			then
				log4s info "$1�����ɹ�"
			else
				log4s error "$1����ʧ��"
			fi
		fi
		if [ X$4 = Xa ]
		then
			log4s debug "����dbspace  $1"
			onspaces -a $1 -p $2 -o 0 -s $3;
			onresult=$?
			sleep 3;
			if [ $onresult = 0 ]
			then
				log4s info "$1���ӳɹ�"
			else
				log4s error "$1����ʧ��"
			fi
		fi
	fi
}
sizesum()
{
	list=$@
	sizesumnum=0
	for i in `echo $list`
	do
	sizesumnum=$((sizesumnum+i))
	done
}

isfull=0
diskisfull()
{
	#ʹ�÷�������ִ��sizesum����һ��������$devname
	if [ $sizesumnum = 0 ]
	then
		echo "��������sizesum"
		exit 1;
	fi
	let tempsize=$sizesumnum*1024*1024*1024
	disksize=`fdisk -l|grep "$1" |awk -F',' '{print $2}'|awk '{print $1}'`
	log4s info "��Ҫ�ռ�$tempsize,���̿ռ�Ϊ$disksize"
	if [ $tempsize -lt $disksize ] && [ $tempsize != 0 ]
	then
		ifull=ok
		log4s info "���̿ռ���������"
	else
		isfull=full
		log4s error "���̿ռ䲻��"
		exit 1;
	fi
}
vgisfull()
{
	#ʹ�÷�������ִ��sizesum����һ��������$devname
	if [ $sizesumnum = 0 ]
	then
		echo "��������sizesum"
		exit 1;
	fi
	let tempsize=$sizesumnum
	vgsize=`vgdisplay $vgname|grep 'VG Size'|awk '{print $3}'`
	log4s info "��Ҫ��vg�ռ�Ϊ${tempsize}G����ǰvgʵ�ʿռ�Ϊ${tempsize}G"
	if [ $tempsize -lt $vgsize ] && [ $tempsize != 0 ]
	then
		ifull=ok
		log4s info "vg�ռ���������"
	else
		isfull=full
		log4s error "vg�ռ䲻��"
		exit 1;
	fi
}
checklv()
{
	#��黮�ֵ�lv��С�Ƿ�������õ�ֵ�������Ƿ񻮷ֳɹ�
	#$1ΪlvĿ¼��$2Ϊ���õĴ�С
	if [ X$1 = X ] || [ X$2 = X ]
	then
		log4s debug "checklv���д��󣬵�һ������Ϊ��$1���ڶ�������Ϊ��$2"
	fi
	if [ X$2 != X0 ]
	then
		lvexist=`lvdisplay $1|grep 'LV Size'|wc -l|awk '{print $1}'`
		if [ X$lvexist != X1 ]
		then
			log4s error "$1������"
			exit 1;
		fi
		huafensize=`lvdisplay $1|grep 'LV Size'|awk '{print $3}'|awk -F'.' '{print $1}'`
		yaoqiusize=$2
		if [ $huafensize -ge $yaoqiusize ]
		then
			log4s debug "${1}��С����Ҫ��"
		else
			log4s error "�����dbs��СΪ$2������lv��СΪ$1��������Ҫ��"
			exit 1;
		fi
	else
		log4s debug "${1}�Ĵ�СΪ0������Ҫ������dbs�����Բ����"
	fi
}
makeln()
{
	#$1��Դ�ļ�Ҳ����lv��$2��Ҫ�����Ĵ�С��$3�������ļ�Ҳ����dbsfile�µ�
	if [ X$2 != X0 ]
	then
		ln -s $1 $3
		log4s info "����$3"
		if [ -L $3 ]
		then
			log4s info "���������ļ� $3 �ɹ�"
		else
			log4s error "���������ļ� $3 ʧ��"
		fi
	fi
}
tihuan()
{
	log4s debug "��$peizhi�е�\"$1\" �޸�Ϊ \"$2\""
	tihuanbasic "$1" "$2" $peizhi
}
xiugai()
{
	log4s debug "��/tmp/tempIFX12.sh�е�\"$1\" �޸�Ϊ \"$2\""
	tihuanbasic "$1" "$2" /tmp/tempIFX12.sh
}
Pstr()
{
	Pstrtmp1=`echo $1|sed s#[[:space:]]##g`
	Pstrtmp2=`echo $Pstrtmp1|wc -L|awk '{print $1}'`
	WPstrtmp1=`echo $1|wc -L|awk '{print $1}'`
	if [ X$Pstrtmp2 = X$WPstrtmp1 ]
	then
		echo "ok"
	else
		echo "no"
	fi
}

Pip()
{
	tPiptmp1=`echo $1|sed s#[[:digit:]]##g`
	Piptmp1=`echo $tPiptmp1|sed s#[[:space:]]##g`
	Piptmp2=`echo $Piptmp1|wc -L|awk '{print $1}'`
	if [ X$Piptmp2 = X3 ]
	then
		echo "ok"
	else
		echo "no"
	fi
}

Pnum()
{
	Pnumtmp1=`echo $1|sed s#[[:space:]]##g`
	Pnumtmp2=`echo $Pnumtmp1|sed s#[[:digit:]]##g`
	Pnumold1=`echo $1|wc -L|awk '{print $1}'`
	Pnumold2=`echo $Pnumtmp1|wc -L|awk '{print $1}'`
	Pnumnew=`echo $Pnumtmp2|wc -L|awk '{print $1}'`
	if [ X$Pnumold1 = X$Pnumold2 ] && [ X0 = X$Pnumnew ] && [ XPnumold1 != X0 ]
	then
		echo "ok"
	else
		echo "no"
	fi
}

Plvsize()
{
	#$1ΪlvĿ¼��$2Ϊlv��С��$3Ϊlv����
	if [ X$1 = X0 ] || [ X$2 = X0 ] || [ X$3 = X0 ]
	then
		log4s info "��ǰdbs�����������Բ���Ҫ�ж�"
	else
		Plvsizegetsize=`lvdisplay $1|grep 'LV Size'|awk '{print $3}'|awk -F'.' '{print $1}'`
		if [ $Plvsizegetsize -lt $2 ]
		then
			log4s error "$3,���õ�lv�Ĵ�СΪ$Plvsizegetsize��С��Ҫ��Ĵ�С$2"
			exit 1;
		else
			log4s debug "$3,���õ�lv�Ĵ�СΪ$Plvsizegetsize������Ҫ��Ĵ�С$2������Ҫ��"
		fi
	fi
}
Rset0()
{
	if [ X$1 = X ] || [ X$1 = XN ] || [ X$1 = Xn ] || [ X$1 = X0 ]
	then
		$2=0
	fi
}
makepv()
{
	#$1ΪҪ����pv��Ŀ¼
	pvisexist=`pvscan|grep "$1"|wc -l|awk '{print $1}'`
	if [ X$pvisexist = X0 ]
	then
		pvcreate $1 > $log4spath/makepv.temp
		getpvnum=`pvscan|grep $1|wc -l|awk '{print $1}'`
		getmakeresult=`grep -i successfully $log4spath/makepv.temp|wc -l|awk '{print $1}'`
		if [ X$getpvnum = X1 ] && [ X$getmakeresult = X1 ]
		then
			log4s info "pv�����ɹ�"
		else
			log4s error "pv����ʧ��"
			exit 1;
		fi
	else
		log4s error "pv�Ѿ����ڣ���ע�������Ƿ�����"
		exit 1;
	fi
}

makevg()
{
	vgcreate $1 $2 > $log4spath/makevg.temp
	getvgnum=`vgdisplay|grep "$vgname"|wc -l|awk '{print $1}'`
	getmakevgresult=`grep -i successfully $log4spath/makevg.temp|wc -l|awk '{print $1}'`
	if [ X$getvgnum = X1 ] && [ X$getmakevgresult = X1 ]
	then
		log4s info "����vg�ɹ���vg����Ϊ$vgname"
	else
		log4s error "����vgʧ��"
		exit 1;
	fi
}

makelv()
{
	#ʹ�÷����������һ��������lv�����ڶ���������С����ʽΪ1G��������������vg����
	if [ $2 != 0 ]
	then
		lvcreate -L ${2}G -n $1 $3 > $log4spath/makelv.temp
		getmakelvresult=`grep $1 $log4spath/makelv.temp|grep -i created|wc -l|awk '{print $1}'`
		if [ X$getmakelvresult = X1 ]
		then
			log4s info "$1�����ɹ�"
		else
			log4s error "$1����ʧ��"
			exit 1;
		fi
	fi

}



#########################ռλ�������������޸�#########
#��������Ϊ��ʹ��informix�˻������ű�ʱ�ܻ��֮ǰ�����������Ϣ
priINFORMIXSERVER=XXXXXX
secINFORMIXSERVER=XXXXXX
priDBSERVERALIASES=XXXXXX
secDBSERVERALIASES=XXXXXX
priname=XXXXXX
secname=XXXXXX
priONCONFIG=XXXXXX
secONCONFIG=XXXXXX
priappname=XXXXXX
secappname=XXXXXX
priip=XXXXXX
secip=XXXXXX
priappip=XXXXXX
secappip=XXXXXX
lvrootdbs1=XXXXXX
lvtempdbs1=XXXXXX
lvtempdbs2=XXXXXX
lvlogdbs1=XXXXXX
lvphydbs1=XXXXXX
lvuserdbs1=XXXXXX
lvuserdbs2=XXXXXX
lvuserdbs3=XXXXXX
lvuserdbs4=XXXXXX
lvuserdbs5=XXXXXX
lvchargedbs1=XXXXXX
lvchargedbs2=XXXXXX
lvminfodbs1=XXXXXX
lvminfodbs2=XXXXXX
lvservdbs1=XXXXXX
lvservdbs2=XXXXXX
vgname=XXXXXX
devname=XXXXXX
shifouchuangjianpv=XXXXXX
shifouchuangjianvg=XXXXXX
shifouqueredevname=XXXXXX
shifouqueredevname1=XXXXXX
shifouchuangjianlv=XXXXXX
shifoutiaozhenglvsize=XXXXXX
shifouquerenlvsize=XXXXXX
shifoutiaozhenglvsize=XXXXXX
shifouquerenlvsize=XXXXXX
sizerootdbs1G=XXXXXX
sizetempdbs1G=XXXXXX
sizetempdbs2G=XXXXXX
sizelogdbs1G=XXXXXX
sizephydbs1G=XXXXXX
sizeuserdbs1G=XXXXXX
sizeuserdbs2G=XXXXXX
sizeuserdbs3G=XXXXXX
sizeuserdbs4G=XXXXXX
sizeuserdbs5G=XXXXXX
sizechargedbs1G=XXXXXX
sizechargedbs2G=XXXXXX
sizeminfodbs1G=XXXXXX
sizeminfodbs2G=XXXXXX
sizeservdbs1G=XXXXXX
sizeservdbs2G=XXXXXX
shifouquerenlvsize=XXXXXX
lvmuluqueren=XXXXXX
peizhiqueren=XXXXXX
hdrflag=XXXXXX
isserver=XXXXXX
client_pri_serverip=XXXXXX
client_pri_serverport=XXXXXX
client_pri_serverservername=XXXXXX
client_sec_serverip=XXXXXX
client_sec_serverport=XXXXXX
client_sec_serverservername=XXXXXX
clientcount=XXXXXX
clientip1=XXXXXX
clientport1=XXXXXX
clientusername=XXXXXX
clientip=XXXXXX
clientport=XXXXXX
clientpeizhiqueren=XXXXXX

#############��ȡϵͳ�������������ó���Ϊ�˱��ڵ���#########
X86=`uname -m`
XITONGTEMP=`uname`
XITONG=`echo $XITONGTEMP|tr '[a-z]' '[A-Z]'`  #ϵͳ����
XTBANBEN=`cat /etc/issue|head -1|awk '{print $7}'`  #��ȡϵͳ�汾
tXTBB=$(echo $XTBANBEN |awk '{print $1*100}')
cpunumtemp=`cat /proc/cpuinfo|grep processor|wc -l`
let cpunum=cpunumtemp-1
kernel_shmmax="kernel.shmmax = 4398046511104"
kernel_shmmni="kernel.shmmni = 4096"
kernel_shmall="kernel.shmall = 67108864"
kernel_sem="kernel.sem = 250 32000 32 4096"

let sizerootdbs1=$sizerootdbs1G*1000000
let sizetempdbs1=$sizetempdbs1G*1000000
let sizetempdbs2=$sizetempdbs2G*1000000
let sizelogdbs1=$sizelogdbs1G*1000000
let sizephydbs1=$sizephydbs1G*1000000
let sizeuserdbs1=$sizeuserdbs1G*1000000

#������ʼ����У������
CheckP()
{
	PWDDIR=`pwd`
	if [ X$PWDDIR != X/tmp ]
	then
		echo "�뽫�ű�����/tmp�£�����/tmp��ִ��"
		exit 1;
	fi
	if [ ! -f /tmp/$anzhuangbao ]
	then
		echo "�뽫��װ��$anzhuangbao����/tmp��"
		exit 1;
	fi
	cp /tmp/$jiaobenming /tmp/tempIFX12.sh
	chmod 777 /tmp/tempIFX12.sh
	
	X86=`uname -m`
	if [ X$X86 != Xx86_64 ]
	then
		log4s error "ϵͳΪ32λ�汾����ʱ��֧��"
		exit 1;
	fi
	FILEsize=`stat -c %s /tmp/$anzhuangbao`
	if [ X$FILEsize != X564142080 ]
	then
		log4s error "�ļ���С����ȷ����˶Ժ��ٽ��У���СӦΪ554557440�ֽ�";
		exit 0;
	fi
	if [ $tXTBB -le 590 ] || [ $tXTBB -ge 710 ]
	then
		echo "ϵͳ�汾�ݲ�֧�֣�����ϵ�ű�������Ա"
		exit 1;
	fi
}
InputAndCheck()
{
	while [[ X$hdrflag != Xhdr  && X$hdrflag != Xonly && X$hdrflag != Xsec && X$hdrflag != Xpri && X$hdrflag != Xclient ]]
	do
		read -p "�����ð�װģʽ��1������ģʽ������only��2������˫��hdrģʽ��������hdr��ֻ������ִ�иýű����ɣ���3����װ�ͻ���ģʽ������client�� " hdrflaginput
		log4s debug "�����hdrflaginput����Ϊ��$hdrflaginput"
		if [ X$hdrflaginput = Xonly ]
		then
			log4s debug "����hdrflag����Ϊonly"
			hdrflag=only
		fi
		if [ X$hdrflaginput = Xhdr ]
		then
			log4s debug "����hdrflag����Ϊpri"
			hdrflag=hdr
		fi 
		if [ X$hdrflaginput = Xclient ]
		then
			log4s debug "����hdrflag����Ϊclient"
			hdrflag=client
		fi 
	done
	if [ X$hdrflag = Xhdr ]
	then
		hdrflag=pri
	fi
	while [[ $peizhiqueren != [Yy] ]]
	do
		#����ģʽ
		if [ X$hdrflaginput = Xonly ]
		then
			log4s info "�������ÿ�ʼ"
			echo "���濪ʼ�������ݿ�ʵ������Ҳ������sqlhosts�����õ����ݿ�ʵ����"
			read -p "����������ʵ����������hdr1��[Ĭ��Ϊhdr1] �� " priINFORMIXSERVER
			log4s debug "���������ʵ����Ϊ$priINFORMIXSERVER"
			if [ X$priINFORMIXSERVER = X ]
			then
				priINFORMIXSERVER=hdr1
				log4s debug "����ʵ����Ϊ�գ���������ʵ����priINFORMIXSERVERΪĬ��ֵhdr1"
				priONCONFIG=onconfig.$priINFORMIXSERVER
				log4s debug "����������priONCONFIGΪonconfig.$priINFORMIXSERVER"
			else
				priONCONFIG=onconfig.${priINFORMIXSERVER}
				log4s debug "���������ʵ����priINFORMIXSERVER��Ϊ�գ�ֵΪ$priINFORMIXSERVER"
				log4s debug "����������priONCONFIGΪonconfig.$priINFORMIXSERVER"
			fi
			read -p "����������ҵ��ʵ����������appdb1��[Ĭ��Ϊappdb1] �� " priDBSERVERALIASES
			log4s debug "�����ҵ��ʵ����priDBSERVERALIASESΪ$priDBSERVERALIASES"
			if [ X$priDBSERVERALIASES = X ]
			then
				priDBSERVERALIASES=appdb1
				log4s debug "�����ҵ��ʵ����Ϊ�գ�priDBSERVERALIASES����ΪĬ��ֵappdb1"
			fi
			echo `ifconfig -a|grep "inet addr"|grep -v '127.0.0.1'|awk '{print $2}'|awk -F':' '{print $2}'`
			echo "�����ip�ǵ�ǰ����������ip���밴����ʾ�������������ip���������ip��ȥ�����鿴"
			read -p "������������ip��"			priip
			read -p "����������ҵ��ip��"	priappip
			echo "�����Ǹղ����������"
			echo "������ʵ������ $priINFORMIXSERVER"
			echo "ҵ��ʵ������   $priDBSERVERALIASES"
			echo "������ip��     $priip"
			echo "ҵ��ʵ��ip��   $priappip"
			log4s debug "�����������ipΪ$priip"
			log4s debug "�����ҵ��ipΪ$priappip"
			read -p "�����Ƿ���ȷ�������ȷ������Y/y��" peizhiqueren
			log4s debug "�����ȷ������Ϊ$peizhiqueren"
		fi
		#hdrģʽ
		if [ X$hdrflaginput = Xhdr ]
		then
			log4s info "hdr���ÿ�ʼ"
			read -p "������������ssh�˿ںţ�һ��Ϊ19222����22��[��Ĭ��ֵ]��"  sshport
			echo "���濪ʼ�������ݿ�ʵ������Ҳ������sqlhosts�����õ����ݿ�ʵ����"
			
			#priINFORMIXSERVER����
			if [ X$peizhiqueren = XXXXXXX ]
			then
				read -p "����������������ʵ������[Ĭ��Ϊhdr1] �� " tpriINFORMIXSERVER
			fi
			if [ X$peizhiqueren != XXXXXXX ]
			then
				read -p "����������������ʵ�������ղ��������$priINFORMIXSERVER �� " tpriINFORMIXSERVER
			fi
			log4s debug "���������������ʵ����Ϊ��$tpriINFORMIXSERVER"
			if [ X$tpriINFORMIXSERVER = X ]
			then
				priINFORMIXSERVER=hdr1
				log4s debug "priINFORMIXSERVERֵΪ�գ�����ΪĬ�ϣ�hdr1"
				priONCONFIG=onconfig.$priINFORMIXSERVER
				log4s debug "�������������ļ���Ϊ��onconfig.$priINFORMIXSERVER"
			else
				priINFORMIXSERVER=$tpriINFORMIXSERVER
				log4s debug "��������priINFORMIXSERVERΪ��$tpriINFORMIXSERVER"
				priONCONFIG=onconfig.${priINFORMIXSERVER}
				log4s debug "���������ļ���Ϊ��$priONCONFIG"
			fi
			if [ X$tpriINFORMIXSERVER = X ]
			then
				priINFORMIXSERVER=$priINFORMIXSERVER
				log4s debug "priINFORMIXSERVERֵΪ�գ�����ΪĬ�ϣ�$priINFORMIXSERVER"
				priONCONFIG=onconfig.$priINFORMIXSERVER
				log4s debug "�������������ļ���Ϊ��onconfig.$priINFORMIXSERVER"
			else
				priINFORMIXSERVER=$tpriINFORMIXSERVER
				log4s debug "��������priINFORMIXSERVERΪ��$tpriINFORMIXSERVER"
				priONCONFIG=onconfig.${priINFORMIXSERVER}
				log4s debug "���������ļ���Ϊ��$priONCONFIG"
			fi
			
			#secINFORMIXSERVER
			if [ X$peizhiqueren = XXXXXXX ]
			then
				read -p "�����뱸��������ʵ������[Ĭ��Ϊhdr2] �� " tsecINFORMIXSERVER
			fi
			if [ X$peizhiqueren != XXXXXXX ]
			then
				read -p "�����뱸��������ʵ�������ղ��������$secINFORMIXSERVER �� " tsecINFORMIXSERVER
			fi
			log4s debug "����ı���������ʵ����Ϊ��$tsecINFORMIXSERVER"
			if [ X$tsecINFORMIXSERVER = X ]
			then
				secINFORMIXSERVER=hdr2
				log4s debug "secINFORMIXSERVERֵΪ�գ�����ΪĬ�ϣ�hdr2"
				secONCONFIG=onconfig.$secINFORMIXSERVER
				log4s debug "���ñ��������ļ���Ϊ��$secONCONFIG"
			else
				secINFORMIXSERVER=$tsecINFORMIXSERVER
				log4s debug "secINFORMIXSERVER����Ϊ��$secINFORMIXSERVER"
				secONCONFIG=onconfig.${secINFORMIXSERVER}
				log4s debug "���������ļ���Ϊ��$secONCONFIG"
			fi
			if [ X$tsecINFORMIXSERVER = X ]
			then
				secINFORMIXSERVER=$secINFORMIXSERVER
				log4s debug "secINFORMIXSERVERֵΪ�գ�����ΪĬ�ϣ�$secINFORMIXSERVER"
				secONCONFIG=onconfig.$secINFORMIXSERVER
				log4s debug "���ñ��������ļ���Ϊ��$secONCONFIG"
			else
				secINFORMIXSERVER=$tsecINFORMIXSERVER
				log4s debug "secINFORMIXSERVER����Ϊ��$secINFORMIXSERVER"
				secONCONFIG=onconfig.${secINFORMIXSERVER}
				log4s debug "���������ļ���Ϊ��$secONCONFIG"
			fi
			
			#priDBSERVERALIASES
			if [ X$peizhiqueren = XXXXXXX ]
			then
				read -p "����������ҵ��ʵ������[Ĭ��Ϊappdb1] �� " tpriDBSERVERALIASES
			fi
			if [ X$peizhiqueren != XXXXXXX ]
			then
				read -p "����������ҵ��ʵ�������ղ��������$priDBSERVERALIASES �� " tpriDBSERVERALIASES
			fi
			log4s debug "��������ҵ��ʵ����Ϊ��$tpriDBSERVERALIASES"
			if [ X$tpriDBSERVERALIASES = X ]
			then
				priDBSERVERALIASES=appdb1
				log4s debug "���������ҵ��ʵ����Ϊ�գ�����Ĭ��ֵΪ��appdb1"
			else
				priDBSERVERALIASES=$tpriDBSERVERALIASES
				log4s debug "���������ҵ��ʵ����Ϊ��$tpriDBSERVERALIASES"
			fi
			if [ X$tpriDBSERVERALIASES = X ]
			then
				priDBSERVERALIASES=$priDBSERVERALIASES
				log4s debug "���������ҵ��ʵ����Ϊ�գ�����Ĭ��ֵΪ��$priDBSERVERALIASES"
			else
				priDBSERVERALIASES=$tpriDBSERVERALIASES
				log4s debug "���������ҵ��ʵ����Ϊ��$tpriDBSERVERALIASES"
			fi
			
			#secDBSERVERALIASES
			if [ X$peizhiqueren = XXXXXXX ]
			then
				read -p "�����뱸��ҵ��ʵ������[Ĭ��Ϊappdb2] �� " tsecDBSERVERALIASES
			fi
			if [ X$peizhiqueren != XXXXXXX ]
			then
				read -p "�����뱸��ҵ��ʵ�������ղ��������$secDBSERVERALIASES �� " tsecDBSERVERALIASES
			fi
			log4s debug "����ı���ҵ��ʵ����Ϊ��$tsecDBSERVERALIASES"
			if [ X$tsecDBSERVERALIASES = X ]
			then
				secDBSERVERALIASES=appdb2
				log4s debug "����ı�ҵ��ʵ����Ϊ�գ�����Ĭ��ֵΪ��appdb2"
			else
				secDBSERVERALIASES=$tsecDBSERVERALIASES
				log4s debug "����ı���ҵ��ʵ����Ϊ��$tsecDBSERVERALIASES"
			fi
			if [ X$tsecDBSERVERALIASES = X ]
			then
				secDBSERVERALIASES=$secDBSERVERALIASES
				log4s debug "����ı�ҵ��ʵ����Ϊ�գ�����Ĭ��ֵΪ��$secDBSERVERALIASES"
			else
				secDBSERVERALIASES=$tsecDBSERVERALIASES
				log4s debug "����ı���ҵ��ʵ����Ϊ��$tsecDBSERVERALIASES"
			fi
			
			echo `ifconfig -a|grep "inet addr"|grep -v '127.0.0.1'|awk '{print $2}'|awk -F':' '{print $2}'`
			echo "�����ip�ǵ�ǰ����������ip���밴����ʾ�������������ip���������ip��ȥ�����鿴"
			#priip
			if [ X$peizhiqueren = XXXXXXX ]
			then
				read -p "����������������ip��[��Ĭ��ֵ]��"	priip
				read -p "�����뱸��������ip��[��Ĭ��ֵ]��"	secip
				read -p "����������ҵ��ip��[��Ĭ��ֵ]��"		priappip
				read -p "�����뱸��ҵ��ip��[��Ĭ��ֵ]��"		secappip
			fi
			if [ X$peizhiqueren != XXXXXXX ]
			then
				read -p "����������������ip���ղ��������$priip��"		priip
				read -p "�����뱸��������ip���ղ��������$secip��"		secip
				read -p "����������ҵ��ip���ղ��������$priappip��"		priappip
				read -p "�����뱸��ҵ��ip���ղ��������$secappip��"		secappip
			fi
			log4s debug "����������������ip��[��Ĭ��ֵ]�� $priip"
			log4s debug "�����뱸��������ip��[��Ĭ��ֵ]�� $secip"
			log4s debug "����������ҵ��ip��[��Ĭ��ֵ]��   $priappip"
			log4s debug "�����뱸��ҵ��ip��[��Ĭ��ֵ]��   $secappip"
			
			echo "�����Ǹղ����������"
			echo "����������ʵ������  ${priINFORMIXSERVER}"
			echo "����������ʵ������  ${secINFORMIXSERVER}"
			echo "����ҵ��ʵ������    ${priDBSERVERALIASES}"
			echo "����ҵ��ʵ������    ${secDBSERVERALIASES}"
			echo "����������ip��      ${priip}"
			echo "����������ip��      ${secip}"
			echo "����ҵ��ip��        ${priappip}"
			echo "����ҵ��ip��        ${secappip}"
	
			read -p "�����Ƿ���ȷ�������ȷ������Y/y��[Ĭ��ֵΪn]��" peizhiqueren
			log4s debug "�����ȷ������peizhiquerenΪ��$peizhiqueren"
			#��ֹ����peizhiqueren=XXXXXX���»��Գ�����
			if [ X$peizhiqueren = XXXXXXX ]
			then
				peizhiqueren=N
			fi
			

			#У���������
			if [ X$peizhiqueren = XY ] || [ X$peizhiqueren = Xy ]
			then
				PpriINFORMIXSERVER=`Pstr $priINFORMIXSERVER`
				PsecINFORMIXSERVER=`Pstr $secINFORMIXSERVER`
				PpriDBSERVERALIASES=`Pstr $priDBSERVERALIASES`
				PsecDBSERVERALIASES=`Pstr $secDBSERVERALIASES`
				Ppriip=`Pip $priip`
				Psecip=`Pip $secip`
				Ppriappip=`Pip $priappip`
				Psecappip=`Pip $secappip`
				if [ X$PpriINFORMIXSERVER != Xok ]
				then
					echo "����������ʵ����������������ϸ���"
					peizhiqueren=N
				fi
				if [ X$PsecINFORMIXSERVER != Xok ]
				then
					echo "����������ʵ����������������ϸ���"
					peizhiqueren=N
				fi
				if [ X$PpriDBSERVERALIASES != Xok ]
				then
					echo "����ҵ��ʵ����������������ϸ���"
					peizhiqueren=N
				fi
				if [ X$PsecDBSERVERALIASES != Xok ]
				then
					echo "����ҵ��ʵ����������������ϸ���"
					peizhiqueren=N
				fi
				
				if [ X$Ppriip != Xok ]
				then
					echo "����������ip������������ϸ���"
					peizhiqueren=N
				fi
				if [ X$Psecip != Xok ]
				then
					echo "����������ip������������ϸ���"
					peizhiqueren=N
				fi
				if [ X$Ppriappip != Xok ]
				then
					echo "����ҵ��ip������������ϸ���"
					peizhiqueren=N
				fi
				if [ X$Psecappip != Xok ]
				then
					echo "����ҵ��ip������������ϸ���"
					peizhiqueren=N
				fi
			fi
		fi
		
	done
	#���������ļ�
	if [ X$hdrflag = Xpri ]
	then
		ONCONFIG=$priONCONFIG
		INFORMIXSERVER=$priINFORMIXSERVER
		DBSERVERNAME=$priDBSERVERNAME
		DBSERVERALIASES=$priDBSERVERALIASES
	fi
	if [ X$hdrflag = Xsec ]
	then
		ONCONFIG=$secONCONFIG
		INFORMIXSERVER=$secINFORMIXSERVER
		DBSERVERNAME=$secDBSERVERNAME
		DBSERVERALIASES=$secDBSERVERALIASES
	fi
	#���̻���
		#����pv
	while [[ $shifouchuangjianpv != [YyNn] ]]
	do
		read -p "�Ƿ���Ҫ����PV���������pv��������y/n��[Ĭ��ΪN]��" shifouchuangjianpv;
	done
	if [ X$shifouchuangjianpv = Xy ] || [ X$shifouchuangjianpv = XY ]
	then
		#������ж�devname��Ϊ�˱����õ���devname����Ҫ������devname�ˣ�����Ҫ������
		shifouchuangjianpv=y
		log4s info "��Ҫ����pv"
		if [ X$devname = XXXXXXX ]
		then
			while [[ $shifouqueredevname != [Yy] ]]
			do
				shifouqueredevname=y
				read -p "������Ӳ��ȫ·��������/dev/sdb��[û��Ĭ��ֵ]��"  devname
				read -p "�����ȷ��Ӳ��·���Ƿ�Ϊ$devname��������������ɲ���Ԥ֪������[Y/N]��[Ĭ��ΪN]��" shifouqueredevname
				log4s debug "shifouqueredevname��ֵΪ$shifouqueredevname"
				log4s debug "����pv��·��Ϊ$devname"
				if [ X$shifouqueredevname != XY ] && [ X$shifouqueredevname != Xy ]
				then
					shifouqueredevname=N
				fi
			done
		fi
	else
		shifouchuangjianpv=n
	fi
	
		#����vg
	while [[ $shifouchuangjianvg != [YyNn] ]]
	do
		read -p "�Ƿ���Ҫ����VG���������vg��������y/n��[Ĭ��Ϊ������]��" shifouchuangjianvg;
	done
	if [ X$shifouchuangjianvg = Xy ] || [ X$shifouchuangjianvg = XY ]
	then
		log4s info "��Ҫ����vg"
		while [[ $shifouqueredevname1 != [Yy] ]]
		do
			if [ X$devname = XXXXXXX ]
			then
				read -p "������pv�����ƣ�����/dev/sdb��[û��Ĭ��ֵ]��"  devname
				log4s info "pv���ֶ�������������Ҫ���봴����pv���ƣ�Ϊ��$devname"
			fi
			read -p "������vg�����ƣ�����dbvg��[û��Ĭ��ֵ]��" vgname;
			read -p "�����ȷ��vg�����Ƿ�Ϊ$vgname��������������ɲ���Ԥ֪������[Y/N]��[Ĭ��Ϊ������]��" shifouqueredevname1
			if [ X$shifouqueredevname1 != XY ] && [ X$shifouqueredevname1 != Xy ]
			then
				shifouqueredevname1=N
			fi
		done
	else
	shifouchuangjianvg=n
	fi
	
	#����lv
	while [[ $shifouchuangjianlv != [YyNn] ]]
	do
		read -p "�Ƿ���Ҫ����LV���������LV��������y/n��[Ĭ��Ϊ������]��" shifouchuangjianlv;
		if [ X$shifouchuangjianlv != XY ] && [ X$shifouchuangjianlv != Xy ]
		then
			shifouchuangjianlv=n
		fi
	done
	if [ X$shifouchuangjianlv = Xy ] || [ X$shifouchuangjianlv = XY ]
	then
		log4s info "��Ҫ����lv"
		if [ X$shifouchuangjianvg = XN ] || [ X$shifouchuangjianvg = Xn ]
		then
			log4s info "֮ǰû��ͨ���ű�����vg����Ҫָ��vg���ƺ�devname"
			if [ X$hdrflag = Xsec ]
			then
				log4s info "�����Զ��Զ���ȡ����"
			else
				read -p "������vg���ƣ�����dbvg��[û��Ĭ��ֵ]��"  vgname
				read -p "������pv�����ƣ�����/dev/sdb��[û��Ĭ��ֵ]��"  devname
				log4s info "vg���ֶ������ģ���Ҫ����vg��pv�����ƣ�vg����Ϊ��$vgname��pv������Ϊ$devname"
			fi
		fi
		while [[ $shifoutiaozhenglvsize != [YyNn] ]]
		do
			echo "Ĭ��lv��СΪrootdbs=$tsizerootdbs1G,tempdbs1=$tsizetempdbs1G,tempdbs2=$tsizetempdbs2G,logdbs1=$tsizelogdbs1G,phydbs1=$tsizephydbs1G,userdbs1=$tsizeuserdbs1G����λΪG"
			read -p "�Ƿ���Ҫ����lv��С��������y/n��[Ĭ��Ϊn]��" shifoutiaozhenglvsize;
			if [ X$shifoutiaozhenglvsize != XY ] && [ X$shifoutiaozhenglvsize != Xy ]
			then
				shifoutiaozhenglvsize=n
			fi
		done
		if [ X$shifoutiaozhenglvsize = Xy ] || [ X$shifoutiaozhenglvsize = XY ]
		then
			while [[ $shifouquerenlvsize != [Yy] ]]
			do
				echo "�����������Ĵ�С����λΪG��ֻ��Ҫ�������ּ��ɣ���ȷ��Ӳ�̴�С��������������lv"
				echo "�������Ҫĳ��dbs��[Ĭ��Ϊ0]��"
				read -p "rootdbs1��С��"		sizerootdbs1G
				read -p "tempdbs1��С��"		sizetempdbs1G
				read -p "tempdbs2��С��"		sizetempdbs2G
				read -p "logdbs1��С��"			sizelogdbs1G
				read -p "phydbs1��С��"			sizephydbs1G
				read -p "userdbs1��С��"		sizeuserdbs1G
				read -p "userdbs2��С��"		sizeuserdbs2G
				read -p "userdbs3��С��"		sizeuserdbs3G
				read -p "userdbs4��С��"		sizeuserdbs4G
				read -p "userdbs5��С��"		sizeuserdbs5G
				read -p "chargedbs1��С��"	sizechargedbs1G
				read -p "chargedbs2��С��"	sizechargedbs2G
				read -p "minfodbs1��С��"		sizeminfodbs1G
				read -p "minfodbs2��С��"		sizeminfodbs2G
				read -p "servdbs1��С��"		sizeservdbs1G
				read -p "servdbs2��С��"		sizeservdbs2G
				if [ X$sizerootdbs1G = X ] || [ X$sizerootdbs1G = XN ] || [ X$sizerootdbs1G = Xn ] || [ X$sizerootdbs1G = X0 ]
				then
					sizerootdbs1G=0
				fi
				if [ X$sizetempdbs1G = X ] || [ X$sizetempdbs1G = XN ] || [ X$sizetempdbs1G = Xn ] || [ X$sizetempdbs1G = X0 ]
				then
					sizetempdbs1G=0
				fi
				if [ X$sizetempdbs2G = X ] || [ X$sizetempdbs2G = XN ] || [ X$sizetempdbs2G = Xn ] || [ X$sizetempdbs2G = X0 ]
				then
					sizetempdbs2G=0
				fi
				if [ X$sizelogdbs1G = X ] || [ X$sizelogdbs1G = XN ] || [ X$sizelogdbs1G = Xn ] || [ X$sizelogdbs1G = X0 ]
				then
					sizelogdbs1G=0
				fi
				if [ X$sizephydbs1G = X ] || [ X$sizephydbs1G = XN ] || [ X$sizephydbs1G = Xn ] || [ X$sizephydbs1G = X0 ]
				then
					sizephydbs1G=0
				fi
				if [ X$sizeuserdbs1G = X ] || [ X$sizeuserdbs1G = XN ] || [ X$sizeuserdbs1G = Xn ] || [ X$sizeuserdbs1G = X0 ]
				then
					sizeuserdbs1G=0
				fi
				if [ X$sizeuserdbs2G = X ] || [ X$sizeuserdbs2G = XN ] || [ X$sizeuserdbs2G = Xn ] || [ X$sizeuserdbs2G = X0 ]
				then
					sizeuserdbs2G=0
				fi
				if [ X$sizeuserdbs3G = X ] || [ X$sizeuserdbs3G = XN ] || [ X$sizeuserdbs3G = Xn ] || [ X$sizeuserdbs3G = X0 ]
				then
					sizeuserdbs3G=0
				fi
				if [ X$sizeuserdbs4G = X ] || [ X$sizeuserdbs4G = XN ] || [ X$sizeuserdbs4G = Xn ] || [ X$sizeuserdbs4G = X0 ]
				then
					sizeuserdbs4G=0
				fi
				if [ X$sizeuserdbs5G = X ] || [ X$sizeuserdbs5G = XN ] || [ X$sizeuserdbs5G = Xn ] || [ X$sizeuserdbs5G = X0 ]
				then
					sizeuserdbs5G=0
				fi
				if [ X$sizechargedbs1G = X ] || [ X$sizechargedbs1G = XN ] || [ X$sizechargedbs1G = Xn ] || [ X$sizechargedbs1G = X0 ]
				then
					sizechargedbs1G=0
				fi
				if [ X$sizechargedbs2G = X ] || [ X$sizechargedbs2G = XN ] || [ X$sizechargedbs2G = Xn ] || [ X$sizechargedbs2G = X0 ]
				then
					sizechargedbs2G=0
				fi
				if [ X$sizeminfodbs1G = X ] || [ X$sizeminfodbs1G = XN ] || [ X$sizeminfodbs1G = Xn ] || [ X$sizeminfodbs1G = X0 ]
				then
					sizeminfodbs1G=0
				fi
				if [ X$sizeminfodbs2G = X ] || [ X$sizeminfodbs2G = XN ] || [ X$sizeminfodbs2G = Xn ] || [ X$sizeminfodbs2G = X0 ]
				then
					sizeminfodbs2G=0
				fi
				if [ X$sizeservdbs1G = X ] || [ X$sizeservdbs1G = XN ] || [ X$sizeservdbs1G = Xn ] || [ X$sizeservdbs1G = X0 ]
				then
					sizeservdbs1G=0
				fi
				if [ X$sizeservdbs2G = X ] || [ X$sizeservdbs2G = XN ] || [ X$sizeservdbs2G = Xn ] || [ X$sizeservdbs2G = X0 ]
				then
					sizeservdbs2G=0
				fi
				echo "���µ�����Ĵ�С���£�"
				echo "rootdbs1��С��      $sizerootdbs1G"
				echo "tempdbs1��С��      $sizetempdbs1G"
				echo "tempdbs2��С��      $sizetempdbs2G"
				echo "logdbs1��С��       $sizelogdbs1G"
				echo "phydbs1��С��       $sizephydbs1G"
				echo "userdbs1��С��      $sizeuserdbs1G"
				echo "userdbs2��С��      $sizeuserdbs2G"
				echo "userdbs3��С��      $sizeuserdbs3G"
				echo "userdbs4��С��      $sizeuserdbs4G"
				echo "userdbs5��С��      $sizeuserdbs5G"
				echo "chargedbs1��С��    $sizechargedbs1G"
				echo "chargedbs2��С��    $sizechargedbs2G"
				echo "minfodbs1��С��     $sizeminfodbs1G"
				echo "minfodbs2��С��     $sizeminfodbs2G"
				echo "sizeservdbs1��С��  $sizeservdbs1G"
				echo "sizeservdbs2��С��  $sizeservdbs2G"
				read -p "�Ƿ�ȷ�ϵ�����Ĵ�С[Y/N]��" shifouquerenlvsize
				#���ж��Ƿ����д�С��������
				Prootdbs1=`Pnum "$sizerootdbs1G"`
				Ptempdbs1=`Pnum "$sizetempdbs1G"`
				Ptempdbs2=`Pnum "$sizetempdbs2G"`
				Plogdbs1=`Pnum "$sizelogdbs1G"`
				Pphydbs1=`Pnum "$sizephydbs1G"`
				Puserdbs1=`Pnum "$sizeuserdbs1G"`
				Puserdbs2=`Pnum "$sizeuserdbs2G"`
				Puserdbs3=`Pnum "$sizeuserdbs3G"`
				Puserdbs4=`Pnum "$sizeuserdbs4G"`
				Puserdbs5=`Pnum "$sizeuserdbs5G"`
				Pchargedbs1=`Pnum "$sizechargedbs1G"`
				Pchargedbs2=`Pnum "$sizechargedbs2G"`
				Pminfodbs1=`Pnum "$sizeminfodbs1G"`
				Pminfodbs2=`Pnum "$sizeminfodbs2G"`
				Psizeservdbs1G=`Pnum "$sizeservdbs1G"`
				Psizeservdbs2G=`Pnum "$sizeservdbs2G"`
				if [ $Prootdbs1 = no ] || [ $Ptempdbs1 = no ] || [ $Ptempdbs2 = no ] || [ $Plogdbs1 = no ] || [ $Pphydbs1 = no ] || [ $Puserdbs1 = no ] || [ $Puserdbs2 = no ] || [ $Puserdbs3 = no ] || [ $Puserdbs4 = no ] || [ $Puserdbs5 = no ] || [ $Pchargedbs1 = no ] || [ $Pchargedbs2 = no ] || [ $Pminfodbs1 = no ] || [ $Pminfodbs2 = no ] || [ $Psizeservdbs1G = no ] || [ $Psizeservdbs2G = no ]
				then
					echo "����dbs�в�Ϊ���ֵ���������������롣"
					shifouquerenlvsize=n
					continue;
				fi
				if [ X$sizerootdbs1G = X0 ]
				then
					echo "rootdbs1����Ϊ0"
					shifouquerenlvsize=n
					continue;
				fi
				if [ X$sizetempdbs1G = X0 ]
				then
					echo "tempdbs1"
					shifouquerenlvsize=n
					continue;
				fi
				if [ X$sizelogdbs1G = X0 ]
				then
					echo "logdbs1����Ϊ0"
					shifouquerenlvsize=n
					continue;
				fi
				if [ X$sizephydbs1G = X0 ]
				then
					echo "phydbs1����Ϊ0"
					shifouquerenlvsize=n
					continue;
				fi
				if [ X$sizeuserdbs1G = X0 ]
				then
					echo "userdbs1����Ϊ0"
					shifouquerenlvsize=n
					continue;
				fi
				if [ X$shifouquerenlvsize != XY ] && [ X$shifouquerenlvsize != Xy ]
				then
					shifouquerenlvsize=n
				fi
				
			done
		fi
		if [ $shifoutiaozhenglvsize = n ] || [ $shifoutiaozhenglvsize = N ]
		then
			sizerootdbs1G=$tsizerootdbs1G
			sizetempdbs1G=$tsizetempdbs1G
			sizetempdbs2G=$tsizetempdbs2G
			sizelogdbs1G=$tsizelogdbs1G
			sizephydbs1G=$tsizephydbs1G
			sizeuserdbs1G=$tsizeuserdbs1G
			sizeuserdbs2G=0
			sizeuserdbs3G=0
			sizeuserdbs4G=0
			sizeuserdbs5G=0
			sizeminfodbs1G=0
			sizeminfodbs2G=0
			sizeservdbs1G=0
			sizeservdbs2G=0
			sizechargedbs1G=0
			sizechargedbs2G=0
		fi
		lvrootdbs1=/dev/$vgname/rootdbs1
		lvtempdbs1=/dev/$vgname/tempdbs1
		lvtempdbs2=/dev/$vgname/tempdbs2
		lvlogdbs1=/dev/$vgname/logdbs1
		lvphydbs1=/dev/$vgname/phydbs1
		lvuserdbs1=/dev/$vgname/userdbs1
		lvuserdbs2=/dev/$vgname/userdbs2
		lvuserdbs3=/dev/$vgname/userdbs3
		lvuserdbs4=/dev/$vgname/userdbs4
		lvuserdbs5=/dev/$vgname/userdbs5
		lvchargedbs1=/dev/$vgname/chargedbs1
		lvchargedbs2=/dev/$vgname/chargedbs2
		lvminfodbs1=/dev/$vgname/minfodbs1
		lvminfodbs2=/dev/$vgname/minfodbs2
		lvservdbs1=/dev/$vgname/servdbs1
		lvservdbs2=/dev/$vgname/servdbs2
		shifouquerenlvsize=y
		lvmuluqueren=y
	fi
		#������lv
	if [ $shifouchuangjianlv = N ] || [ $shifouchuangjianlv = n ]
	then
		log4s info "����Ҫ����lv��ָ��lvĿ¼"
		while [[ $lvmuluqueren != [Yy] ]]
		do
			if [ $muban = cl ]
			then
				read -p "������vg���ƣ�����dbvg��[û��Ĭ��ֵ]��" vgname
				echo "�������ʾ�����lv��Ŀ¼������/dev/hdvg/rootdbs1"
				echo "���û�����dbs��[Ĭ��Ϊ������]"
				read -p "rootdbs1��Ŀ¼��"		lvrootdbs1
				read -p "tempdbs1��Ŀ¼��"		lvtempdbs1
				read -p "tempdbs2��Ŀ¼��"		lvtempdbs2
				read -p "logdbs1��Ŀ¼��"			lvlogdbs1
				read -p "phydbs1��Ŀ¼��"			lvphydbs1
				read -p "userdbs1��Ŀ¼��"		lvuserdbs1
				read -p "userdbs2��Ŀ¼��"		lvuserdbs2
				read -p "userdbs3��Ŀ¼��"		lvuserdbs3
				read -p "userdbs4��Ŀ¼��"		lvuserdbs4
				read -p "userdbs5��Ŀ¼��"		lvuserdbs5
				read -p "chargedbs1��Ŀ¼��"	lvchargedbs1
				read -p "chargedbs2��Ŀ¼��"	lvchargedbs2
				read -p "minfodbs1��Ŀ¼��"		lvminfodbs1
				read -p "minfodbs2��Ŀ¼��"		lvminfodbs2
				read -p "servdbs1��Ŀ¼��"		lvservdbs1
				read -p "servdbs2��Ŀ¼��"		lvservdbs2
				if [ X$lvrootdbs1 = X ] || [ X$lvrootdbs1 = XN ] || [ X$lvrootdbs1 = Xn ] || [ X$lvrootdbs1 = X0 ]
				then
					lvrootdbs1=0
				fi
				if [ X$lvtempdbs1 = X ] || [ X$lvtempdbs1 = XN ] || [ X$lvtempdbs1 = Xn ] || [ X$lvtempdbs1 = X0 ]
				then
					lvtempdbs1=0
				fi
				if [ X$lvtempdbs2 = X ] || [ X$lvtempdbs2 = XN ] || [ X$lvtempdbs2 = Xn ] || [ X$lvtempdbs2 = X0 ]
				then
					lvtempdbs2=0
				fi
				if [ X$lvlogdbs1 = X ] || [ X$lvlogdbs1 = XN ] || [ X$lvlogdbs1 = Xn ] || [ X$lvlogdbs1 = X0 ]
				then
					lvlogdbs1=0
				fi
				if [ X$lvphydbs1 = X ] || [ X$lvphydbs1 = XN ] || [ X$lvphydbs1 = Xn ] || [ X$lvphydbs1 = X0 ]
				then
					lvphydbs1=0
				fi
				if [ X$lvuserdbs1 = X ] || [ X$lvuserdbs1 = XN ] || [ X$lvuserdbs1 = Xn ] || [ X$lvuserdbs1 = X0 ]
				then
					lvuserdbs1=0
				fi
				if [ X$lvuserdbs2 = X ] || [ X$lvuserdbs2 = XN ] || [ X$lvuserdbs2 = Xn ] || [ X$lvuserdbs2 = X0 ]
				then
					lvuserdbs2=0
				fi
				if [ X$lvuserdbs3 = X ] || [ X$lvuserdbs3 = XN ] || [ X$lvuserdbs3 = Xn ] || [ X$lvuserdbs3 = X0 ]
				then
					lvuserdbs3=0
				fi
				if [ X$lvuserdbs4 = X ] || [ X$lvuserdbs4 = XN ] || [ X$lvuserdbs4 = Xn ] || [ X$lvuserdbs4 = X0 ]
				then
					lvuserdbs4=0
				fi
				if [ X$lvuserdbs5 = X ] || [ X$lvuserdbs5 = XN ] || [ X$lvuserdbs5 = Xn ] || [ X$lvuserdbs5 = X0 ]
				then
					lvuserdbs5=0
				fi
				if [ X$lvchargedbs1 = X ] || [ X$lvchargedbs1 = XN ] || [ X$lvchargedbs1 = Xn ] || [ X$lvchargedbs1 = X0 ]
				then
					lvchargedbs1=0
				fi
				if [ X$lvchargedbs2 = X ] || [ X$lvchargedbs2 = XN ] || [ X$lvchargedbs2 = Xn ] || [ X$lvchargedbs2 = X0 ]
				then
					lvchargedbs2=0
				fi
				if [ X$lvminfodbs1 = X ] || [ X$lvminfodbs1 = XN ] || [ X$lvminfodbs1 = Xn ] || [ X$lvminfodbs1 = X0 ]
				then
					lvminfodbs1=0
				fi
				if [ X$lvminfodbs2 = X ] || [ X$lvminfodbs2 = XN ] || [ X$lvminfodbs2 = Xn ] || [ X$lvminfodbs2 = X0 ]
				then
					lvminfodbs2=0
				fi
				if [ X$lvservdbs1 = X ] || [ X$lvservdbs1 = XN ] || [ X$lvservdbs1 = Xn ] || [ X$lvservdbs1 = X0 ]
				then
					lvservdbs1=0
				fi
				if [ X$lvservdbs2 = X ] || [ X$lvservdbs2 = XN ] || [ X$lvservdbs2 = Xn ] || [ X$lvservdbs2 = X0 ]
				then
					lvservdbs2=0
				fi

				echo "���õ�dbsĿ¼�������£���ȷ��[Y/N]��"
				echo "rootdbs1��Ŀ¼��    $lvrootdbs1" 
				echo "tempdbs1��Ŀ¼��    $lvtempdbs1" 
				echo "tempdbs2��Ŀ¼��    $lvtempdbs2" 
				echo "logdbs1��Ŀ¼��     $lvlogdbs1"
				echo "phydbs1��Ŀ¼��     $lvphydbs1"
				echo "userdbs1��Ŀ¼��    $lvuserdbs1"
				echo "userdbs2��Ŀ¼��    $lvuserdbs2"
				echo "userdbs3��Ŀ¼��    $lvuserdbs3"
				echo "userdbs4��Ŀ¼��    $lvuserdbs4"
				echo "userdbs5��Ŀ¼��    $lvuserdbs5"
				echo "chargedbs1��Ŀ¼��  $lvchargedbs1"
				echo "chargedbs2��Ŀ¼��  $lvchargedbs2"
				echo "minfodbs1��Ŀ¼��   $lvminfodbs1"
				echo "minfodbs2��Ŀ¼��   $lvminfodbs2"
				echo "servdbs1��Ŀ¼��    $lvservdbs1"
				echo "servdbs2��Ŀ¼��    $lvservdbs2"
				read -p "�Ƿ�ȷ�ϣ�[y/n]��[Ĭ��Ϊn]��" lvmuluqueren
				if [ X$lvmuluqueren != XY ] && [ X$lvmuluqueren != Xy ]
				then
					lvmuluqueren=n
				fi
				if [ X$lvrootdbs1 = X ] || [ X$lvrootdbs1 = XN ] || [ X$lvrootdbs1 = Xn ] || [ X$lvrootdbs1 = X0 ]
				then
					lvrootdbs1=0
				fi
			fi
		done
		while [[ $shifouquerenlvsize != [Yy] ]]
		do
			echo "�������õĸ�dbs�Ĵ�С����λΪG��ֻ��Ҫ�������ּ��ɣ���ȷ��ʵ��lv��С����dbs"
			echo "�������Ҫĳ��dbs�����ô�СΪ0����N����n���߲����붼���ԡ�"
			echo "rootdbs1��Ŀ¼��    $lvrootdbs1" 
			read -p "rootdbs1��С��"		sizerootdbs1G
			echo "tempdbs1��Ŀ¼��    $lvtempdbs1" 
			read -p "tempdbs1��С��"		sizetempdbs1G
			echo "tempdbs2��Ŀ¼��    $lvtempdbs2" 
			read -p "tempdbs2��С��"		sizetempdbs2G
			echo "logdbs1��Ŀ¼��     $lvlogdbs1"
			read -p "logdbs1��С��"			sizelogdbs1G
			echo "phydbs1��Ŀ¼��     $lvphydbs1"
			read -p "phydbs1��С��"			sizephydbs1G
			echo "userdbs1��Ŀ¼��    $lvuserdbs1"
			read -p "userdbs1��С��"		sizeuserdbs1G
			echo "userdbs2��Ŀ¼��    $lvuserdbs2"
			read -p "userdbs2��С��"		sizeuserdbs2G
			echo "userdbs3��Ŀ¼��    $lvuserdbs3"
			read -p "userdbs3��С��"		sizeuserdbs3G
			echo "userdbs4��Ŀ¼��    $lvuserdbs4"
			read -p "userdbs4��С��"		sizeuserdbs4G
			echo "userdbs5��Ŀ¼��    $lvuserdbs5"
			read -p "userdbs5��С��"		sizeuserdbs5G
			echo "chargedbs1��Ŀ¼��  $lvchargedbs1"
			read -p "chargedbs1��С��"	sizechargedbs1G
			echo "chargedbs2��Ŀ¼��  $lvchargedbs2"
			read -p "chargedbs2��С��"	sizechargedbs2G
			echo "minfodbs1��Ŀ¼��   $lvminfodbs1"
			read -p "minfodbs1��С��"		sizeminfodbs1G
			echo "minfodbs2��Ŀ¼��   $lvminfodbs2"
			read -p "minfodbs2��С��"		sizeminfodbs2G
			echo "servdbs1��Ŀ¼��    $lvservdbs1"
			read -p "servdbs1��С��"		sizeservdbs1G
			echo "servdbs2��Ŀ¼��    $lvservdbs2"
			read -p "servdbs2��С��"		sizeservdbs2G
			if [ X$sizerootdbs1G = X ] || [ X$sizerootdbs1G = XN ] || [ X$sizerootdbs1G = Xn ] || [ X$sizerootdbs1G = X0 ]
			then
				sizerootdbs1G=0
			fi
			if [ X$sizetempdbs1G = X ] || [ X$sizetempdbs1G = XN ] || [ X$sizetempdbs1G = Xn ] || [ X$sizetempdbs1G = X0 ]
			then
				sizetempdbs1G=0
			fi
			if [ X$sizetempdbs2G = X ] || [ X$sizetempdbs2G = XN ] || [ X$sizetempdbs2G = Xn ] || [ X$sizetempdbs2G = X0 ]
			then
				sizetempdbs2G=0
			fi
			if [ X$sizelogdbs1G = X ] || [ X$sizelogdbs1G = XN ] || [ X$sizelogdbs1G = Xn ] || [ X$sizelogdbs1G = X0 ]
			then
				sizelogdbs1G=0
			fi
			if [ X$sizephydbs1G = X ] || [ X$sizephydbs1G = XN ] || [ X$sizephydbs1G = Xn ] || [ X$sizephydbs1G = X0 ]
			then
				sizephydbs1G=0
			fi
			if [ X$sizeuserdbs1G = X ] || [ X$sizeuserdbs1G = XN ] || [ X$sizeuserdbs1G = Xn ] || [ X$sizeuserdbs1G = X0 ]
			then
				sizeuserdbs1G=0
			fi
			if [ X$sizeuserdbs2G = X ] || [ X$sizeuserdbs2G = XN ] || [ X$sizeuserdbs2G = Xn ] || [ X$sizeuserdbs2G = X0 ]
			then
				sizeuserdbs2G=0
			fi
			if [ X$sizeuserdbs3G = X ] || [ X$sizeuserdbs3G = XN ] || [ X$sizeuserdbs3G = Xn ] || [ X$sizeuserdbs3G = X0 ]
			then
				sizeuserdbs3G=0
			fi
			if [ X$sizeuserdbs4G = X ] || [ X$sizeuserdbs4G = XN ] || [ X$sizeuserdbs4G = Xn ] || [ X$sizeuserdbs4G = X0 ]
			then
				sizeuserdbs4G=0
			fi
			if [ X$sizeuserdbs5G = X ] || [ X$sizeuserdbs5G = XN ] || [ X$sizeuserdbs5G = Xn ] || [ X$sizeuserdbs5G = X0 ]
			then
				sizeuserdbs5G=0
			fi
			if [ X$sizechargedbs1G = X ] || [ X$sizechargedbs1G = XN ] || [ X$sizechargedbs1G = Xn ] || [ X$sizechargedbs1G = X0 ]
			then
				sizechargedbs1G=0
			fi
			if [ X$sizechargedbs2G = X ] || [ X$sizechargedbs2G = XN ] || [ X$sizechargedbs2G = Xn ] || [ X$sizechargedbs2G = X0 ]
			then
				sizechargedbs2G=0
			fi
			if [ X$sizeminfodbs1G = X ] || [ X$sizeminfodbs1G = XN ] || [ X$sizeminfodbs1G = Xn ] || [ X$sizeminfodbs1G = X0 ]
			then
				sizeminfodbs1G=0
			fi
			if [ X$sizeminfodbs2G = X ] || [ X$sizeminfodbs2G = XN ] || [ X$sizeminfodbs2G = Xn ] || [ X$sizeminfodbs2G = X0 ]
			then
				sizeminfodbs2G=0
			fi
			if [ X$sizeservdbs1G = X ] || [ X$sizeservdbs1G = XN ] || [ X$sizeservdbs1G = Xn ] || [ X$sizeservdbs1G = X0 ]
			then
				sizeservdbs1G=0
			fi
			if [ X$sizeservdbs2G = X ] || [ X$sizeservdbs2G = XN ] || [ X$sizeservdbs2G = Xn ] || [ X$sizeservdbs2G = X0 ]
			then
				sizeservdbs2G=0
			fi
			echo "���õ�dbs�Ĵ�С���£�"
			echo "rootdbs1��С��      $sizerootdbs1G"
			echo "tempdbs1��С��      $sizetempdbs1G"
			echo "tempdbs2��С��      $sizetempdbs2G"
			echo "logdbs1��С��       $sizelogdbs1G"
			echo "phydbs1��С��       $sizephydbs1G"
			echo "userdbs1��С��      $sizeuserdbs1G"
			echo "userdbs2��С��      $sizeuserdbs2G"
			echo "userdbs3��С��      $sizeuserdbs3G"
			echo "userdbs4��С��      $sizeuserdbs4G"
			echo "userdbs5��С��      $sizeuserdbs5G"
			echo "chargedbs1��С��    $sizechargedbs1G"
			echo "chargedbs2��С��    $sizechargedbs2G"
			echo "minfodbs1��С��     $sizeminfodbs1G"
			echo "minfodbs2��С��     $sizeminfodbs2G"
			echo "sizeservdbs1��С�� $sizeservdbs1G"
			echo "sizeservdbs2��С�� $sizeservdbs2G"
			read -p "�Ƿ�ȷ�ϵ�����Ĵ�С[Y/N]��[Ĭ��Ϊn]��" shifouquerenlvsize
			#���ж��Ƿ����д�С��������
			Prootdbs1=`Pnum "$sizerootdbs1G"`
			Ptempdbs1=`Pnum "$sizetempdbs1G"`
			Ptempdbs2=`Pnum "$sizetempdbs2G"`
			Plogdbs1=`Pnum "$sizelogdbs1G"`
			Pphydbs1=`Pnum "$sizephydbs1G"`
			Puserdbs1=`Pnum "$sizeuserdbs1G"`
			Puserdbs2=`Pnum "$sizeuserdbs2G"`
			Puserdbs3=`Pnum "$sizeuserdbs3G"`
			Puserdbs4=`Pnum "$sizeuserdbs4G"`
			Puserdbs5=`Pnum "$sizeuserdbs5G"`
			Pchargedbs1=`Pnum "$sizechargedbs1G"`
			Pchargedbs2=`Pnum "$sizechargedbs2G"`
			Pminfodbs1=`Pnum "$sizeminfodbs1G"`
			Pminfodbs2=`Pnum "$sizeminfodbs2G"`
			Psizeservdbs1G=`Pnum "$sizeservdbs1G"`
			Psizeservdbs2G=`Pnum "$sizeservdbs2G"`
			if [ $Prootdbs1 = no ] || [ $Ptempdbs1 = no ] || [ $Ptempdbs2 = no ] || [ $Plogdbs1 = no ] || [ $Pphydbs1 = no ] || [ $Puserdbs1 = no ] || [ $Puserdbs2 = no ] || [ $Puserdbs3 = no ] || [ $Puserdbs4 = no ] || [ $Puserdbs5 = no ] || [ $Pchargedbs1 = no ] || [ $Pchargedbs2 = no ] || [ $Pminfodbs1 = no ] || [ $Pminfodbs2 = no ] || [ $Psizeservdbs1G = no ] || [ $Psizeservdbs2G = no ]
			then
				echo "����dbs�в�Ϊ���ֵ���������������롣"
				shifouquerenlvsize=n
				continue;
			fi
			if [ X$shifouquerenlvsize != Xy ] && [ X$shifouquerenlvsize != XY ]
			then
				shifouquerenlvsize=n
			fi
			Plvsize  $lvrootdbs1      $sizerootdbs1G           rootdbs1   
			Plvsize  $lvtempdbs1      $sizetempdbs1G           tempdbs1   
			Plvsize  $lvtempdbs2      $sizetempdbs2G           tempdbs2   
			Plvsize  $lvlogdbs1       $sizelogdbs1G            logdbs1    
			Plvsize  $lvphydbs1       $sizephydbs1G            phydbs1    
			Plvsize  $lvuserdbs1      $sizeuserdbs1G           userdbs1   
			Plvsize  $lvuserdbs2      $sizeuserdbs2G           userdbs2   
			Plvsize  $lvuserdbs3      $sizeuserdbs3G           userdbs3   
			Plvsize  $lvuserdbs4      $sizeuserdbs4G           userdbs4   
			Plvsize  $lvuserdbs5      $sizeuserdbs5G           userdbs5   
			Plvsize  $lvchargedbs1    $sizechargedbs1G         chargedbs1 
			Plvsize  $lvchargedbs2    $sizechargedbs2G         chargedbs2 
			Plvsize  $lvminfodbs1     $sizeminfodbs1G          minfodbs1  
			Plvsize  $lvminfodbs2     $sizeminfodbs2G          minfodbs2  
			Plvsize  $lvservdbs1      $sizeservdbs1G           servdbs1   
			Plvsize  $lvservdbs2      $sizeservdbs2G           servdbs2   
		done
	fi
	let sizerootdbs1=$sizerootdbs1G*1000000
	let sizetempdbs1=$sizetempdbs1G*1000000
	let sizetempdbs2=$sizetempdbs2G*1000000
	let sizelogdbs1=$sizelogdbs1G*1000000
	let sizephydbs1=$sizephydbs1G*1000000
	let sizeuserdbs1=$sizeuserdbs1G*1000000
	let sizeuserdbs2=$sizeuserdbs2G*1000000
	let sizeuserdbs3=$sizeuserdbs3G*1000000
	let sizeuserdbs4=$sizeuserdbs4G*1000000
	let sizeuserdbs5=$sizeuserdbs5G*1000000
	let sizechargedbs1=$sizechargedbs1G*1000000
	let sizechargedbs2=$sizechargedbs2G*1000000
	let sizeminfodbs1=$sizeminfodbs1G*1000000
	let sizeminfodbs2=$sizeminfodbs2G*1000000
	let sizeservdbs1=$sizeservdbs1G*1000000
	let sizeservdbs2=$sizeservdbs2G
}
ZhanWeiflag()
{
	#��һ�׶Σ���������ռλ���޸�
	if [ X$hdrflag = Xonly ]
	then
		xiugai "hdrflag=XXXXXX"								"hdrflag=only"
	fi
	if [ X$hdrflag = Xpri ]
	then
		#�����ڴ���ļ���һ�£�����Ϊ�ļ��Ǹ������õ�
		xiugai "hdrflag=XXXXXX"								"hdrflag=sec"
	fi
	xiugai "^peizhiqueren=XXXXXX"						"peizhiqueren=$peizhiqueren"
	xiugai "^priINFORMIXSERVER=XXXXXX"				"priINFORMIXSERVER=$priINFORMIXSERVER"
	xiugai "^secINFORMIXSERVER=XXXXXX"				"secINFORMIXSERVER=$secINFORMIXSERVER"
	xiugai "^priDBSERVERALIASES=XXXXXX"			"priDBSERVERALIASES=$priDBSERVERALIASES"
	xiugai "^secDBSERVERALIASES=XXXXXX"			"secDBSERVERALIASES=$secDBSERVERALIASES"
	xiugai "^priip=XXXXXX"										"priip=$priip"
	xiugai "^secip=XXXXXX"										"secip=$secip"
	xiugai "^priappip=XXXXXX"								"priappip=$priappip"
	xiugai "^secappip=XXXXXX"								"secappip=$secappip"
	xiugai "^priONCONFIG=XXXXXX"							"priONCONFIG=$priONCONFIG"
	xiugai "^secONCONFIG=XXXXXX"							"secONCONFIG=$secONCONFIG"
	
	#�ڶ��׶Σ�Ӳ�̻���ռλ���޸�
	xiugai "^shifouchuangjianpv=XXXXXX"			"shifouchuangjianpv=$shifouchuangjianpv"
	xiugai "^shifouqueredevname=XXXXXX"			"shifouqueredevname=$shifouqueredevname"
	xiugai "^devname=XXXXXX"									"devname=$devname"
	
	xiugai "^shifouchuangjianvg=XXXXXX"			"shifouchuangjianvg=$shifouchuangjianvg"
	xiugai "^vgname=XXXXXX"									"vgname=$vgname"
	xiugai "^shifouqueredevname1=XXXXXX"			"shifouqueredevname1=$shifouqueredevname1"
	
	xiugai "^shifouchuangjianlv=XXXXXX"			"shifouchuangjianlv=$shifouchuangjianlv"
	xiugai "^vgname=XXXXXX"									"vgname=$vgname"
	xiugai "^shifoutiaozhenglvsize=XXXXXX"		"shifoutiaozhenglvsize=$shifoutiaozhenglvsize"
	xiugai "^shifouquerenlvsize=XXXXXX"			"shifouquerenlvsize=$shifouquerenlvsize"
	xiugai "^sizerootdbs1G=XXXXXX"						"sizerootdbs1G=$sizerootdbs1G"
	xiugai "^sizetempdbs1G=XXXXXX"						"sizetempdbs1G=$sizetempdbs1G"
	xiugai "^sizetempdbs2G=XXXXXX"						"sizetempdbs2G=$sizetempdbs2G"
	xiugai "^sizelogdbs1G=XXXXXX"						"sizelogdbs1G=$sizelogdbs1G"
	xiugai "^sizephydbs1G=XXXXXX"						"sizephydbs1G=$sizephydbs1G"
	xiugai "^sizeuserdbs1G=XXXXXX"						"sizeuserdbs1G=$sizeuserdbs1G"
	xiugai "^sizeuserdbs2G=XXXXXX"						"sizeuserdbs2G=$sizeuserdbs2G"
	xiugai "^sizeuserdbs3G=XXXXXX"						"sizeuserdbs3G=$sizeuserdbs3G"
	xiugai "^sizeuserdbs4G=XXXXXX"						"sizeuserdbs4G=$sizeuserdbs4G"
	xiugai "^sizeuserdbs5G=XXXXXX"						"sizeuserdbs5G=$sizeuserdbs5G"
	xiugai "^sizechargedbs1G=XXXXXX"					"sizechargedbs1G=$sizechargedbs1G"
	xiugai "^sizechargedbs2G=XXXXXX"					"sizechargedbs2G=$sizechargedbs2G"
	xiugai "^sizeminfodbs1G=XXXXXX"					"sizeminfodbs1G=$sizeminfodbs1G"
	xiugai "^sizeminfodbs2G=XXXXXX"					"sizeminfodbs2G=$sizeminfodbs2G"
	xiugai "^sizeservdbs1G=XXXXXX"						"sizeservdbs1G=$sizeservdbs1G"
	xiugai "^sizeservdbs2G=XXXXXX"						"sizeservdbs2G=$sizeservdbs2G"
	
	xiugai "^lvrootdbs1=XXXXXX"              "lvrootdbs1=$lvrootdbs1"
	xiugai "^lvtempdbs1=XXXXXX"              "lvtempdbs1=$lvtempdbs1"
	xiugai "^lvtempdbs2=XXXXXX"              "lvtempdbs2=$lvtempdbs2"
	xiugai "^lvlogdbs1=XXXXXX"               "lvlogdbs1=$lvlogdbs1"
	xiugai "^lvphydbs1=XXXXXX"               "lvphydbs1=$lvphydbs1"
	xiugai "^lvuserdbs1=XXXXXX"              "lvuserdbs1=$lvuserdbs1"
	xiugai "^lvuserdbs2=XXXXXX"              "lvuserdbs2=$lvuserdbs2"
	xiugai "^lvuserdbs3=XXXXXX"              "lvuserdbs3=$lvuserdbs3"
	xiugai "^lvuserdbs4=XXXXXX"              "lvuserdbs4=$lvuserdbs4"
	xiugai "^lvuserdbs5=XXXXXX"              "lvuserdbs5=$lvuserdbs5"
	xiugai "^lvchargedbs1=XXXXXX"						"lvchargedbs1=$lvchargedbs1"
	xiugai "^lvchargedbs2=XXXXXX"						"lvchargedbs2=$lvchargedbs2"
	xiugai "^lvminfodbs1=XXXXXX"							"lvminfodbs1=$lvminfodbs1"
	xiugai "^lvminfodbs2=XXXXXX"							"lvminfodbs2=$lvminfodbs2"
	xiugai "^lvservdbs1=XXXXXX"							"lvservdbs1=$lvservdbs1"
	xiugai "^lvservdbs2=XXXXXX"							"lvservdbs2=$lvservdbs2"
	xiugai "^lvmuluqueren=XXXXXX"						"lvmuluqueren=$lvmuluqueren"
}
startdisk()
{
	if [ $shifouchuangjianlv = y ] || [ $shifouchuangjianlv = Y ]
	then
		if [ $devname != XXXXXX ]
		then
			if [ $shifouqueredevname = Y ] || [ $shifouqueredevname = y ]
			then
				log4s info "��ʼ����pv"
				makepv $devname
			fi
		fi
	fi
	
	if [ $shifouchuangjianvg = y ] || [ $shifouchuangjianvg = Y ]
	then
		if [ $shifouqueredevname1 = y ] || [ $shifouqueredevname1 = Y ]
		then
			if [ $devname != XXXXXX ] && [ $vgname != XXXXXX ]
			then
				log4s info "��ʼ����vg��vg��Ϊ��$vgname��pv��Ϊ��$devname"
				makevg $vgname $devname
			fi
		fi
	fi
	
	if [ $shifouchuangjianlv = Y ] || [ $shifouchuangjianlv = y ]
	then
		if [ $devname != XXXXXX ]
		then
			if [ $shifouquerenlvsize = y ] || [ $shifouquerenlvsize = Y ]
			then
				if [ $lvmuluqueren = y ] || [ $lvmuluqueren = Y ]
				then
					log4s info "��ʼ����lv"
					makelv rootdbs1		$sizerootdbs1G		$vgname
					makelv tempdbs1		$sizetempdbs1G		$vgname
					makelv tempdbs2		$sizetempdbs2G		$vgname
					makelv logdbs1		$sizelogdbs1G			$vgname
					makelv phydbs1		$sizephydbs1G			$vgname
					makelv userdbs1		$sizeuserdbs1G		$vgname
					makelv userdbs2		$sizeuserdbs2G		$vgname
					makelv userdbs3	  $sizeuserdbs3G		$vgname
					makelv userdbs4		$sizeuserdbs4G		$vgname
					makelv userdbs5		$sizeuserdbs5G		$vgname
					makelv chargedbs1	$sizechargedbs1G	$vgname
					makelv chargedbs2 $sizechargedbs2G	$vgname
					makelv minfodbs1	$sizeminfodbs1G		$vgname
					makelv minfodbs2	$sizeminfodbs2G		$vgname
					makelv servdbs1		$sizeservdbs1G		$vgname
					makelv servdbs2		$sizeservdbs2G		$vgname
				fi
			fi
		fi
	fi
	checklv $lvrootdbs1		$sizerootdbs1G
	checklv $lvtempdbs1		$sizetempdbs1G
	checklv $lvtempdbs2		$sizetempdbs2G
	checklv $lvlogdbs1		$sizelogdbs1G
	checklv $lvphydbs1		$sizephydbs1G
	checklv $lvuserdbs1		$sizeuserdbs1G
	checklv $lvuserdbs2		$sizeuserdbs2G
	checklv $lvuserdbs3		$sizeuserdbs3G
	checklv $lvuserdbs4		$sizeuserdbs4G
	checklv $lvuserdbs5		$sizeuserdbs5G
	checklv $lvchargedbs1	$sizechargedbs1G
	checklv $lvchargedbs2	$sizechargedbs2G
	checklv $lvminfodbs1	$sizeminfodbs1G
	checklv $lvminfodbs2	$sizeminfodbs2G
	checklv $lvservdbs1		$sizeservdbs1G
	checklv $lvservdbs2		$sizeservdbs2G
}










#####################������############
huifu()
{
	log4s info "ȡ��rsh����������"
	tihuanbasic ".*disable.*" "        disable                 = yes" /etc/xinetd.d/rsh
	/etc/rc.d/init.d/xinetd restart
	tihuanbasic "rsh" "" /etc/securetty

}
beijihuifu()
{	
	echo "beijidengdaihuifu" > /tmp/dengdaihuifu.txt
	beijikaishihuifuflag=`nc -l $tongxinduankou2 </tmp/dengdaihuifu.txt`
	if [ X$beijikaishihuifuflag = Xbeijikaishihuifu ]
	then
	  huifu
	  killall nc
	fi

}
zhujihuifu(){

	log4s info "ȡ���ű���������"

	rm -rf /tmp/temp.sh

}
beijijianting1()
{
	echo "secbootok" > /tmp/bootok.txt
	tempflag=`nc -l $tongxinduankou1 </tmp/bootok.txt`
	if [ X$tempflag = Xkaishihdr ]
	then
		log4s info  "��֪ͨ����������װ��ɣ��ȴ������hdr"
		log4s debug "�Ѿ�������������1"
	  beijihuifu;
	  killall nc
	fi

}

#############��װ��##########################
#�ж��Ƿ��Ѿ��������װ�ɹ���������δ��������������װ���ں˲����������������ͽ�������Ĳ��衣
anzhuang()
{
	stty erase ^H;
	CheckP;
	InputAndCheck;
	ZhanWeiflag;
	startdisk;

	if [ ! -d $idshome ]
	then
		log4s info "������װĿ¼"
		mkdir $idshome
	fi
	peizhi=$idshome/etc/$ONCONFIG
	wai=`whoami`
	if [ X$wai != Xroot ]
	then
	log4s error "��ʹ��root�˻����а�װ"
	exit 1;
	fi
	if [ X$X86 != Xx86_64 ]
	then
		log4s error "ϵͳΪ32λ�汾����ʱ��֧��"
		exit 1;
	fi
	if [ ! -f /tmp/$jiaobenming ]
	then
		log4s error "�뽫���ű�����/tmp�ļ�����"
		exit 1;
	fi
	if [ ! -f /tmp/$anzhuangbao ]
	then
		log4s error "�뽫$anzhuangbao�ŵ�/tmp��";
		exit 1;
	fi
	FILEsize=`stat -c %s /tmp/$anzhuangbao`
	if [ X$FILEsize != X564142080 ]
	then
		log4s error "�ļ���С����ȷ����˶Ժ��ٽ��У���СӦΪ554557440�ֽ�";
		exit 1;
	fi
	if [ $tXTBB -le 590 ] || [ $tXTBB -ge 710 ]
	then
		log4s error "ϵͳ�汾�ݲ�֧�֣�����ϵ�ű�������Ա"
		exit 1;
	fi
	if [ ! -f $alreadyornolog ]
	then
		touch $alreadyornolog
		log4s info "�������ݿ�����ʶ�ļ�$alreadyornolog"
		initflag=0
	else
		logs4 info "��װ��ʶ�ļ�����"
		initflag=`grep "alreadyinstall informix" $alreadyornolog|wc -l|awk '{print $1}'`
	fi
if [ $initflag = 0 ]
then
	#�û��Ƿ���ڣ���������ھͽ���
	log4s info "��װ��ʶ�ļ��в����ڰ�װ��ʶ"
	userexistflag=`grep informix /etc/passwd|wc -l|awk '{print $1}'`
	if [ X$userexistflag != X1 ]
	then
		#linux��װ����
		if [ X$XITONG = XLINUX ]
		then
			log4s info "�����û���"
			groupadd informix;
			log4s info "�����û�"
			useradd -g informix -d $informixhome informix;
			chown informix:informix $idshome
			chmod 770 $idshome
			passwd informix <<EOF
EBupt!@#456
EBupt!@#456
EOF
		fi
		#AIX��װ����
		if [ X$XITONG = XAIX ]
		then
			mkgroup informix;
			mkuser pgrp=informix home=$informixhome informix
			passwd informix <<EOF
EBupt!@#456
EBupt!@#456
EOF
	
		fi
	fi
	echo "LANG=$LANG:zh_CN.UTF8:zh_CN.GB18030" >> /home/informix/.bash_profile
	

	chown informix:informix $idshome
	chmod 775 $idshome
	INFORMIXDIR=$idshome
	export INFORMIXDIR
	chmod 777 /tmp/tempIFX12.sh
	if [ X$prionly = X1 ] && [ X$hdrflag = Xpri ]
	then
		log4s info "���ڽ��ű��Ͱ�װ�����Ƶ����������ֶ��������루��Ҫ��Σ�"
		mkdir /tmp/scptempdir/
		cp /tmp/tempIFX12.sh /tmp/scptempdir/$jiaobenming
		mv /tmp/$anzhuangbao /tmp/scptempdir/
		scp -oPort=$sshport -r /tmp/scptempdir/* root@$secip:/tmp/
		mv /tmp/scptempdir/$anzhuangbao /tmp/
		ssh -oPort=$sshport root@$secip "cd /tmp;nohup sh ./$jiaobenming anzhuang >/tmp/anzhuang.log 2>&1 &"
		log4s info "��Ҫ���������ݽ��������濪ʼȫ�Զ���װ�������������ݿ⣬�HDR�������ڰ�װ���������κβ���"
		sleep 3;
	fi

	
	
	log4s info "�ƶ���װ������װĿ¼"
	mv $anzhuangbao $idshome/
	cd $idshome;
	log4s info "��ѹ��װ��"
	tar -xvf  $idshome/$anzhuangbao -C $idshome/
	mv $idshome/$anzhuangbao /tmp
	log4s info "��ʼ�Զ��������ݿ�"
	$idshome/ids_install <<EOF

1
$idshome/
Y

1
2



EOF
	
	log4s info "�������"
	log4s info "�޸��ں˲���"
	kernel_shmmaxnum=`grep "kernel.shmmax = 4398046511104" /etc/sysctl.conf|wc -l`
	kernel_shmmninum=`grep "kernel.shmmni = 4096" /etc/sysctl.conf|wc -l`
	kernel_shmallnum=`grep "kernel.shmall = 67108864" /etc/sysctl.conf|wc -l`
	kernel_semnum=`grep "kernel.sem = 250 32000 32 4096" /etc/sysctl.conf|wc -l`
	if [ $kernel_shmmaxnum = 0 ]
	then
		echo "kernel.shmmax = 4398046511104" >> /etc/sysctl.conf
	fi
	if [ $kernel_shmmninum = 0 ]
	then
		echo "kernel.shmmni = 4096" >> /etc/sysctl.conf
	fi
	if [ $kernel_shmallnum = 0 ]
	then
		echo "kernel.shmall = 67108864" >> /etc/sysctl.conf
	fi
	if [ $kernel_semnum = 0 ]
	then
		echo "kernel.sem = 250 32000 32 4096" >> /etc/sysctl.conf
	fi


	log4s info "����ں˲���д���Ƿ���ȷ"

	kernel_shmmaxok=`grep "kernel.shmmax = 4398046511104" /etc/sysctl.conf|wc -l`
	kernel_shmmniok=`grep "kernel.shmmni = 4096" /etc/sysctl.conf|wc -l`
	kernel_shmallok=`grep "kernel.shmall = 67108864" /etc/sysctl.conf|wc -l`
	kernel_semok=`grep "kernel.sem = 250 32000 32 4096" /etc/sysctl.conf|wc -l`
	if [ X$kernel_shmmaxok != X1 ] || [ X$kernel_shmmniok != X1 ] || [ X$kernel_shmallok != X1 ] || [ X$kernel_semok != X1 ]
	then
	log4s info "�ں˲���д���쳣������"
	exit 0;
	fi
	log4s info "д���ں����ݸ��±�ʶ"
	echo "alreadyinstall informix" >> $alreadyornolog
	cp /tmp/$jiaobenming $idshome/

	if [ ! -d $idshome/dbfiles ]
	then
		log4s info "����dbfilesĿ¼"
		mkdir $idshome/dbfiles
		chown informix:informix $idshome/dbfiles
		chmod 775 $idshome/dbfiles
	fi
	
	chmod 777 $idshome/$jiaobenming
	chmod 777 $alreadyornolog


	log4s info "���������ļ���"
	makeln   $lvrootdbs1       $sizerootdbs1G           $idshome/dbfiles/rootdbs1   
	makeln   $lvtempdbs1       $sizetempdbs1G           $idshome/dbfiles/tempdbs1   
	makeln   $lvtempdbs2       $sizetempdbs2G           $idshome/dbfiles/tempdbs2   
	makeln   $lvlogdbs1        $sizelogdbs1G            $idshome/dbfiles/logdbs1    
	makeln   $lvphydbs1        $sizephydbs1G            $idshome/dbfiles/phydbs1    
	makeln   $lvuserdbs1       $sizeuserdbs1G           $idshome/dbfiles/userdbs1   
	makeln   $lvuserdbs2       $sizeuserdbs2G           $idshome/dbfiles/userdbs2   
	makeln   $lvuserdbs3       $sizeuserdbs3G           $idshome/dbfiles/userdbs3   
	makeln   $lvuserdbs4       $sizeuserdbs4G           $idshome/dbfiles/userdbs4   
	makeln   $lvuserdbs5       $sizeuserdbs5G           $idshome/dbfiles/userdbs5   
	makeln   $lvchargedbs1     $sizechargedbs1G         $idshome/dbfiles/chargedbs1 
	makeln   $lvchargedbs2     $sizechargedbs2G         $idshome/dbfiles/chargedbs2 
	makeln   $lvminfodbs1      $sizeminfodbs1G          $idshome/dbfiles/minfodbs1  
	makeln   $lvminfodbs2      $sizeminfodbs2G          $idshome/dbfiles/minfodbs2  
	makeln   $lvservdbs1       $sizeservdbs1G           $idshome/dbfiles/servdbs1   
	makeln   $lvservdbs2       $sizeservdbs2G           $idshome/dbfiles/servdbs2   
	chown informix:informix $idshome/dbfiles/*
	chmod 660 $idshome/dbfiles/*
	

	log4s info "����5.9����6.5���ض�����"
	log4s info "ϵͳ�汾Ϊ$XTBANBEN"
	if [ $tXTBB -ge 590 ] || [ $tXTBB -le 650 ]
	then
		gai59   $lvrootdbs1       $sizerootdbs1G
		gai59   $lvtempdbs1       $sizetempdbs1G
		gai59   $lvtempdbs2       $sizetempdbs2G
		gai59   $lvlogdbs1        $sizelogdbs1G
		gai59   $lvphydbs1        $sizephydbs1G
		gai59   $lvuserdbs1       $sizeuserdbs1G
		gai59   $lvuserdbs2       $sizeuserdbs2G
		gai59   $lvuserdbs3       $sizeuserdbs3G
		gai59   $lvuserdbs4       $sizeuserdbs4G
		gai59   $lvuserdbs5       $sizeuserdbs5G
		gai59   $lvchargedbs1     $sizechargedbs1G
		gai59   $lvchargedbs2     $sizechargedbs2G
		gai59   $lvminfodbs1      $sizeminfodbs1G
		gai59   $lvminfodbs2      $sizeminfodbs2G
		gai59   $lvservdbs1       $sizeservdbs1G
		gai59   $lvservdbs2       $sizeservdbs2G
	fi
	if [ $tXTBB -gt 650 ] || [ $tXTBB -le 720 ]
	then
		gai65  $vgname  rootdbs1       $sizerootdbs1G
		gai65  $vgname  tempdbs1       $sizetempdbs1G
		gai65  $vgname  tempdbs2       $sizetempdbs2G
		gai65  $vgname  logdbs1        $sizelogdbs1G
		gai65  $vgname  phydbs1        $sizephydbs1G
		gai65  $vgname  userdbs1       $sizeuserdbs1G
		gai65  $vgname  userdbs2       $sizeuserdbs2G
		gai65  $vgname  userdbs3       $sizeuserdbs3G
		gai65  $vgname  userdbs4       $sizeuserdbs4G
		gai65  $vgname  userdbs5       $sizeuserdbs5G
		gai65  $vgname  chargedbs1     $sizechargedbs1G
		gai65  $vgname  chargedbs2     $sizechargedbs2G
		gai65  $vgname  minfodbs1      $sizeminfodbs1G
		gai65  $vgname  minfodbs2      $sizeminfodbs2G
		gai65  $vgname  servdbs1       $sizeservdbs1G
		gai65  $vgname  servdbs2       $sizeservdbs2G
	fi
	
	log4s info "�޸�informix�Ļ������������ļ�"
	if [ X$XITONG = XLINUX ]
	then
		bashprofile=".bash_profile"
		echo "INFORMIXDIR=$idshome" >> /home/informix/$bashprofile
		echo "PATH=\$PATH:\$INFORMIXDIR/bin:\$INFORMIXDIR/lib/esql" >> /home/informix/$bashprofile
		echo "INFORMIXSERVER=$INFORMIXSERVER" >> /home/informix/$bashprofile
		echo "ONCONFIG=$ONCONFIG" >> /home/informix/$bashprofile
		echo "export INFORMIXDIR PATH INFORMIXSERVER ONCONFIG" >> /home/informix/$bashprofile
		echo "INFORMIXCONTIME=2" >> /home/informix/$bashprofile
		echo "INFORMIXCONRETRY=1" >> /home/informix/$bashprofile
		echo "export INFORMIXCONTIME INFORMIXCONRETRY " >> /home/informix/$bashprofile
	fi
	if [ X$XITONG = XAIX ]
	then
		bashprofile=".profile"
		echo "INFORMIXDIR=$idshome" >> /home/informix/$bashprofile
		echo "PATH=\$PATH:\$INFORMIXDIR/bin:\$INFORMIXDIR/lib/esql" >> /home/informix/$bashprofile
		echo "INFORMIXSERVER=$INFORMIXSERVER" >> /home/informix/$bashprofile
		echo "ONCONFIG=$ONCONFIG" >> /home/informix/$bashprofile
		echo "export INFORMIXDIR PATH INFORMIXSERVER ONCONFIG" >> /home/informix/$bashprofile
		echo "INFORMIXCONTIME=2" >> /home/informix/$bashprofile
		echo "INFORMIXCONRETRY=1" >> /home/informix/$bashprofile
		echo "export INFORMIXCONTIME INFORMIXCONRETRY " >> /home/informix/$bashprofile
	fi
	
	log4s info "д��.rhosts�ļ����������Ҫ���Լ��޸�.rhost�ļ���Ĭ��Ϊ+"
	echo '+' > /home/informix/.rhosts
	chown informix:informix /home/informix/.rhosts
	chmod 660 /home/informix/.rhosts
	
	log4s info "��ʼ�޸������ļ�"
	cp $idshome/etc/onconfig.std $peizhi
	chown informix:informix $peizhi
	chown informix:informix $log4spath
	chmod 777 $log4spath
	
	
	if [ X$hdrflag = Xpri ]
	then
		DBSERVERALIASES=$priDBSERVERALIASES
	fi
	if [ X$hdrflag = Xsec ]
	then
		DBSERVERALIASES=$secDBSERVERALIASES
	fi
	tihuan "^ROOTPATH \$INFORMIXDIR/tmp/demo_on.rootdbs" "ROOTPATH $idshome/dbfiles/rootdbs1";
	tihuan "^ROOTSIZE 300000" "ROOTSIZE 2000000";
	tihuan "^MSGPATH \$INFORMIXDIR/tmp/online.log" "MSGPATH /home/informix/online.log";
	tihuan "^DBSPACETEMP" "DBSPACETEMP tempdbs1,tempdbs2";
	tihuan "^ONDBSPACEDOWN 2" "ONDBSPACEDOWN 1";
	tihuan "^DBSERVERNAME" "DBSERVERNAME $INFORMIXSERVER";
	tihuan "^DBSERVERALIASES" "DBSERVERALIASES $DBSERVERALIASES";
	tihuan "^FULL_DISK_INIT.*" "FULL_DISK_INIT  1";
	tihuan "^NETTYPE ipcshm,1,50,CPU" "NETTYPE soctcp,4,150,NET";
	tihuan "^MULTIPROCESSOR 0" "MULTIPROCESSOR 1";
	tihuan "^VPCLASS cpu,num=1,noage" "VPCLASS cpu,num=${cpunum},noage";
	tihuan "^LOCKS 20000" "LOCKS 200000";
	tihuan "^SHMVIRTSIZE 32656" "SHMVIRTSIZE 200000";
	tihuan "^SHMADD 8192" "SHMADD 80000";
	tihuan "^CKPTINTVL 300" "CKPTINTVL 30";
	tihuan "^TAPEDEV /dev/tapedev" "TAPEDEV /dev/null";
	tihuan "^TAPEBLK 32" "TAPEBLK 128";
	tihuan "^LTAPEDEV /dev/tapedev" "LTAPEDEV /dev/null";
	tihuan "^BAR_ACT_LOG \$INFORMIXDIR/tmp/bar_act.log" "BAR_ACT_LOG /home/informix/bar_act.log";
	tihuan "^OPTCOMPIND 2" "OPTCOMPIND 0";
	tihuan "^DRAUTO                  0" "DRAUTO                  2";
	tihuan "^DUMPDIR \$INFORMIXDIR/tmp" "DUMPDIR /home/informix/tmp";
	tihuan "^DUMPSHMEM 1" "DUMPSHMEM 0";
	tihuan "^CLEANERS.*" "CLEANERS 16";
	if [ $testflag = 1 ]
	then
		tihuan "^BUFFERPOOL default.*" "BUFFERPOOL default,buffers=300000,lrus=64,lru_min_dirty=0,lru_max_dirty=0.05";
		tihuan "^BUFFERPOOL size.*" "";
	else
		tihuan "^BUFFERPOOL default.*" "BUFFERPOOL default,buffers=3000000,lrus=64,lru_min_dirty=0,lru_max_dirty=0.05";
		tihuan "^BUFFERPOOL size.*" "";
	fi

	chown informix:informix $peizhi
	if [ X$hdrflag = Xonly ]
	then
		echo "$priINFORMIXSERVER     onsoctcp      $priip       7778" >> $idshome/etc/sqlhosts
		echo "$priDBSERVERALIASES     onsoctcp     $priappip    7779" >> $idshome/etc/sqlhosts
	fi
	if [ X$hdrflag = Xpri ] || [ X$hdrflag = Xsec ]
	then
		echo "$priINFORMIXSERVER      onsoctcp     $priip       7778" >> $idshome/etc/sqlhosts
		echo "$secINFORMIXSERVER      onsoctcp     $secip       7778" >> $idshome/etc/sqlhosts
		echo "$priDBSERVERALIASES     onsoctcp     $priappip    7779" >> $idshome/etc/sqlhosts
		echo "$secDBSERVERALIASES     onsoctcp     $secappip    7779" >> $idshome/etc/sqlhosts
	fi
	chown informix:informix $idshome/etc/sqlhosts
	chown informix:informix $idshome/etc/*
	chomod a+r $idshome/etc/sqlhosts
	if [ -f /etc/hosts.equiv ]
	then
		log4s info "����/etc/hosts.equiv"
		eq1=`grep "$priINFORMIXSERVER$" /etc/hosts.equiv|wc -l|awk '{print $1}'`
		log4s debug "eq1ֵΪ$eq1"
		if [ X$eq1 != X1 ]
		then
			echo $priINFORMIXSERVER >> /etc/hosts.equiv
		fi
		if [ X$hdrflag != Xonly ]
		then
			eq2=`grep "$secINFORMIXSERVER" /etc/hosts.equiv|wc -l|awk '{print $1}'`
			log4s debug "eq2ֵΪ$eq2"
			if [ X$eq2 != X1 ]
			then
				echo $secINFORMIXSERVER >> /etc/hosts.equiv
			fi
		fi
		eq3=`grep "$priDBSERVERALIASES" /etc/hosts.equiv|wc -l|awk '{print $1}'`
		log4s debug "eq3ֵΪ$eq3"
		if [ X$eq3 != X1 ]
		then
			echo $priDBSERVERALIASES >> /etc/hosts.equiv
		fi
		if [ X$hdrflag != Xonly ]
		then
			eq4=`grep "$secDBSERVERALIASES" /etc/hosts.equiv|wc -l|awk '{print $1}'`
			log4s debug "eq4ֵΪ$eq4"
			if [ X$eq4 != X1 ]
			then
				echo $secDBSERVERALIASES >> /etc/hosts.equiv
			fi
		fi
		eq5=`grep "+" /etc/hosts.equiv|wc -l|awk '{print $1}'`
		log4s debug "eq5ֵΪ$eq5"
		if [ X$eq5 != X1 ]
		then
			echo "+" >> /etc/hosts.equiv
		fi
	else
		echo $priINFORMIXSERVER >> /etc/hosts.equiv
		echo $priDBSERVERALIASES >> /etc/hosts.equiv
		if [ X$hdrflag != Xonly ]
		then
			echo $secINFORMIXSERVER >> /etc/hosts.equiv
			echo $secDBSERVERALIASES >> /etc/hosts.equiv
		fi
		echo "+" >> /etc/hosts.equiv
	fi
	log4s info "����hosts�ļ�"
	hosts1=`grep -F "$priip $priINFORMIXSERVER" /etc/hosts|wc -l|awk '{print $1}'`
	hosts3=`grep -F "$priappip $priDBSERVERALIASES" /etc/hosts|wc -l|awk '{print $1}'`
	if [ X$hdrflag != Xonly ]
	then
		hosts2=`grep -F "$secip $secINFORMIXSERVER" /etc/hosts|wc -l|awk '{print $1}'`
		hosts4=`grep -F "$secappip $secDBSERVERALIASES" /etc/hosts|wc -l|awk '{print $1}'`
	fi
	if [ X$hosts1 != X1 ]
	then
		echo "$priip $priINFORMIXSERVER" >> /etc/hosts
	fi
	if [ X$hosts3 != X1 ]
	then
		echo "$priappip $priDBSERVERALIASES" >> /etc/hosts
	fi
	if [ X$hdrflag != Xonly ]
	then
		if [ X$hosts2 != X1 ]
		then
			echo "$secip $secINFORMIXSERVER" >> /etc/hosts
		fi
		if [ X$hosts4 != X1 ]
		then
			echo "$secappip $secDBSERVERALIASES" >> /etc/hosts
		fi
	fi
	log4s info "��Ч�ں˲���"
	sysctl -p;
	#�����Զ�������
	if [ X$hdrflag = Xsec ]
	then
		chmod 775 $idshome;
		log4s info "����������rsh����"
		tihuanbasic ".*disable.*" "        disable                 = no" /etc/xinetd.d/rsh
		echo "rsh" >> /etc/securetty
		/etc/rc.d/init.d/xinetd restart
		log4s info "������װ��ɣ��ȴ���������֪ͨ"
		beijijianting1
	fi
	#��������������
	if [ X$hdrflag = Xpri ] || [ X$hdrflag = Xonly ]
	then
		log4s info "������ʼ��ʼ��"
		chmod 775 $idshome;
		chmod 777 $log4slog
		echo "su - informix -c '. /home/informix/.bash_profile;sh /tmp/tempIFX12.sh chushihua'" >/tmp/temp.sh
		chmod 777 /tmp/temp.sh
		
		
		vgname=`echo $lvrootdbs1 |awk -F'/' '{print $3}'`



		chmod 777 /tmp/tempIFX12.sh
		chmod 777 /tmp/temp.sh
		sh /tmp/temp.sh
		
	fi
else
	log4s info "��װ��ʶ�ļ��д��ڰ�װ��ʶ��������װĿ¼$idshome�����������нű�"
fi


}
###################�hdr��###############
client()
{
	#��װ�ͻ���ģʽ
	hdrflag=client
	if [ X$hdrflag = Xclient ]
	then
		while [[ $clientpeizhiqueren != [Yy] ]]
		do
			isserver=server
			read -p "�������������ݿ�����ṩ�����ip��"				client_pri_serverip
			read -p "�������������ݿ�����ṩ����Ķ˿ڣ�"			client_pri_serverport
			read -p "�������������ݿ�����ṩ�����ʵ������"		client_pri_serverservername
			read -p "�����뱸�����ݿ�����ṩ�����ip��"				client_sec_serverip
			read -p "�����뱸�����ݿ�����ṩ����Ķ˿ڣ�"			client_sec_serverport
			read -p "�����뱸�����ݿ�����ṩ�����ʵ������"		client_sec_serverservername
			read -p "��������Ҫ��װ�Ŀͻ��˸�����һ�����5����"	clientcount

			if [ X$clientcount != X1 ] && [ X$clientcount != X2 ] && [ X$clientcount != X3 ] && [ X$clientcount != X4 ] && [ X$clientcount != X5 ]
			then
				echo "���벻Ϊ1-5��Ĭ����Ϊ��1���ͻ���"
				clientcount=1
			fi
			if [ $clientcount -ge 1 ]
			then
				read -p "������ͻ���1��ip��"							clientip1
				read -p "������ͻ���1����������"					clienthostname1
				read -p "������ͻ���1��ssh�Ķ˿ںţ�"		clientport1
				read -p "������ͻ���1���˻���"						clientusername1
			fi
			if [ $clientcount -ge 2 ]
			then
				read -p "������ͻ���2��ip��"							clientip2
				read -p "������ͻ���2����������"					clienthostname2
				read -p "������ͻ���2��ssh�Ķ˿ںţ�"		clientport2
				read -p "������ͻ���2���˻���"						clientusername2
			fi
			if [ $clientcount -ge 3 ]
			then
				read -p "������ͻ���3��ip��"							clientip3
				read -p "������ͻ���3����������"					clienthostname3
				read -p "������ͻ���3��ssh�Ķ˿ںţ�"		clientport3
				read -p "������ͻ���3���˻���"						clientusername3
			fi
			if [ $clientcount -ge 4 ]
			then
				read -p "������ͻ���4��ip��"							clientip4
				read -p "������ͻ���4����������"					clienthostname4
				read -p "������ͻ���4��ssh�Ķ˿ںţ�"		clientport4
				read -p "������ͻ���4���˻���"						clientusername4
			fi
			if [ $clientcount -ge 5 ]
			then
				read -p "������ͻ���5��ip��"							clientip5
				read -p "������ͻ���5����������"					clienthostname5
				read -p "������ͻ���5��ssh�Ķ˿ںţ�"		clientport5
				read -p "������ͻ���5���˻���"						clientusername5
			fi
			echo "�������ݿ�����ṩ�����ip��        $client_pri_serverip"
			echo "�������ݿ�����ṩ����Ķ˿ڣ�      $client_pri_serverport"
			echo "�������ݿ�����ṩ�����ʵ������    $client_pri_serverservername"
			echo "�������ݿ�����ṩ�����ip��        $client_sec_serverip"
			echo "�������ݿ�����ṩ����Ķ˿ڣ�      $client_sec_serverport"
			echo "�������ݿ�����ṩ�����ʵ������    $client_sec_serverservername"
			echo "��Ҫ��װ�Ŀͻ��˸�����              $clientcount"
			if [ $clientcount -ge 1 ]
			then
				echo "�ͻ���1��ipΪ��                     $clientip1"
				echo "�ͻ���1��������Ϊ��                 $clienthostname1"
				echo "�ͻ���1��ssh�˿ں�Ϊ��              $clientport1"
				echo "�ͻ���1���˻�Ϊ��                   $clientusername1"
			fi
			if [ $clientcount -ge 2 ]
			then
				echo "�ͻ���2��ipΪ��                     $clientip2"
				echo "�ͻ���2��������Ϊ��                 $clienthostname2"
				echo "�ͻ���2��ssh�˿ں�Ϊ��              $clientport2"
				echo "�ͻ���2���˻�Ϊ��                   $clientusername2"
			fi
			if [ $clientcount -ge 3 ]
			then
				echo "�ͻ���3��ipΪ��                     $clientip3"
				echo "�ͻ���3��������Ϊ��                 $clienthostname3"
				echo "�ͻ���3��ssh�˿ں�Ϊ��              $clientport3"
				echo "�ͻ���3���˻�Ϊ��                   $clientusername3"
			fi
			if [ $clientcount -ge 4 ]
			then
				echo "�ͻ���4��ipΪ��                     $clientip4"
				echo "�ͻ���3��������Ϊ��                 $clienthostname3"
				echo "�ͻ���4��ssh�˿ں�Ϊ��              $clientport4"
				echo "�ͻ���4���˻�Ϊ��                   $clientusername4"
			fi
			if [ $clientcount -ge 5 ]
			then
				echo "�ͻ���5��ipΪ��                     $clientip5"
				echo "�ͻ���5��������Ϊ��                 $clienthostname5"
				echo "�ͻ���5��ssh�˿ں�Ϊ��              $clientport5"
				echo "�ͻ���5���˻�Ϊ��                   $clientusername5"
			fi
			read -p "�Ƿ�ȷ�Ͽͻ�������[YyNn]��" clientpeizhiqueren
		done
		if [ $clientpeizhiqueren = y ] || [ $clientpeizhiqueren = Y ]
		then
			if [ X$isserver=Xserver ]
			then
				if [ $clientcount -ge 1 ]
				then
					log4s info "��ʼ׼���ͻ���1�İ�װ�ű�"
					echo "$clientip1     $clienthostname1" >> /etc/hosts
					echo "$clienthostname1" >> /etc/hosts.equiv
					rm -rf /tmp/tempIFX12.sh
					cp /tmp/$jiaobenming /tmp/tempIFX12.sh
					chmod 777 /tmp/tempIFX12.sh
					xiugai "^isserver=XXXXXX"											"isserver=client"
					xiugai "^client_pri_serverip=XXXXXX"					"client_pri_serverip=$client_pri_serverip"
					xiugai "^client_pri_serverport=XXXXXX"				"client_pri_serverport=$client_pri_serverport"
					xiugai "^client_pri_serverservername=XXXXXX"	"client_pri_serverservername=$client_pri_serverservername"
					xiugai "^client_sec_serverip=XXXXXX"					"client_sec_serverip=$client_sec_serverip"
					xiugai "^client_sec_serverport=XXXXXX"				"client_sec_serverport=$client_sec_serverport"
					xiugai "^client_sec_serverservername=XXXXXX"	"client_sec_serverservername=$client_sec_serverservername"
					xiugai "^clientcount=XXXXXX"									"clientcount=$clientcount"
					xiugai "^clientpeizhiqueren=XXXXXX"						"clientpeizhiqueren=y"
					mkdir /tmp/scptempdir/
					mv /tmp/$anzhuangbao /tmp/scptempdir/
					xiugai "^clientip=XXXXXX"											"clientip=$clientip1"
					xiugai "^clientport=XXXXXX"										"clientport=$clientport1"
					xiugai "^clientusername=XXXXXX"								"clientusername=$clientusername1"
					cp /tmp/tempIFX12.sh /tmp/scptempdir/$jiaobenming
					log4s info "׼�����"
					log4s info "��ʼ������װ�ű���$clientip1"
					scp -oPort=$clientport1 -r /tmp/scptempdir/* root@$clientip1:/tmp/
					log4s info "��ʼԶ��ִ�а�װ�ű�"
					ssh -oPort=$clientport1 root@$clientip1 "cd /tmp;nohup sh ./$jiaobenming client >/tmp/anzhuang.log 2>&1 &"
					#su - informix -c ". ./.bash_profile;echo 'grant dba to $clientusername1'|dbaccess sysmater"
					log4s info "��Ҫ����ĸ��������Ȩ����dbaccess��Ӧ����ִ��grant dba to �˻���"
					log4s info "���ͻ���������/tmp/anzhuang.log����ʾ��װ��ɼ���ʹ��"
				fi
				if [ $clientcount -ge 2 ]
				then
					log4s info "��ʼ׼���ͻ���2�İ�װ�ű�"
					echo "$clientip2     $clienthostname2" >> /etc/hosts
					echo "$clienthostname2" >> /etc/hosts.equiv
					rm -rf /tmp/tempIFX12.sh
					cp /tmp/$jiaobenming /tmp/tempIFX12.sh
					chmod 777 /tmp/tempIFX12.sh
					xiugai "^clientip=XXXXXX"											"clientip=$clientip2"
					xiugai "^clientport=XXXXXX"										"clientport=$clientport2"
					xiugai "^clientusername=XXXXXX"								"clientusername=$clientusername2"
					cp /tmp/tempIFX12.sh /tmp/scptempdir/$jiaobenming
					log4s info "׼�����"
					log4s info "��ʼ������װ�ű���$clientip2"
					scp -oPort=$clientport2 -r /tmp/scptempdir/* root@$clientip2:/tmp/
					log4s info "��ʼԶ��ִ�а�װ�ű�"
					ssh -oPort=$clientport2 root@$clientip2 "cd /tmp;nohup sh ./$jiaobenming client >/tmp/anzhuang.log 2>&1 &"
					su - informix -c ". ./.bash_profile;echo 'grant dba to $clientusername2'|dbaccess sysmater"
					log4s info "��Ҫ����ĸ��������Ȩ����dbaccess��Ӧ����ִ��grant dba to �˻���"
					log4s info "���ͻ���������/tmp/anzhuang.log����ʾ��װ��ɼ���ʹ��"
				fi
				if [ $clientcount -ge 3 ]
				then
					log4s info "��ʼ׼���ͻ���3�İ�װ�ű�"
					echo "$clientip3     $clienthostname3" >> /etc/hosts
					echo "$clienthostname3" >> /etc/hosts.equiv
					rm -rf /tmp/tempIFX12.sh
					cp /tmp/$jiaobenming /tmp/tempIFX12.sh
					chmod 777 /tmp/tempIFX12.sh
					xiugai "^clientip=XXXXXX"										"clientip=$clientip3"
					xiugai "^clientport=XXXXXX"									"clientport=$clientport3"
					xiugai "^clientusername=XXXXXX"							"clientusername=$clientusername3"
					cp /tmp/tempIFX12.sh /tmp/scptempdir/$jiaobenming
					log4s info "׼�����"
					log4s info "��ʼ������װ�ű���$clientip3"
					scp -oPort=$clientport3 -r /tmp/scptempdir/* root@$clientip3:/tmp/
					log4s info "��ʼԶ��ִ�а�װ�ű�"
					ssh -oPort=$clientport3 root@$clientip3 "cd /tmp;nohup sh ./$jiaobenming client >/tmp/anzhuang.log 2>&1 &"
					su - informix -c ". ./.bash_profile;echo 'grant dba to $clientusername3'|dbaccess sysmater"
					log4s info "��Ҫ����ĸ��������Ȩ����dbaccess��Ӧ����ִ��grant dba to �˻���"
					log4s info "���ͻ���������/tmp/anzhuang.log����ʾ��װ��ɼ���ʹ��"
				fi
				if [ $clientcount -ge 4 ]
				then
					log4s info "��ʼ׼���ͻ���4�İ�װ�ű�"
					echo "$clientip4     $clienthostname4" >> /etc/hosts
					echo "$clienthostname4" >> /etc/hosts.equiv
					rm -rf /tmp/tempIFX12.sh
					cp /tmp/$jiaobenming /tmp/tempIFX12.sh
					chmod 777 /tmp/tempIFX12.sh
					xiugai "^clientip=XXXXXX"										"clientip=$clientip4"
					xiugai "^clientport=XXXXXX"									"clientport=$clientport4"
					xiugai "^clientusername=XXXXXX"							"clientusername=$clientusername4"
					cp /tmp/tempIFX12.sh /tmp/scptempdir/$jiaobenming
					log4s info "׼�����"
					log4s info "��ʼ������װ�ű���$clientip4"
					scp -oPort=$clientport4 -r /tmp/scptempdir/* root@$clientip4:/tmp/
					log4s info "��ʼԶ��ִ�а�װ�ű�"
					ssh -oPort=$clientport4 root@$clientip4 "cd /tmp;nohup sh ./$jiaobenming client >/tmp/anzhuang.log 2>&1 &"
					su - informix -c ". ./.bash_profile;echo 'grant dba to $clientusername4'|dbaccess sysmater"
					log4s info "��Ҫ����ĸ��������Ȩ����dbaccess��Ӧ����ִ��grant dba to �˻���"
					log4s info "���ͻ���������/tmp/anzhuang.log����ʾ��װ��ɼ���ʹ��"
				fi
				if [ $clientcount -ge 5 ]
				then
					log4s info "��ʼ׼���ͻ���1�İ�װ�ű�"
					echo "$clientip5     $clienthostname5" >> /etc/hosts
					echo "$clienthostname5" >> /etc/hosts.equiv
					rm -rf /tmp/tempIFX12.sh
					cp /tmp/$jiaobenming /tmp/tempIFX12.sh
					chmod 777 /tmp/tempIFX12.sh
					xiugai "^clientip=XXXXXX"										"clientip=$clientip5"
					xiugai "^clientport=XXXXXX"									"clientport=$clientport5"
					xiugai "^clientusername=XXXXXX"							"clientusername=$clientusername5"
					cp /tmp/tempIFX12.sh /tmp/scptempdir/$jiaobenming
					log4s info "׼�����"
					log4s info "��ʼ������װ�ű���$clientip1"
					scp -oPort=$clientport5 -r /tmp/scptempdir/* root@$clientip5:/tmp/
					log4s info "��ʼԶ��ִ�а�װ�ű�"
					ssh -oPort=$clientport5 root@$clientip5 "cd /tmp;nohup sh ./$jiaobenming client >/tmp/anzhuang.log 2>&1 &"
					su - informix -c ". ./.bash_profile;echo 'grant dba to $clientusername5'|dbaccess sysmater"
					log4s info "��Ҫ����ĸ��������Ȩ����dbaccess��Ӧ����ִ��grant dba to �˻���"
					log4s info "���ͻ���������/tmp/anzhuang.log����ʾ��װ��ɼ���ʹ��"
				fi
				mv /tmp/scptempdir/$anzhuangbao /tmp/
			fi
			#X$isserver=Xserver��if����
			if [ X$isserver=Xclient ]
			then
				CheckP;
				if [ ! -d $idshome ]
				then
					log4s info "������װĿ¼"
					mkdir $idshome
				fi
				peizhi=$idshome/etc/$ONCONFIG
				wai=`whoami`
				if [ X$wai != Xroot ]
				then
				log4s error "��ʹ��root�˻����а�װ"
				exit 1;
				fi
				if [ X$X86 != Xx86_64 ]
				then
					log4s error "ϵͳΪ32λ�汾����ʱ��֧��"
					exit 1;
				fi
				if [ ! -f /tmp/$jiaobenming ]
				then
					log4s error "�뽫���ű�����/tmp�ļ�����"
					exit 1;
				fi
				if [ ! -f /tmp/$anzhuangbao ]
				then
					log4s error "�뽫$anzhuangbao�ŵ�/tmp��";
					exit 1;
				fi
				FILEsize=`stat -c %s /tmp/$anzhuangbao`
				if [ X$FILEsize != X564142080 ]
				then
					log4s error "�ļ���С����ȷ����˶Ժ��ٽ��У���СӦΪ554557440�ֽ�";
					exit 1;
				fi
				if [ $tXTBB -lt 590 ] || [ $tXTBB -ge 710 ]
				then
					log4s error "ϵͳ�汾�ݲ�֧�֣�����ϵ�ű�������Ա"
					exit 1;
				fi
				if [ ! -f $alreadyornolog ]
				then
					touch $alreadyornolog
					log4s info "�������ݿ�����ʶ�ļ�$alreadyornolog"
					initflag=0
				else
					log4s info "��װ��ʶ�ļ�����"
					initflag=`grep "alreadyinstall informix" $alreadyornolog|wc -l|awk '{print $1}'`
				fi
				if [ $initflag = 0 ]
				then
					#�û��Ƿ���ڣ���������ھͽ���
					log4s info "��װ��ʶ�ļ��в����ڰ�װ��ʶ"
					userexistflag=`grep informix /etc/passwd|wc -l|awk '{print $1}'`
					if [ X$userexistflag != X1 ]
					then
						#linux��װ����
						if [ X$XITONG = XLINUX ]
						then
							log4s info "�����û���"
							groupadd informix;
							log4s info "�����û�"
							useradd -g informix -d $informixhome informix;
							chown informix:informix $idshome
							chmod 770 $idshome
							passwd informix <<EOF
EBupt!@#456
EBupt!@#456
EOF
							fi
							#AIX��װ����
							if [ X$XITONG = XAIX ]
							then
								mkgroup informix;
								mkuser pgrp=informix home=$informixhome informix
								passwd informix <<EOF
EBupt!@#456
EBupt!@#456
EOF
							fi
						fi
						#[ X$userexistflag != X1 ]��if����
						chown informix:informix $idshome
						chmod 775 $idshome
						INFORMIXDIR=$idshome
						export INFORMIXDIR
						log4s info "�ƶ���װ������װĿ¼"
						mv $anzhuangbao $idshome/
						cd $idshome;
						log4s info "��ѹ��װ��"
						tar -xvf  $idshome/$anzhuangbao -C $idshome/
						mv $idshome/$anzhuangbao /tmp
						log4s info "��ʼ�Զ��������ݿ�"
						$idshome/ids_install <<EOF

1
$idshome/
Y

1
2



EOF
						if [ X$XITONG = XLINUX ]
						then
							bashprofile=".bash_profile"
						fi
						if [ X$XITONG = XAIX ]
						then
							bashprofile=".profile"
						fi
						#д��informix�˻���������
						echo "LANG=$LANG:zh_CN.UTF8:zh_CN.GB18030" >> /home/informix/$bashprofile
						echo "INFORMIXDIR=$idshome" >> /home/informix/$bashprofile
						echo "PATH=\$PATH:\$INFORMIXDIR/bin:\$INFORMIXDIR/lib/esql" >> /home/informix/$bashprofile
						echo "INFORMIXSERVER=$INFORMIXSERVER" >> /home/informix/$bashprofile
						echo "ONCONFIG=$ONCONFIG" >> /home/informix/$bashprofile
						echo "export INFORMIXDIR PATH INFORMIXSERVER ONCONFIG" >> /home/informix/$bashprofile
						echo "INFORMIXCONTIME=2" >> /home/informix/$bashprofile
						echo "INFORMIXCONRETRY=1" >> /home/informix/$bashprofile
						echo "export INFORMIXCONTIME INFORMIXCONRETRY " >> /home/informix/$bashprofile
				
						echo "LANG=$LANG:zh_CN.UTF8:zh_CN.GB18030" >> /home/$clientusername/$bashprofile
						echo "INFORMIXDIR=$idshome" >> /home/$clientusername/$bashprofile
						echo "PATH=\$PATH:\$INFORMIXDIR/bin:\$INFORMIXDIR/lib/esql" >> /home/$clientusername/$bashprofile
						echo "INFORMIXSERVER=$INFORMIXSERVER" >> /home/$clientusername/$bashprofile
						echo "ONCONFIG=$ONCONFIG" >> /home/$clientusername/$bashprofile
						echo "export INFORMIXDIR PATH INFORMIXSERVER ONCONFIG" >> /home/$clientusername/$bashprofile
						echo "INFORMIXCONTIME=2" >> /home/$clientusername/$bashprofile
						echo "INFORMIXCONRETRY=1" >> /home/$clientusername/$bashprofile
						echo "export INFORMIXCONTIME INFORMIXCONRETRY " >> /home/$clientusername/$bashprofile
						
						log4s info "д��.rhosts�ļ����������Ҫ���Լ��޸�.rhost�ļ���Ĭ��Ϊ+"
						echo '+' > /home/informix/.rhosts
						chown informix:informix /home/informix/.rhosts
						chmod 660 /home/informix/.rhosts
						
						log4s info "д��sqlhosts�ļ�"
						echo "$client_pri_serverservername     onsoctcp     $client_pri_serverip     $client_pri_serverport" >> $idshome/etc/sqlhosts
						echo "$client_sec_serverservername     onsoctcp     $client_sec_serverip     $client_sec_serverport" >> $idshome/etc/sqlhosts
						chown informix:informix $idshome/etc/sqlhosts
						chown informix:informix $idshome/etc/*
						chmod a+r $idshome/etc/sqlhosts
				fi
				#$initflag = 0��if����
			fi
			#X$isserver=Xclient��if����
		fi
		#[ $clientpeizhiqueren = y ] || [ $clientpeizhiqueren = Y ]��if����
	fi
	#X$hdrflag = Xclient��if����
}

hdr()
{
	wai1=`whoami`
	hdfflag=pri
	if [ $wai1 != informix ]
	then
		echo "����informix�˻�����"
		exit 0;
	fi
	onmode -ky;
	oninit;
	log4s info "��ʼ�㱸���ָ�����"
	ontape -t STDIO -s -L 0 -F|rsh $secip "cd /home/informix;. ./.bash_profile ; ontape -t STDIO -p";
	sleep 5;
	log4s info "��ʼ����������״̬"
	onmode -d primary $secINFORMIXSERVER;
	rsh $secip "cd /home/informix;. ./.bash_profile ; onmode -d secondary $priINFORMIXSERVER";
	sleep 1;
	log4s info "HDR����"
	while true
	do
	zhubeihdrokle=`echo "beijikaishihuifu"|nc $secip $tongxinduankou2`
		if [ X$zhubeihdrokle = Xbeijidengdaihuifu ]
		then
			log4s info "�����ָ�rsh������"
			break;
		fi
	sleep 1;
	done;

}
#########################��ʼ����##############
#ʹ�õ�ǰ�����Ѿ��޸ĺ�sqlhosts�ļ���/etc/hosts.*�ļ�
chushihua()
{
	wai1=`whoami`
	if [ $wai1 != informix ]
	then
		echo "����informix�˻�����"
		exit 0;
	fi
	chmod 775 $idshome;
	chmod 775 $idshome/dbfiles;
	
	oninit -ivy;
	bulidsysmasterok=`grep "'sysmaster' database built successfully." /home/informix/online.log|wc -l|awk '{print $1}'`
	bulidsysadminok=`grep "'sysadmin' database built successfully." /home/informix/online.log|wc -l|awk '{print $1}'`
	bulidsysuserok=`grep "'sysuser' database built successfully." /home/informix/online.log|wc -l|awk '{print $1}'`
	bulidsysutilsok=`grep "'sysutils' database built successfully." /home/informix/online.log|wc -l|awk '{print $1}'`
	let buildoknum=bulidsysmasterok+bulidsysadminok+bulidsysuserok+bulidsysutilsok
	while [ $buildoknum -lt 4 ]
	do
		log4s info "�ȴ�ϵͳ�ⴴ�����"
		sleep 10;
		bulidsysmasterok=`grep "'sysmaster' database built successfully." /home/informix/online.log|wc -l|awk '{print $1}'`
		bulidsysadminok=`grep "'sysadmin' database built successfully." /home/informix/online.log|wc -l|awk '{print $1}'`
		bulidsysuserok=`grep "'sysuser' database built successfully." /home/informix/online.log|wc -l|awk '{print $1}'`
		bulidsysutilsok=`grep "'sysutils' database built successfully." /home/informix/online.log|wc -l|awk '{print $1}'`
		let buildoknum=bulidsysmasterok+bulidsysadminok+bulidsysuserok+bulidsysutilsok
	done
	log4s info "���ݿ��ʼ����ɣ���ʼ����dbs";
	makeonspace   tempdbs1      $idshome/dbfiles/tempdbs1       $sizetempdbs1G     c
	makeonspace   tempdbs2      $idshome/dbfiles/tempdbs2       $sizetempdbs2G     c
	makeonspace   logdbs        $idshome/dbfiles/logdbs1        $sizelogdbs1G      c
	makeonspace   phydbs        $idshome/dbfiles/phydbs1        $sizephydbs1G      c
	makeonspace   userdbs       $idshome/dbfiles/userdbs1       $sizeuserdbs1G     c
	makeonspace   userdbs       $idshome/dbfiles/userdbs2       $sizeuserdbs2G     a
	makeonspace   userdbs       $idshome/dbfiles/userdbs3       $sizeuserdbs3G     a
	makeonspace   userdbs       $idshome/dbfiles/userdbs4       $sizeuserdbs4G     a
	makeonspace   userdbs       $idshome/dbfiles/userdbs5       $sizeuserdbs5G     a
	makeonspace   chargedbs     $idshome/dbfiles/chargedbs1     $sizechargedbs1G   c
	makeonspace   chargedbs     $idshome/dbfiles/chargedbs2     $sizechargedbs2G   a
	makeonspace   minfodbs      $idshome/dbfiles/minfodbs1      $sizeminfodbs1G    c
	makeonspace   minfodbs      $idshome/dbfiles/minfodbs2      $sizeminfodbs2G    a
	makeonspace   servdbs       $idshome/dbfiles/servdbs1       $sizeservdbs1G     c
	makeonspace   servdbs       $idshome/dbfiles/servdbs2       $sizeservdbs2G     a
	ontape -s -L 0;
	sleep 10;
	onmode -sy;
	for i in {1..36}
	do
		onparams -a -d logdbs -s 200000;
		let i+=1

	done
	ontape -s -L 0;
	onparams -d -l 2 <<EOF
y
EOF

	onparams -d -l 3 <<EOF
y
EOF
	onparams -d -l 4 <<EOF
y
EOF
	onparams -d -l 5 <<EOF
y
EOF
	onparams -d -l 6 <<EOF
y
EOF
	onmode -l;
	onmode -c;
	onparams -d -l 1 <<EOF
y
EOF

	ontape -s -L 0;

	for i in {1..6}
	do
		onparams -a -d logdbs -s 200000;
		let i+=1

	done
	let physize=sizephydbs1*95/100
	onparams -p -s $physize -d phydbs -y;
	ontape -s -L 0;
	onparams -d -l 2 <<EOF
y
EOF

	onparams -d -l 3 <<EOF
y
EOF
	onparams -d -l 4 <<EOF
y
EOF
	onparams -d -l 5 <<EOF
y
EOF
	onparams -d -l 6 <<EOF
y
EOF
	for i in {1..6}
	do
		onparams -a -d logdbs -s 200000;
		let i+=1

	done
	ontape -s -L 0;
	log4s info "������װ��ɣ��ȴ�������װ����źš�"
	if [ X$hdrflag != Xonly ]
	then
		while true
		do
			beijiqidongflag=`echo "kaishihdr"|nc $secip $tongxinduankou1`
				if [ X$beijiqidongflag = Xsecbootok ]
				then
					log4s info "������װ��ɡ���ʼ�HDR"
					break;
				fi
			sleep 1;
		done;
		hdr
	fi
	if [ X$hdrflag = Xonly ]
	then
		onmode -m;
		log4s info "������װ���"
		killall nc;
		killall nc;
		exit 0;
	fi 
}


qingli()
{
	wai2=`whoami`
	if [ X$wai2 = Xroot ]
	then
		su - informix -c '. /home/informix/.bash_profile;onmode -ky'
		rm -rf /home/informix
		rm -rf /ids
		rm -rf /etc/hosts.equiv
		rm -rf /etc/udev/rules.d/93-application-devices.rules
		tihuanbasic "$priip $priname" ""  /etc/hosts
		tihuanbasic "$secip $secname" ""  /etc/hosts
		tihuanbasic "$priappip $priappname" "" /etc/hosts
		tihuanbasic "$secappip $secappname" "" /etc/hosts
		tihuanbasic "chown informix:informix $lvrootdbs1" "" /etc/rc.d/rc.local
		tihuanbasic "chown informix:informix $lvtempdbs1" "" /etc/rc.d/rc.local
		tihuanbasic "chown informix:informix $lvtempdbs2" "" /etc/rc.d/rc.local
		tihuanbasic "chown informix:informix $lvlogdbs1" "" /etc/rc.d/rc.local
		tihuanbasic "chown informix:informix $lvphydbs1" "" /etc/rc.d/rc.local
		tihuanbasic "chown informix:informix $lvuserdbs1" "" /etc/rc.d/rc.local
		tihuanbasic "chmod 660 $lvrootdbs1" "" /etc/rc.d/rc.local
		tihuanbasic "chmod 660 $lvtempdbs1" "" /etc/rc.d/rc.local
		tihuanbasic "chmod 660 $lvtempdbs2" "" /etc/rc.d/rc.local
		tihuanbasic "chmod 660 $lvlogdbs1" "" /etc/rc.d/rc.local
		tihuanbasic "chmod 660 $lvphydbs1" "" /etc/rc.d/rc.local
		tihuanbasic "chmod 660 $lvuserdbs1" "" /etc/rc.d/rc.local
		tihuanbasic "kernel.shmmax = 4398046511104" "" /etc/sysctl.conf
		tihuanbasic "kernel.shmmni = 4096" "" /etc/sysctl.conf
		tihuanbasic "kernel.shmall = 67108864" "" /etc/sysctl.conf
		tihuanbasic "kernel.sem = 250 32000 32 4096" "" /etc/sysctl.conf


		tihuanbasic "rsh" "" /etc/securetty
		tihuanbasic ".*disable.*" "        disable                 = yes" /etc/xinetd.d/rsh
		ps -u informix|sed 1d|awk '{print $1}'|xargs kill -9
		userdel informix
		rm -rf /var/spool/mail/informix
		rm -rf /tmp/scptempdir
		rm -rf /tmp/temp.sh
		killall nc
		sleep 1
		killall nc
		
		vgname=`grep "^vgname=" tempIFX12.sh |awk -F'=' '{print $2}'`
		devname=`grep "^devname=" tempIFX12.sh |awk -F'=' '{print $2}'`
		if [ X$vgname != X ]
		then
			vgremove $vgname <<-EOF
			y
			y
			y
			y
			y
			y
			y
			y
			y
			y
			y
			y
			y
			y
			y
			y
			y
EOF
		fi
		if [ X$devname != X ]
		then
			pvremove $devname
		fi
		rm -rf /tmp/tempIFX12.sh
	else
		echo "��Ҫ��root�˻�"
	fi
}

if [ $# = 1 ] && [ $1 = anzhuang ]
then
	anzhuang
fi
if [ $# = 1 ] && [ $1 = chushihua ]
then
	chushihua
fi
if [ $# = 1 ] && [ $1 = qingli ]
then
	qingli
fi
if [ $# = 1 ] && [ $1 = client ]
then
	client
fi
