#!/bin/sh

version=1.2
#1.0优化内容：支持fc8和fc10，自动检测，使用最高版本
#1.1优化内容：更多提示，输入监控前置。本地盘方式支持优化。单机安装优化。内核参数核查机制变更。
#1.2增加对fc12的支持

#架构重置版
#############################################
#将本脚本和安装包放到/tmp下
#暂时只支持linux
#############################################

#测试标志位，1则为测试配置项，0则为正式配置项
testflag=0
#模板，待扩展
muban=cl
#为0是使用配置文件，为1是使用输入方式
peizhiflag=1
#是否需要去备机自动执行，0否，1是
prionly=1
#是否安全加固，0否，1是
anquan=1


if [ $# = 0 ]
then
	echo "启动需要参数，anzhuang，进行安装，具体配置请详细阅读配置区"
	echo "SecureCRT need defult"
	echo "ru guo zhong wen luan ma ,qing geng gai SecureCRT bian ma wei defult"
	exit 0;
fi


#############配置区，如需更改请仔细阅读##############
isinformixid=0								#是否指定informix用户id和组id，暂不支持，觉得没用
informixgroupid=200
informixuserid=200
informixhome=/home/informix		#informix的home目录
idshome=/ids									#软件安装目录
INFORMIXDIR=$idshome
log=$idshome/rizhi.log
alreadyornolog=$idshome/instalready.log
banbenlist=("fc8" "fc10" "fc12")
declare -A anzhuangbaolist=(["fc8"]="Informix_Enterprise_12.10.FC8W1_LIN-x86_64_IFix.tar" ["fc10"]="Informix_Enterprise_12.10.FC10_LIN-x86_64_Fixpack.tar" ["fc12"]="Informix_Enterprise_12.10.FC12_LIN-x86_64_Fixpack.tar")
declare -A filesizelist=(["fc8"]="564142080" ["fc10"]="402227200" ["fc12"]="418252800")
jiaobenming=`echo $0|awk -F'/' '{print $NF}'`
tongxinduankou1=36925					#主备机通信的端口，系统默认的36925不被占用，如有特殊情况请手动更改。
tongxinduankou2=36926

#dbs区域，设置各dbs大小，根据chunk名填写，配置单位为G
#注意想要设置的dbs所在lv的大小一定要大于设置的dbs大小
#测试版的小数据
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


#############基础函数，不要动###############################
################log4s配置区#################
log4spath=$idshome								#输出日志目录
log4sechoCategory=info				#输出到屏幕日志级别名称，级别按照debug=0，warn=1，info=2，error=3
log4swriteCategory=debug			#输出到文件日志级别名称，级别按照debug=0，warn=1，info=2，error=3
log4slogname=root.log					#输出日志名称
isecho=1											#输出到日志的同时是否打印到屏幕，0是不打印，1是打印
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
	if [ X$log4sechoCategory = X ]
	then
		echo "log4sechoCategory参数需要配置"
		exit 1;
	fi
	if [ X$log4swriteCategory = X ]
	then
		echo "log4swriteCategory参数需要配置"
		exit 1;
	fi
	if [ X$log4slogname = X ]
	then
		echo "log4slogname参数需要配置"
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
	log4sechoCategoryToU=`echo $log4sechoCategory|tr '[a-z]' '[A-Z]'`
	log4swriteCategoryToU=`echo $log4swriteCategory|tr '[a-z]' '[A-Z]'`

	case $log4sechoCategoryToU in
		DEBUG)
			log4sechoCategorylevel=0
			;;
		WARN)
			log4sechoCategorylevel=1
			;;
		INFO)
			log4sechoCategorylevel=2
			;;
		ERROR)
			log4sechoCategorylevel=3
			;;
		*)
			log4sechoCategorylevel=3
			;;
	esac
	case $log4swriteCategoryToU in
		DEBUG)
			log4swriteCategorylevel=0
			;;
		WARN)
			log4swriteCategorylevel=1
			;;
		INFO)
			log4swriteCategorylevel=2
			;;
		ERROR)
			log4swriteCategorylevel=3
			;;
		*)
			log4swriteCategorylevel=3
			;;
	esac
}
################log4s代码区#################
log4slog=${log4spath}/${log4slogname}
log4scheck;
log4s()                       #$1是级别，$2是内容
{
	nowdate=`date +"%Y-%m-%d %H:%M:%S"`
	######判断区域，保证参数严谨性
	#判断目录及日志文件，不自动创建目录，但是会自动创建文件
	if [ ! -d $log4spath ]
	then
		echo "$nowdate log4s配置的目录不存在，自动建立目录"
		mkdir $log4spath;
		chmod 777 $log4spath;
		chown informix:informix $log4spath;
	fi
	if [ ! -f $log4slog ]
	then
		#echo "log4s日志不存在，创建log4s日志文件"
		echo "$nowdate log4s日志不存在，创建log4s日志文件" >> $log4slog
		chmod 777 $log4slog
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
	if [ $log4snowlevel -ge $log4sechoCategorylevel ] && [ $isecho = 1 ]
	then
		echo "$2"
	fi
	if [ $log4snowlevel -ge $log4swriteCategorylevel ]
	then
		echo "$nowdate log4s.${log4sinlevel}   $2" >> $log4slog
	fi
}
querenanzhuangbao()
{
	#安装包分辨
	for banbenlisti in ${banbenlist[*]}; do
		if [ -f ${anzhuangbaolist[$banbenlisti]} ]
		then
			log4s debug "安装包设置为${anzhuangbaolist[$banbenlisti]}"
			anzhuangbao=${anzhuangbaolist[$banbenlisti]}
			filesize=${filesizelist[$banbenlisti]}
			log4s debug "安装包大小应该为$filesize"
		fi
	done
	if [ X$anzhuangbao = X ] || [ X$filesize = X ]
	then
		log4s error "安装包不存在"
		exit 1;
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
	#两个参数，$1位lv目录比如$lvrootdbs1，$2位lv的大小
	if [ $2 != 0 ]
	then
		log4s debug "ENV{DM_NAME}==\"$1\", OWNER:=\"informix\", GROUP:=\"informix\", MODE:=\"660\""
		echo "ENV{DM_NAME}==\"$1\", OWNER:=\"informix\", GROUP:=\"informix\", MODE:=\"660\"" >> /etc/udev/rules.d/93-application-devices.rules
	fi
}
gai65()
{
	#3个参数，$1位$vgname，$2是lv名称比如rootdbs1，,3是lv的大小
	if [ $3 != 0 ]
	then
		log4s debug "ENV{DM_VG_NAME}==\"$1\", ENV{DM_LV_NAME}==\"$2\", OWNER:=\"informix\", GROUP:=\"informix\""
		echo "ENV{DM_VG_NAME}==\"$1\", ENV{DM_LV_NAME}==\"$2\", OWNER:=\"informix\", GROUP:=\"informix\"" >> /etc/udev/rules.d/93-application-devices.rules
	fi
}
makeonspace()
{
	#onspaces -c -d logdbs -p $idshome/dbfiles/logdbs1 -o 0 -s $sizelogdbs1;
	#$1是logdbs，$2是$idshome/dbfiles/logdbs1，$3是$sizelogdbs1，$4是决定是-c -d 还是-a
	if [ $3 != 0 ]
	then
		let onspacetempsize=$3*1000000
		if [ X$4 = Xc ]
		then
			log4s debug "开始创建dbspace  $1"
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
				log4s info "$1创建成功"
			else
				log4s error "$1创建失败"
			fi
		fi
		if [ X$4 = Xa ]
		then
			log4s debug "增加dbspace  $1"
			onspaces -a $1 -p $2 -o 0 -s $onspacetempsize;
			onresult=$?
			sleep 3;
			if [ $onresult = 0 ]
			then
				log4s info "$1增加成功"
			else
				log4s error "$1增加失败"
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
	#使用方法，先执行sizesum，第一个参数是$devname
	if [ $sizesumnum = 0 ]
	then
		echo "请先运行sizesum"
		exit 1;
	fi
	let tempsize=$sizesumnum*1024*1024*1024
	disksize=`fdisk -l|grep "$1" |awk -F',' '{print $2}'|awk '{print $1}'`
	log4s info "需要空间$tempsize,磁盘空间为$disksize"
	if [ $tempsize -lt $disksize ] && [ $tempsize != 0 ]
	then
		ifull=ok
		log4s info "磁盘空间满足需求"
	else
		isfull=full
		log4s error "磁盘空间不足"
		exit 1;
	fi
}
vgisfull()
{
	#使用方法，先执行sizesum，第一个参数是$devname
	if [ $sizesumnum = 0 ]
	then
		echo "请先运行sizesum"
		exit 1;
	fi
	let tempsize=$sizesumnum
	vgsize=`vgdisplay $vgname|grep 'VG Size'|awk '{print $3}'`
	log4s info "需要的vg空间为${tempsize}G，当前vg实际空间为${tempsize}G"
	if [ $tempsize -lt $vgsize ] && [ $tempsize != 0 ]
	then
		ifull=ok
		log4s info "vg空间满足需求"
	else
		isfull=full
		log4s error "vg空间不足"
		exit 1;
	fi
}
checklv()
{
	#检查划分的lv大小是否符合设置的值，或者是否划分成功
	#$1为lv目录，$2为设置的大小
	if [ X$1 = X ] || [ X$2 = X ]
	then
		log4s debug "checklv运行错误，第一个参数为：$1，第二个参数为：$2"
	fi
	if [ X$2 != X0 ]
	then
		lvexist=`lvdisplay $1|grep 'LV Size'|wc -l|awk '{print $1}'`
		if [ X$lvexist != X1 ]
		then
			log4s error "$1不存在"
			exit 1;
		fi
		huafensize=`lvdisplay $1|grep 'LV Size'|awk '{print $3}'|awk -F'.' '{print $1}'`
		yaoqiusize=$2
		if [ $huafensize -ge $yaoqiusize ]
		then
			log4s debug "${1}大小符合要求"
		else
			log4s error "输入的dbs大小为$2，但是lv大小为$1，不符合要求"
			exit 1;
		fi
	else
		log4s debug "${1}的大小为0，不需要创建该dbs，所以不检查"
	fi
}
makeln()
{
	#$1是源文件也就是lv，$2是要创建的大小，$3是连接文件也就是dbsfile下的
	if [ X$2 != X0 ]
	then
		ln -s $1 $3
		log4s info "创建$3"
		if [ -L $3 ]
		then
			log4s info "创建连接文件 $3 成功"
		else
			log4s error "创建连接文件 $3 失败"
		fi
	fi
}
tihuan()
{
	log4s debug "将$peizhi中的\"$1\" 修改为 \"$2\""
	tihuanbasic "$1" "$2" $peizhi
}
tihuanaao()
{
	log4s debug "将$idshome/aaodir/adtcfg中的\"$1\" 修改为 \"$2\""
	tihuanbasic "$1" "$2" $idshome/aaodir/adtcfg
}
xiugai()
{
	log4s debug "将/tmp/tempIFX12.sh中的\"$1\" 修改为 \"$2\""
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
	Pnumtmp1=`echo "$*"|sed s#[[:space:]]##g`
	Pnumtmp2=`echo $Pnumtmp1|sed s#[[:digit:]]##g`
	Pnumold1=`echo "$*"|wc -L|awk '{print $1}'`
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
	#$1为lv目录，$2为lv大小，$3为lv名称
	if [ X$1 = X0 ] || [ X$2 = X0 ] || [ X$3 = X0 ]
	then
		log4s info "当前dbs不建立，所以不需要判断"
	else
		Plvsizegetsize=`lvdisplay $1|grep 'LV Size'|awk '{print $3}'|awk -F'.' '{print $1}'`
		if [ $Plvsizegetsize -lt $2 ]
		then
			log4s error "$3,设置的lv的大小为$Plvsizegetsize，小于要求的大小$2"
			exit 1;
		else
			log4s debug "$3,设置的lv的大小为$Plvsizegetsize，大于要求的大小$2，符合要求"
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
	#$1为要创建pv的目录
	pvisexist=`pvscan|grep "$1"|wc -l|awk '{print $1}'`
	if [ X$pvisexist = X0 ]
	then
		pvcreate $1 > $log4spath/makepv.temp
		getpvnum=`pvscan|grep $1|wc -l|awk '{print $1}'`
		getmakeresult=`grep -i successfully $log4spath/makepv.temp|wc -l|awk '{print $1}'`
		if [ X$getpvnum = X1 ] && [ X$getmakeresult = X1 ]
		then
			log4s info "pv创建成功"
		else
			log4s error "pv创建失败"
			exit 1;
		fi
	else
		log4s error "pv已经存在，请注意输入是否正常"
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
		log4s info "创建vg成功，vg名称为$vgname"
	else
		log4s error "创建vg失败"
		exit 1;
	fi
}

makelv()
{
	#使用方法，传入第一个参数是lv名，第二个参数大小（格式为1G），第三个参数vg名称
	if [ $2 != 0 ]
	then
		lvcreate -L ${2}G -n $1 $3 > $log4spath/makelv.temp
		getmakelvresult=`grep $1 $log4spath/makelv.temp|grep -i created|wc -l|awk '{print $1}'`
		if [ X$getmakelvresult = X1 ]
		then
			log4s info "$1创建成功"
		else
			log4s error "$1创建失败"
			exit 1;
		fi
	fi

}



#########################占位配置区，请勿修改#########
#该区域是为了使用informix账户启动脚本时能获得之前输入的配置信息
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
shifouquerenlvorfs=XXXXXX
lvorfs=XXXXXX
shifouquerendbssize=XXXXXX
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
ltapedev=XXXXXX
#############获取系统配置区，单独拿出来为了便于调试#########
X86=`uname -m`
XITONGTEMP=`uname`
XITONG=`echo $XITONGTEMP|tr '[a-z]' '[A-Z]'`  #系统类型
xtong=`echo $XITONG|tr '[A-Z]' '[a-z]'`
releaseBANBEN=`cat /etc/redhat-release |awk '{print $1}'|tr '[a-z]' '[A-Z]'`
if [ X$releaseBANBEN = XRED ]
then
	#是红帽系统
	XTBANBEN=`lsb_release -a|grep Release|awk '{print $2}'`  #获取系统版本
elif [ X$releaseBANBEN = XCENTOS ]
then
	#是centos
	XTBANBEN=`cat /etc/redhat-release |awk '{print $4}'|awk 'BEGIN{FS=".";OFS="."} {print $1,$2}'` #获取系统版本
fi
tXTBB=$(echo $XTBANBEN |awk -F'.' '{print $1*1000+$2}')
cpunumtemp=`cat /proc/cpuinfo|grep processor|wc -l`
let cpunum=cpunumtemp-1
#获取内存信息，要求单位是kb，但是这里得出数是直接按照page2k的个数，然后计算内存的50%是否大于32G，如果大于则buff配置32G，否则buff配置内存的50%
meminfopage=`cat /proc/meminfo |grep -i MemTotal|awk '{print $2/2}'`
let memthreshold=meminfopage/2
if [ 16000000 -le $memthreshold ]
then
	BUFFPOOLMEM=16000000
else
	BUFFPOOLMEM=$memthreshold
fi
kernel_shmmax="kernel.shmmax = 4398046511104"
kernel_shmmni="kernel.shmmni = 4096"
kernel_shmall="kernel.shmall = 67108864"
kernel_sem="kernel.sem = 250 32000 32 4096"
stty erase ^H;

let sizerootdbs1=$sizerootdbs1G*1000000
let sizetempdbs1=$sizetempdbs1G*1000000
let sizetempdbs2=$sizetempdbs2G*1000000
let sizelogdbs1=$sizelogdbs1G*1000000
let sizephydbs1=$sizephydbs1G*1000000
let sizeuserdbs1=$sizeuserdbs1G*1000000

#参数初始化并校验区域
CheckP()
{
	PWDDIR=`pwd`
	if [ X$PWDDIR != X/tmp ]
	then
		echo "请将脚本放在/tmp下，且在/tmp下执行"
		exit 1;
	fi
	if [ ! -f /tmp/$anzhuangbao ]
	then
		echo "请将安装包$anzhuangbao放在/tmp下"
		exit 1;
	fi
	cp /tmp/$jiaobenming /tmp/tempIFX12.sh
	chmod 777 /tmp/tempIFX12.sh
	
	X86=`uname -m`
	if [ X$X86 != Xx86_64 ]
	then
		log4s error "系统为32位版本，暂时不支持"
		exit 1;
	fi
	FILEsize=`stat -c %s /tmp/$anzhuangbao`
	if [ X$FILEsize != X$filesize ]
	then
		log4s error "文件大小不正确，请核对后再进行，大小应为$filesize字节";
		exit 0;
	fi
	if [ $tXTBB -le 5009 ] || [ $tXTBB -ge 7906 ]
	then
		echo "系统版本暂不支持，请联系脚本开发人员"
		exit 1;
	fi
	ncanzhuang=`rpm -q nc|wc -l|awk '{print $1}'`
	if [ X$ncanzhuang != X1 ] || [ ! -f /usr/bin/nc ]
	then
		echo "请安装nc后再执行脚本"
		exit 1;
	fi
	rshanzhuang1=`rpm -q rsh|wc -l|awk '{print $1}'`
	if [ X$rshanzhuang1 != X1 ] || [ ! -f /etc/xinetd.d/rsh ]
	then
		echo "请确认安装rsh后再执行脚本"
		exit 1;
	fi
	which nc 1>/dev/null 2>&1
	if [ $? != 0 ]
	then
		echo "当前主机没有nc，请务必确保安装"
	fi
}
InputAndCheck()
{
	echo "开始安装，当前版本为$version，每一块输入后都有二次确认，如有输入错误可以选择n，则该模块重新输入"
	while [[ X$hdrflag != Xhdr  && X$hdrflag != Xonly && X$hdrflag != Xsec && X$hdrflag != Xpri && X$hdrflag != Xclient ]]
	do
		read -p "请设置安装模式，1、单机模式请输入only；2、主备双机hdr模式，请输入hdr（只在主机执行该脚本即可）；3、安装客户端模式请输入client： " hdrflaginput
		while [[ X$hdrflaginput != Xhdr && X$hdrflaginput != Xonly && X$hdrflaginput != Xclient ]]
		do
			log4s info "输入不符合要求，请按照要求输入"
			read -p "请设置安装模式，1、单机模式请输入only；2、主备双机hdr模式，请输入hdr（只在主机执行该脚本即可）；3、安装客户端模式请输入client： " hdrflaginput
		done
		log4s debug "输入的hdrflaginput参数为：$hdrflaginput"
		if [ X$hdrflaginput = Xonly ]
		then
			log4s debug "设置hdrflag参数为only"
			hdrflag=only
		fi
		if [ X$hdrflaginput = Xhdr ]
		then
			log4s debug "设置hdrflag参数为pri"
			hdrflag=hdr
		fi 
		if [ X$hdrflaginput = Xclient ]
		then
			log4s debug "设置hdrflag参数为client"
			hdrflag=client
		fi 
	done
	if [ X$hdrflag = Xhdr ]
	then
		hdrflag=pri
	fi
	while [[ $peizhiqueren != [Yy] ]]
	do
		#单机模式
		if [ X$hdrflaginput = Xonly ]
		then
			log4s info "单机配置开始"
			echo "下面开始输入数据库主实例名，也就是在onconfig中配置的数据库实例名servername"
			read -p "请输入主实例名，比如hdr1，[默认为hdr1] ： " priINFORMIXSERVER
			log4s debug "输入的主实例名为$priINFORMIXSERVER"
			if [ X$priINFORMIXSERVER = X ]
			then
				priINFORMIXSERVER=hdr1
				log4s debug "主实例名为空，设置主实例名priINFORMIXSERVER为默认值hdr1"
				priONCONFIG=onconfig.$priINFORMIXSERVER
				log4s debug "设置配置名priONCONFIG为onconfig.$priINFORMIXSERVER"
			else
				priONCONFIG=onconfig.${priINFORMIXSERVER}
				log4s debug "输入的主实例名priINFORMIXSERVER不为空，值为$priINFORMIXSERVER"
				log4s debug "设置配置名priONCONFIG为onconfig.$priINFORMIXSERVER"
			fi
			read -p "请输入主机业务实例名，也就是onconfig中的alisename，比如appdb1，务必不能与主实例名相同，[默认为appdb1] ： " priDBSERVERALIASES
			log4s debug "输入的业务实例名priDBSERVERALIASES为$priDBSERVERALIASES"
			if [ X$priDBSERVERALIASES = X ]
			then
				priDBSERVERALIASES=appdb1
				log4s debug "输入的业务实例名为空，priDBSERVERALIASES设置为默认值appdb1"
			fi
			echo `ifconfig -a|grep "inet addr"|grep -v '127.0.0.1'|awk '{print $2}'|awk -F':' '{print $2}'`

			read -p "请输入主实例对外ip："			priip
			while [[ X$priip = X ]]
			do
				read -p "主实例对外ip，不能为空，请重新输入"  priip
			done
			read -p "请输入业务实例对外ip："	priappip
			while [[ X$priappip = X ]]
			do
				read -p "业务实例对外ip，不能为空，请重新输入"  priappip
			done
			echo "下面是刚才输入的配置"
			echo "主实例名：     $priINFORMIXSERVER"
			echo "业务实例名：   $priDBSERVERALIASES"
			echo "主实例ip：     $priip"
			echo "业务实例ip：   $priappip"
			log4s debug "输入的主实例ip为$priip"
			log4s debug "输入的业务实例ip为$priappip"
			read -p "配置是否正确，如果正确请输入[y/n]：" peizhiqueren
			log4s debug "输入的确认配置为$peizhiqueren"
		fi
		#单机模式结束
		
		#hdr模式
		if [ X$hdrflaginput = Xhdr ]
		then
			log4s info "hdr配置开始"
			read -p "请输入主备机ssh端口号，一般为19222或者22，[默认为19222]："  sshport
			if [ X$sshport = X ]
			then
				sshport=19222
			fi
			echo "下面开始输入数据库实例名，也就是在sqlhosts中配置的数据库实例名"
			
			#priINFORMIXSERVER参数
			if [ X$peizhiqueren = XXXXXXX ]
			then
				read -p "请输入主机心跳线实例名，[默认为hdr1] ： " tpriINFORMIXSERVER
			fi
			if [ X$peizhiqueren != XXXXXXX ]
			then
				read -p "请输入主机心跳线实例名，刚才输入的是$priINFORMIXSERVER ： " tpriINFORMIXSERVER
			fi
			log4s debug "输入的主机心跳线实例名为：$tpriINFORMIXSERVER"
			if [ X$tpriINFORMIXSERVER = X ]
			then
				priINFORMIXSERVER=hdr1
				log4s debug "priINFORMIXSERVER值为空，设置为默认：hdr1"
				priONCONFIG=onconfig.$priINFORMIXSERVER
				log4s debug "设置主机配置文件名为：onconfig.$priINFORMIXSERVER"
			else
				priINFORMIXSERVER=$tpriINFORMIXSERVER
				log4s debug "主机配置priINFORMIXSERVER为：$tpriINFORMIXSERVER"
				priONCONFIG=onconfig.${priINFORMIXSERVER}
				log4s debug "主机配置文件名为：$priONCONFIG"
			fi
			if [ X$tpriINFORMIXSERVER = X ]
			then
				priINFORMIXSERVER=$priINFORMIXSERVER
				log4s debug "priINFORMIXSERVER值为空，设置为默认：$priINFORMIXSERVER"
				priONCONFIG=onconfig.$priINFORMIXSERVER
				log4s debug "设置主机配置文件名为：onconfig.$priINFORMIXSERVER"
			else
				priINFORMIXSERVER=$tpriINFORMIXSERVER
				log4s debug "主机配置priINFORMIXSERVER为：$tpriINFORMIXSERVER"
				priONCONFIG=onconfig.${priINFORMIXSERVER}
				log4s debug "主机配置文件名为：$priONCONFIG"
			fi
			
			#secINFORMIXSERVER
			if [ X$peizhiqueren = XXXXXXX ]
			then
				read -p "请输入备机心跳线实例名，[默认为hdr2] ： " tsecINFORMIXSERVER
			fi
			if [ X$peizhiqueren != XXXXXXX ]
			then
				read -p "请输入备机心跳线实例名，刚才输入的是$secINFORMIXSERVER ： " tsecINFORMIXSERVER
			fi
			log4s debug "输入的备机心跳线实例名为：$tsecINFORMIXSERVER"
			if [ X$tsecINFORMIXSERVER = X ]
			then
				secINFORMIXSERVER=hdr2
				log4s debug "secINFORMIXSERVER值为空，设置为默认：hdr2"
				secONCONFIG=onconfig.$secINFORMIXSERVER
				log4s debug "设置备机配置文件名为：$secONCONFIG"
			else
				secINFORMIXSERVER=$tsecINFORMIXSERVER
				log4s debug "secINFORMIXSERVER配置为：$secINFORMIXSERVER"
				secONCONFIG=onconfig.${secINFORMIXSERVER}
				log4s debug "备机配置文件名为：$secONCONFIG"
			fi
			if [ X$tsecINFORMIXSERVER = X ]
			then
				secINFORMIXSERVER=$secINFORMIXSERVER
				log4s debug "secINFORMIXSERVER值为空，设置为默认：$secINFORMIXSERVER"
				secONCONFIG=onconfig.$secINFORMIXSERVER
				log4s debug "设置备机配置文件名为：$secONCONFIG"
			else
				secINFORMIXSERVER=$tsecINFORMIXSERVER
				log4s debug "secINFORMIXSERVER配置为：$secINFORMIXSERVER"
				secONCONFIG=onconfig.${secINFORMIXSERVER}
				log4s debug "备机配置文件名为：$secONCONFIG"
			fi
			
			#priDBSERVERALIASES
			if [ X$peizhiqueren = XXXXXXX ]
			then
				read -p "请输入主机业务实例名，不能与心跳线实例名相同，[默认为appdb1] ： " tpriDBSERVERALIASES
			fi
			if [ X$peizhiqueren != XXXXXXX ]
			then
				read -p "请输入主机业务实例名，刚才输入的是$priDBSERVERALIASES ： " tpriDBSERVERALIASES
			fi
			log4s debug "输入主机业务实例名为：$tpriDBSERVERALIASES"
			if [ X$tpriDBSERVERALIASES = X ]
			then
				priDBSERVERALIASES=appdb1
				log4s debug "输入的主机业务实例名为空，设置默认值为：appdb1"
			else
				priDBSERVERALIASES=$tpriDBSERVERALIASES
				log4s debug "输入的主机业务实例名为：$tpriDBSERVERALIASES"
			fi
			if [ X$tpriDBSERVERALIASES = X ]
			then
				priDBSERVERALIASES=$priDBSERVERALIASES
				log4s debug "输入的主机业务实例名为空，设置默认值为：$priDBSERVERALIASES"
			else
				priDBSERVERALIASES=$tpriDBSERVERALIASES
				log4s debug "输入的主机业务实例名为：$tpriDBSERVERALIASES"
			fi
			
			#secDBSERVERALIASES
			if [ X$peizhiqueren = XXXXXXX ]
			then
				read -p "请输入备机业务实例名，不能与心跳线实例名相同，[默认为appdb2] ： " tsecDBSERVERALIASES
			fi
			if [ X$peizhiqueren != XXXXXXX ]
			then
				read -p "请输入备机业务实例名，刚才输入的是$secDBSERVERALIASES ： " tsecDBSERVERALIASES
			fi
			log4s debug "输入的备机业务实例名为：$tsecDBSERVERALIASES"
			if [ X$tsecDBSERVERALIASES = X ]
			then
				secDBSERVERALIASES=appdb2
				log4s debug "输入的备业务实例名为空，设置默认值为：appdb2"
			else
				secDBSERVERALIASES=$tsecDBSERVERALIASES
				log4s debug "输入的备机业务实例名为：$tsecDBSERVERALIASES"
			fi
			if [ X$tsecDBSERVERALIASES = X ]
			then
				secDBSERVERALIASES=$secDBSERVERALIASES
				log4s debug "输入的备业务实例名为空，设置默认值为：$secDBSERVERALIASES"
			else
				secDBSERVERALIASES=$tsecDBSERVERALIASES
				log4s debug "输入的备机业务实例名为：$tsecDBSERVERALIASES"
			fi
			
			echo `ifconfig -a|grep "inet addr"|grep -v '127.0.0.1'|awk '{print $2}'|awk -F':' '{print $2}'`
			echo "上面的ip是当前主机的所有ip，请按照提示输入主备机相关ip，备机相关ip请去备机查看"
			#priip
			if [ X$peizhiqueren = XXXXXXX ]
			then
				read -p "请输入主机心跳线ip，[无默认值]："	priip
				while [[ X$priip = X || X$priip = XXXXXXX ]]
				do
					log4s info "输入主机心跳线ip不能为空，请重新输入"
					read -p "请输入主机心跳线ip，[无默认值]：" priip
				done
				read -p "请输入备机心跳线ip，[无默认值]："	secip
				while [[ X$secip = X || X$secip = XXXXXXX ]]
				do
					log4s info "输入备机心跳线ip不能为空，请重新输入"
					read -p "请输入备机心跳线ip，[无默认值]：" secip
				done
				read -p "请输入主机业务ip，[无默认值]："		priappip
				while [[ X$priappip = X || X$priappip = XXXXXXX ]]
				do
					log4s info "输入主机业务ip不能为空，请重新输入"
					read -p "请输入主机业务ip，[无默认值]：" priappip
				done
				read -p "请输入备机业务ip，[无默认值]："		secappip
				while [[ X$secappip = X || X$secappip = XXXXXXX ]]
				do
					log4s info "输入备机业务ip不能为空，请重新输入"
					read -p "请输入备机业务ip，[无默认值]：" secappip
				done
				read -p "请输入逻辑日志备份方式，alarmprogram为普通方式，备份使用alarmprogram备份到/dev/null；alarmAPI为使用alarmAPI方式，[默认为alarmprogram]：" templtapedev
				if [ X$templtapedev = X ] || [ X$templtapedev = XXXXXXX ]
				then
					templtapedev=alarmprogram
				fi
				while [[ $templtapedev != alarmprogram && $templtapedev != alarmAPI && $templtapedev != alarmapi ]]
				do
					log4s info "输入逻辑日志备份方式输入非法，请重新输入"
					read -p "请输入逻辑日志备份方式，alarmprogram为普通方式，备份使用alarmprogram备份到/dev/null；alarmAPI为使用alarmAPI方式，[默认为alarmprogram]：" templtapedev
					if [ X$templtapedev = X ] || [ X$templtapedev = XXXXXXX ]
					then
						templtapedev=alarmprogram
					fi
				done
			fi
			if [ X$peizhiqueren != XXXXXXX ]
			then
				read -p "请输入主机心跳线ip，刚才输入的是$priip："		priip
				while [[ X$priip = X || X$priip = XXXXXXX ]]
				do
					log4s info "输入主机心跳线ip不能为空，请重新输入"
					read -p "请输入主机心跳线ip，刚才输入的是$priip：" priip
				done
				read -p "请输入备机心跳线ip，刚才输入的是$secip："		secip
				while [[ X$secip = X || X$secip = XXXXXXX ]]
				do
					log4s info "输入备机心跳线ip不能为空，请重新输入"
					read -p "请输入备机心跳线ip，刚才输入的是$secip：" secip
				done
				read -p "请输入主机业务ip，刚才输入的是$priappip："		priappip
				while [[ X$priappip = X || X$priappip = XXXXXXX ]]
				do
					log4s info "输入主机业务ip不能为空，请重新输入"
					read -p "请输入主机业务ip，刚才输入的是$priappip：" priappip
				done
				read -p "请输入备机业务ip，刚才输入的是$secappip："		secappip
				while [[ X$secappip = X || X$secappip = XXXXXXX ]]
				do
					log4s info "输入备机业务ip不能为空，请重新输入"
					read -p "请输入备机业务ip，刚才输入的是$secappip：" secappip
				done
				read -p "请输入逻辑日志备份方式，刚才输入的是$templtapedev：" templtapedev
				while [[ X$templtapedev = X || X$templtapedev = XXXXXXX ]]
				do
					log4s info "输入逻辑日志备份方式不能为空，请重新输入"
					read -p "请输入逻辑日志备份方式，刚才输入的是$templtapedev：" templtapedev
				done
			fi
			log4s debug "请输入主机心跳线ip，[无默认值]： $priip"
			log4s debug "请输入备机心跳线ip，[无默认值]： $secip"
			log4s debug "请输入主机业务ip，[无默认值]：   $priappip"
			log4s debug "请输入备机业务ip，[无默认值]：   $secappip"
			log4s debug "请输入逻辑日志备份方式：         $templtapedev"
			
			ltapedev=`echo $templtapedev|tr '[A-Z]' '[a-z]'`
			if [ X$ltapedev = XALARMAPI ] || [ X$ltapedev = Xalarmapi ] || [ X$ltapedev = XalarmAPI ]
			then
				ltapedev=alarmapi
			else
				ltapedev=alarmprogram
			fi
			echo "下面是刚才输入的配置"
			echo "主机心跳线实例名：  ${priINFORMIXSERVER}"
			echo "备机心跳线实例名：  ${secINFORMIXSERVER}"
			echo "主机业务实例名：    ${priDBSERVERALIASES}"
			echo "备机业务实例名：    ${secDBSERVERALIASES}"
			echo "主机心跳线ip：      ${priip}"
			echo "备机心跳线ip：      ${secip}"
			echo "主机业务ip：        ${priappip}"
			echo "备机业务ip：        ${secappip}"
			echo "逻辑日志备份方式为：$ltapedev"
	
			read -p "配置是否正确，请输入y/n：" peizhiqueren
			while [[ X$peizhiqueren = X ]]
			do
				log4s info "配置确认不能输入空，请重新输入"
				read -p "配置是否正确，请输入y/n：" peizhiqueren
			done
			while [[ $peizhiqueren != [YyNn] ]]
			do
				log4s info "配置确认输入非法，请重新输入"
				read -p "配置是否正确，请输入y/n：" peizhiqueren
			done
			log4s debug "输入的确认配置peizhiqueren为：$peizhiqueren"
			#防止碰巧peizhiqueren=XXXXXX导致回显出问题
			if [ X$peizhiqueren = XXXXXXX ]
			then
				peizhiqueren=N
			fi
			

			#校验输入参数
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
				if [ X$ltapedev = Xalarmapi ]
				then
					if [ ! -f /tmp/alarmAPI.tar ]
					then
						log4s error "配置需要使用alarmAPI，但是在/tmp下没有alarmAPI.tar，所以将使用默认逻辑日志备份配置"
						ltapedev=alarmprogram
					fi
				fi
				if [ X$PpriINFORMIXSERVER != Xok ]
				then
					log4s error "主机心跳线实例名输入有误，请仔细检查"
					peizhiqueren=N
				fi
				if [ X$PsecINFORMIXSERVER != Xok ]
				then
					log4s error "备机心跳线实例名输入有误，请仔细检查"
					peizhiqueren=N
				fi
				if [ X$PpriDBSERVERALIASES != Xok ]
				then
					log4s error "主机业务实例名输入有误，请仔细检查"
					peizhiqueren=N
				fi
				if [ X$PsecDBSERVERALIASES != Xok ]
				then
					log4s error "备机业务实例名输入有误，请仔细检查"
					peizhiqueren=N
				fi
				
				if [ X$Ppriip != Xok ]
				then
					log4s error "主机心跳线ip输入有误，请仔细检查"
					peizhiqueren=N
				fi
				if [ X$Psecip != Xok ]
				then
					log4s error "备机心跳线ip输入有误，请仔细检查"
					peizhiqueren=N
				fi
				if [ X$Ppriappip != Xok ]
				then
					log4s error "主机业务ip输入有误，请仔细检查"
					peizhiqueren=N
				fi
				if [ X$Psecappip != Xok ]
				then
					log4s error "备机业务ip输入有误，请仔细检查"
					peizhiqueren=N
				fi
			fi
		fi
		#hdr模式结束
		
		#client模式
		if [ X$hdrflaginput = Xclient ]
		then
			client
		fi
		#client模式结束
	done
	#设置配置文件
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
	if [ X$hdrflag = Xonly ]
	then
		ONCONFIG=$priONCONFIG
		INFORMIXSERVER=$priINFORMIXSERVER
		DBSERVERNAME=$priDBSERVERNAME
		DBSERVERALIASES=$priDBSERVERALIASES
	fi
	
	while [[ $shifouquerenlvorfs != [Yy] ]]
	do
		read -p "请选择使用裸设备方式还是熟文件方式[裸设备请输入：lv    熟文件请输入：fs]：" lvorfs
		lvorfs=`echo $lvorfs|tr '[A-Z]' '[a-z]'`
		if [ X$lvorfs = Xlv ]
		then
			read -p "您选择的裸设备方式，是否确认[y/n]：" shifouquerenlvorfs
		elif [ X$lvorfs = Xfs ]
		then
			read -p "您选择的熟文件方式，是否确认[y/n]：" shifouquerenlvorfs
		else
			log4s info "您输入的是[$lvorfs]，输入不合法，请重新输入lv或fs"
		fi
	done
	log4s debug "当前输入的dbs方式为$lvorfs"
	
	#使用lv方式
	if [ X$lvorfs = Xlv ]
	then
		#磁盘划分
		
		#创建pv
		while [[ $shifouchuangjianpv != [YyNn] ]]
		do
			read -p "是否需要创建PV，如果创建pv，请输入[y/n]：" shifouchuangjianpv;
			if [ X$shifouchuangjianpv = X ]
			then
				#防止while中判断异常
				shifouchuangjianpv=x
			fi
		done
		if [ X$shifouchuangjianpv = Xy ] || [ X$shifouchuangjianpv = XY ]
		then
			#这里的判断devname是为了备机得到的devname是需要创建的devname了，不需要在输入
			shifouchuangjianpv=y
			log4s info "需要创建pv"
			if [ X$devname = XXXXXXX ]
			then
				while [[ $shifouqueredevname != [Yy] ]]
				do
					shifouqueredevname=y
					read -p "请输入硬盘全路径，比如/dev/sdb，[没有默认值]："  devname
					while [[ X$devname = X ]]
					do
						log4s info "硬盘全路径不能为空，请重新输入"
						read -p "请输入硬盘全路径，比如/dev/sdb，[没有默认值]：" devname
					done
					read -p "请务必确认硬盘路径是否为$devname，如果输入错误将造成不可预知的问题[y/n]：" shifouqueredevname
					while [[ X$shifouqueredevname = X ]]
					do
						log4s info "是否确认硬盘路径不能为空，请重新输入"
						read -p "请务必确认硬盘路径是否为$devname，如果输入错误将造成不可预知的问题[y/n]：" shifouqueredevname
					done
					while [[ $shifouqueredevname != [YyNn] ]]
					do
						log4s info "是否确认硬盘路径输入非法，请重新输入"
						read -p "请务必确认硬盘路径是否为$devname，如果输入错误将造成不可预知的问题[y/n]：" shifouqueredevname
					done
					log4s debug "shifouqueredevname的值为$shifouqueredevname"
					log4s debug "创建pv的路径为$devname"
					if [ X$shifouqueredevname != XY ] && [ X$shifouqueredevname != Xy ]
					then
						shifouqueredevname=N
					fi
				done
			fi
		else
			shifouchuangjianpv=n
		fi
		#创建pv结束
		
		#创建vg
		while [[ $shifouchuangjianvg != [YyNn] ]]
		do
			read -p "是否需要创建VG，如果创建vg，请输入y/n ：" shifouchuangjianvg;
			if [ X$shifouchuangjianvg = X ]
			then
				shifouchuangjianvg=x
			fi
		done
		if [ X$shifouchuangjianvg = Xy ] || [ X$shifouchuangjianvg = XY ]
		then
			log4s info "需要创建vg"
			while [[ $shifouqueredevname1 != [Yy] ]]
			do
				if [ X$devname = XXXXXXX ]
				then
					read -p "请输入vg的目录，比如/dev/sdb，[没有默认值]："  devname
					while [[ X$devname = X ]]
					do
						log4s info "vg的目录不能为空，请重新输入"
						read -p "请输入vg的目录，比如/dev/sdb，[没有默认值]：" devname
					done 
					log4s info "pv是手动创建，所以需要输入创建的vg的目录，为：$devname"
				fi
				read -p "请输入vg的名称，比如dbvg，[没有默认值]：" vgname;
				while [[ X$vgname = X ]]
				do
					log4s info "vg的名称不能为空，请重新输入"
					read -p "请输入vg的名称，比如dbvg，[没有默认值]：" vgname
				done 
				read -p "请务必确认vg名称是否为$vgname，如果输入错误将造成不可预知的问题[Y/N]：" shifouqueredevname1
				while [[ X$shifouqueredevname1 = X ]]
				do
					log4s info "是否确认vg名称，不能为空请重新输入"
					read -p "请务必确认vg名称是否为$vgname，如果输入错误将造成不可预知的问题[Y/N]：" shifouqueredevname1
				done
				while [[ $shifouqueredevname1 != [YyNn] ]]
				do
					log4s info "是否确认vg名称，输入非法，请重新输入"
					read -p "请务必确认vg名称是否为$vgname，如果输入错误将造成不可预知的问题[Y/N]：" shifouqueredevname1
				done
				if [ X$shifouqueredevname1 != XY ] && [ X$shifouqueredevname1 != Xy ]
				then
					shifouqueredevname1=N
				fi
			done
		else
		shifouchuangjianvg=n
		fi
		#创建vg结束
		
		#创建lv
		while [[ $shifouchuangjianlv != [YyNn] ]]
		do
			read -p "是否需要创建LV，如果创建LV，请输入y/n：" shifouchuangjianlv;
			if [ X$shifouchuangjianlv = X ] || [ X$shifouchuangjianlv = XXXXXXXX ]
			then
				shifouchuangjianlv=x
			fi
		done
		if [ X$shifouchuangjianlv = Xy ] || [ X$shifouchuangjianlv = XY ]
		then
			log4s info "需要创建lv"
			if [ X$shifouchuangjianvg = XN ] || [ X$shifouchuangjianvg = Xn ]
			then
				log4s info "之前没有通过脚本创建vg，需要指定vg名称和devname"
				if [ X$hdrflag = Xsec ]
				then
					log4s info "备机自动自动读取配置"
				else
					read -p "请输入vg名称，比如dbvg，[没有默认值]："  vgname
					while [[ X$vgname = X ]]
					do
						log4s info "vg名称不能为空，请重新输入"
						read -p "请输入vg名称，比如dbvg，[没有默认值]：" vgname
					done
					read -p "请输入vg的目录，比如/dev/sdb，[没有默认值]："  devname
					while [[ X$devname = X ]]
					do
						log4s info "pv名称不能为空，请重新输入"
						read -p "请输入vg的目录，比如/dev/sdb，[没有默认值]：" devname
					done
					log4s info "vg是手动创建的，需要输入vg和pv的名称，vg名称为：$vgname，vg的目录为$devname"
				fi
			fi
			while [[ $shifoutiaozhenglvsize != [YyNn] ]]
			do
				echo "默认lv大小为rootdbs=$tsizerootdbs1G,tempdbs1=$tsizetempdbs1G,tempdbs2=$tsizetempdbs2G,logdbs1=$tsizelogdbs1G,phydbs1=$tsizephydbs1G,userdbs1=$tsizeuserdbs1G，单位为G"
				read -p "是否需要调整lv大小，请输入[y/n] ：" shifoutiaozhenglvsize;
				while [[ X$shifoutiaozhenglvsize = X ]]
				do
					log4s info "是否调整lv大小不能为空，请重新输入"
					read -p "是否需要调整lv大小，请输入[y/n] ：" shifoutiaozhenglvsize
				done
				while [[ $shifoutiaozhenglvsize != [YyNn] ]]
				do
					log4s info "是否调整lv大小输入非法，请重新输入"
					read -p "是否需要调整lv大小，请输入[y/n] ：" shifoutiaozhenglvsize
				done
				if [ X$shifoutiaozhenglvsize != XY ] && [ X$shifoutiaozhenglvsize != Xy ]
				then
					shifoutiaozhenglvsize=n
				fi
			done
			if [ X$shifoutiaozhenglvsize = Xy ] || [ X$shifoutiaozhenglvsize = XY ]
			then
				while [[ $shifouquerenlvsize != [Yy] ]]
				do
					echo "请输入调整后的大小，单位为G，只需要输入数字即可，请确保硬盘大小可以满足调整后的lv"
					echo "如果不需要某个dbs则，[默认为0]。"
					read -p "rootdbs1大小，  [必须创建]："					sizerootdbs1G
					Pnum_sizerootdbs1G=`Pnum $sizerootdbs1G`
					while [[ X$sizerootdbs1G = X || X$sizerootdbs1G = XN || X$sizerootdbs1G = Xn || X$sizerootdbs1G = X0 || X$Pnum_sizerootdbs1G = Xno ]]
					do
						log4s info "rootdbs1大小输入非法，请重新输入"
						read -p "rootdbs1大小，  [必须创建]：" 			sizerootdbs1G
						Pnum_sizerootdbs1G=`Pnum $sizerootdbs1G`
					done
					read -p "tempdbs1大小，  [必须创建]："					sizetempdbs1G
					Pnum_sizetempdbs1G=`Pnum $sizetempdbs1G`
					while [[ X$sizetempdbs1G = X || X$sizetempdbs1G = XN || X$sizetempdbs1G = Xn || X$sizetempdbs1G = X0 || X$Pnum_sizetempdbs1G = Xno ]]
					do
						log4s info "tempdbs1大小输入非法，请重新输入"
						read -p "tempdbs1大小，  [必须创建]：" 			sizetempdbs1G
						Pnum_sizetempdbs1G=`Pnum $sizetempdbs1G`
					done
					read -p "tempdbs2大小，  [必须创建]："					sizetempdbs2G
					Pnum_sizetempdbs2G=`Pnum $sizetempdbs2G`
					while [[ X$sizetempdbs2G = X || X$sizetempdbs2G = XN || X$sizetempdbs2G = Xn || X$sizetempdbs2G = X0 || X$Pnum_sizetempdbs2G = Xno ]]
					do
						log4s info "tempdbs2大小输入非法，请重新输入"
						read -p "tempdbs2大小，  [必须创建]：" 			sizetempdbs2G
						Pnum_sizetempdbs2G=`Pnum $sizetempdbs2G`
					done
					read -p "logdbs1大小，   [必须创建]："					sizelogdbs1G
					Pnum_sizelogdbs1G=`Pnum $sizelogdbs1G`
					while [[ X$sizelogdbs1G = X || X$sizelogdbs1G = XN || X$sizelogdbs1G = Xn || X$sizelogdbs1G = X0 || X$Pnum_sizelogdbs1G = Xno ]]
					do
						log4s info "logdbs1大小输入非法，请重新输入"
						read -p "logdbs1大小，   [必须创建]：" 			sizelogdbs1G
						Pnum_sizelogdbs1G=`Pnum $sizelogdbs1G`
					done
					read -p "phydbs1大小，   [必须创建]："					sizephydbs1G
					Pnum_sizephydbs1G=`Pnum $sizephydbs1G`
					while [[ X$sizephydbs1G = X || X$sizephydbs1G = XN || X$sizephydbs1G = Xn || X$sizephydbs1G = X0 || X$Pnum_sizephydbs1G = Xno ]]
					do
						log4s info "phydbs1大小输入非法，请重新输入"
						read -p "phydbs1大小，   [必须创建]：" 			sizephydbs1G
						Pnum_sizephydbs1G=`Pnum $sizephydbs1G`
					done
					read -p "userdbs1大小，  [必须创建]："					sizeuserdbs1G
					Pnum_sizeuserdbs1G=`Pnum $sizeuserdbs1G`
					while [[ X$sizeuserdbs1G = X || X$sizeuserdbs1G = XN || X$sizeuserdbs1G = Xn || X$sizeuserdbs1G = X0 || X$Pnum_sizeuserdbs1G = Xno ]]
					do
						log4s info "userdbs1大小输入非法，请重新输入"
						read -p "userdbs1大小，  [必须创建]：" 			sizeuserdbs1G
						Pnum_sizeuserdbs1G=`Pnum $sizeuserdbs1G`
					done
					read -p "userdbs2大小，  [不输入默认为不创建]："		sizeuserdbs2G
					read -p "userdbs3大小，  [不输入默认为不创建]："		sizeuserdbs3G
					read -p "userdbs4大小，  [不输入默认为不创建]："		sizeuserdbs4G
					read -p "userdbs5大小，  [不输入默认为不创建]："		sizeuserdbs5G
					read -p "chargedbs1大小，[不输入默认为不创建]："		sizechargedbs1G
					read -p "chargedbs2大小，[不输入默认为不创建]："		sizechargedbs2G
					read -p "minfodbs1大小， [不输入默认为不创建]："		sizeminfodbs1G
					read -p "minfodbs2大小， [不输入默认为不创建]："		sizeminfodbs2G
					read -p "servdbs1大小，  [不输入默认为不创建]："		sizeservdbs1G
					read -p "servdbs2大小，  [不输入默认为不创建]："		sizeservdbs2G
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
					echo "重新调整后的大小如下："
					echo "rootdbs1大小：      $sizerootdbs1G"
					echo "tempdbs1大小：      $sizetempdbs1G"
					echo "tempdbs2大小：      $sizetempdbs2G"
					echo "logdbs1大小：       $sizelogdbs1G"
					echo "phydbs1大小：       $sizephydbs1G"
					echo "userdbs1大小：      $sizeuserdbs1G"
					echo "userdbs2大小：      $sizeuserdbs2G"
					echo "userdbs3大小：      $sizeuserdbs3G"
					echo "userdbs4大小：      $sizeuserdbs4G"
					echo "userdbs5大小：      $sizeuserdbs5G"
					echo "chargedbs1大小：    $sizechargedbs1G"
					echo "chargedbs2大小：    $sizechargedbs2G"
					echo "minfodbs1大小：     $sizeminfodbs1G"
					echo "minfodbs2大小：     $sizeminfodbs2G"
					echo "sizeservdbs1大小：  $sizeservdbs1G"
					echo "sizeservdbs2大小：  $sizeservdbs2G"
					read -p "是否确认调整后的大小，请输入[y/n]：" shifouquerenlvsize
					while [[ X$shifouquerenlvsize = X ]]
					do
						log4s info "是否确认调整后大小，输入不能为空，请重新输入"
						read -p "是否确认调整后的大小，请输入[y/n]：" shifouquerenlvsize
					done
					while [[ $shifouquerenlvsize != [Yy] ]]
					do
						log4s info "是否确认调整后大小，输入非法，请重新输入"
						read -p "是否确认调整后的大小，请输入[y/n]：" shifouquerenlvsize
					done
					if [ X$shifouquerenlvsize = X ]
					then
						shifouquerenlvsize=n
					fi
					#先判断是否所有大小都是数字
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
						echo "输入dbs有不为数字的情况，请重新输入。"
						shifouquerenlvsize=n
						continue;
					fi
					if [ X$sizerootdbs1G = X0 ]
					then
						echo "rootdbs1不能为0"
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
						echo "logdbs1不能为0"
						shifouquerenlvsize=n
						continue;
					fi
					if [ X$sizephydbs1G = X0 ]
					then
						echo "phydbs1不能为0"
						shifouquerenlvsize=n
						continue;
					fi
					if [ X$sizeuserdbs1G = X0 ]
					then
						echo "userdbs1不能为0"
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
		#创建lv结束
		
		#不创建lv，指定lv路径
		if [ $shifouchuangjianlv = N ] || [ $shifouchuangjianlv = n ]
		then
			log4s info "不需要创建lv，指定lv目录"
			while [[ $lvmuluqueren != [Yy] ]]
			do
				if [ $muban = cl ]
				then
					read -p "请输入vg名称，比如dbvg，[没有默认值]：" vgname
					while [[ X$vgname = X ]]
					do
						log4s info "vg名称不能为空，请重新输入"
						read -p "请输入vg名称，比如dbvg，[没有默认值]：" vgname
					done
					echo "请根据提示输入各lv的目录，举例/dev/$vgname/rootdbs1"
					echo "如果不需要这个dbs，则直接回车即可"
					read -p "rootdbs1的目录，[必须创建]："		lvrootdbs1
					while [[ X$lvrootdbs1 = X ]]
					do
						log4s info "rootdbs1的目录必须创建，请重新输入:"
						read -p "rootdbs1的目录，[必须创建]："	lvrootdbs1
					done
					read -p "tempdbs1的目录，[必须创建]："		lvtempdbs1
					while [[ X$lvtempdbs1 = X ]]
					do
						log4s info "tempdbs1的目录必须创建，请重新输入:"
						read -p "tempdbs1的目录，[必须创建]："	lvtempdbs1
					done
					read -p "tempdbs2的目录，[必须创建]："		lvtempdbs2
					while [[ X$lvtempdbs2 = X ]]
					do
						log4s info "tempdbs2的目录必须创建，请重新输入:"
						read -p "tempdbs2的目录，[必须创建]："	lvtempdbs2
					done
					read -p "logdbs1的目录， [必须创建]："		lvlogdbs1
					while [[ X$lvlogdbs1 = X ]]
					do
						log4s info "logdbs1的目录必须创建，请重新输入:"
						read -p "logdbs1的目录，[必须创建]："	  logdbs1
					done
					read -p "phydbs1的目录， [必须创建]："		lvphydbs1
					while [[ X$lvphydbs1 = X ]]
					do
						log4s info "phydbs1的目录必须创建，请重新输入:"
						read -p "phydbs1的目录，[必须创建]："	  phydbs1
					done
					read -p "userdbs1的目录，[必须创建]："		lvuserdbs1
					while [[ X$lvuserdbs1 = X ]]
					do
						log4s info "userdbs1的目录必须创建，请重新输入:"
						read -p "userdbs1的目录，[必须创建]："	userdbs1
					done
					read -p "userdbs2的目录，[不输入默认为不创建]："		lvuserdbs2
					read -p "userdbs3的目录，[不输入默认为不创建]："		lvuserdbs3
					read -p "userdbs4的目录，[不输入默认为不创建]："		lvuserdbs4
					read -p "userdbs5的目录，[不输入默认为不创建]："		lvuserdbs5
					read -p "chargedbs1的目录，[不输入默认为不创建]："	lvchargedbs1
					read -p "chargedbs2的目录，[不输入默认为不创建]："	lvchargedbs2
					read -p "minfodbs1的目录，[不输入默认为不创建]："		lvminfodbs1
					read -p "minfodbs2的目录，[不输入默认为不创建]："		lvminfodbs2
					read -p "servdbs1的目录，[不输入默认为不创建]："		lvservdbs1
					read -p "servdbs2的目录，[不输入默认为不创建]："		lvservdbs2
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

					echo "设置的dbs目录配置如下，请确认[Y/N]："
					echo "rootdbs1的目录：    $lvrootdbs1" 
					echo "tempdbs1的目录：    $lvtempdbs1" 
					echo "tempdbs2的目录：    $lvtempdbs2" 
					echo "logdbs1的目录：     $lvlogdbs1"
					echo "phydbs1的目录：     $lvphydbs1"
					echo "userdbs1的目录：    $lvuserdbs1"
					echo "userdbs2的目录：    $lvuserdbs2"
					echo "userdbs3的目录：    $lvuserdbs3"
					echo "userdbs4的目录：    $lvuserdbs4"
					echo "userdbs5的目录：    $lvuserdbs5"
					echo "chargedbs1的目录：  $lvchargedbs1"
					echo "chargedbs2的目录：  $lvchargedbs2"
					echo "minfodbs1的目录：   $lvminfodbs1"
					echo "minfodbs2的目录：   $lvminfodbs2"
					echo "servdbs1的目录：    $lvservdbs1"
					echo "servdbs2的目录：    $lvservdbs2"
					read -p "是否确认：[y/n]：" lvmuluqueren
					while [[ X$lvmuluqueren = X ]]
					do
						log4s info "是否确认目录，不能为空，请重新输入"
						read -p "是否确认：[y/n]：" lvmuluqueren
					done
					while [[ $lvmuluqueren != [YyNn] ]]
					do
						log4s info "是否确认目录，输入非法，请重新输入"
						read -p "是否确认：[y/n]：" lvmuluqueren
					done
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
				echo "请输设置的各dbs的大小，单位为G，只需要输入数字即可，请确保实际lv大小满足dbs"
				echo "如果不需要某个dbs则设置大小为0或者N或者n或者不输入都可以。"
				echo "rootdbs1的目录：    $lvrootdbs1" 
				read -p "rootdbs1大小，  [必须创建]："					sizerootdbs1G
				Pnum_sizerootdbs1G=`Pnum $sizerootdbs1G`
				while [[ X$sizerootdbs1G = X || X$sizerootdbs1G = XN || X$sizerootdbs1G = Xn || X$sizerootdbs1G = X0 || X$Pnum_sizerootdbs1G = Xno ]]
				do
					log4s info "rootdbs1大小输入非法，请重新输入"
					read -p "rootdbs1大小，  [必须创建]：" 			sizerootdbs1G
					Pnum_sizerootdbs1G=`Pnum $sizerootdbs1G`
				done
				echo "tempdbs1的目录：    $lvtempdbs1" 
				read -p "tempdbs1大小，  [必须创建]："					sizetempdbs1G
				Pnum_sizetempdbs1G=`Pnum $sizetempdbs1G`
				while [[ X$sizetempdbs1G = X || X$sizetempdbs1G = XN || X$sizetempdbs1G = Xn || X$sizetempdbs1G = X0 || X$Pnum_sizetempdbs1G = Xno ]]
				do
					log4s info "tempdbs1大小输入非法，请重新输入"
					read -p "tempdbs1大小，  [必须创建]：" 			sizetempdbs1G
					Pnum_sizetempdbs1G=`Pnum $sizetempdbs1G`
				done
				echo "tempdbs2的目录：    $lvtempdbs2" 
				read -p "tempdbs2大小，  [必须创建]："					sizetempdbs2G
				Pnum_sizetempdbs2G=`Pnum $sizetempdbs2G`
				while [[ X$sizetempdbs2G = X || X$sizetempdbs2G = XN || X$sizetempdbs2G = Xn || X$sizetempdbs2G = X0 || X$Pnum_sizetempdbs2G = Xno ]]
				do
					log4s info "tempdbs2大小输入非法，请重新输入"
					read -p "tempdbs2大小，  [必须创建]：" 			sizetempdbs2G
					Pnum_sizetempdbs2G=`Pnum $sizetempdbs2G`
				done
				echo "logdbs1的目录：     $lvlogdbs1"
				read -p "logdbs1大小，   [必须创建]："					sizelogdbs1G
				Pnum_sizelogdbs1G=`Pnum $sizelogdbs1G`
				while [[ X$sizelogdbs1G = X || X$sizelogdbs1G = XN || X$sizelogdbs1G = Xn || X$sizelogdbs1G = X0 || X$Pnum_sizelogdbs1G = Xno ]]
				do
					log4s info "logdbs1大小输入非法，请重新输入"
					read -p "logdbs1大小，   [必须创建]：" 			sizelogdbs1G
					Pnum_sizelogdbs1G=`Pnum $sizelogdbs1G`
				done
				echo "phydbs1的目录：     $lvphydbs1"
				read -p "phydbs1大小，   [必须创建]："					sizephydbs1G
				Pnum_sizephydbs1G=`Pnum $sizephydbs1G`
				while [[ X$sizephydbs1G = X || X$sizephydbs1G = XN || X$sizephydbs1G = Xn || X$sizephydbs1G = X0 || X$Pnum_sizephydbs1G = Xno ]]
				do
					log4s info "phydbs1大小输入非法，请重新输入"
					read -p "phydbs1大小，   [必须创建]：" 			sizephydbs1G
					Pnum_sizephydbs1G=`Pnum $sizephydbs1G`
				done
				echo "userdbs1的目录：    $lvuserdbs1"
				read -p "userdbs1大小，  [必须创建]："					sizeuserdbs1G
				Pnum_sizeuserdbs1G=`Pnum $sizeuserdbs1G`
				while [[ X$sizeuserdbs1G = X || X$sizeuserdbs1G = XN || X$sizeuserdbs1G = Xn || X$sizeuserdbs1G = X0 || X$Pnum_sizeuserdbs1G = Xno ]]
				do
					log4s info "userdbs1大小输入非法，请重新输入"
					read -p "userdbs1大小，  [必须创建]：" 			sizeuserdbs1G
					Pnum_sizeuserdbs1G=`Pnum $sizeuserdbs1G`
				done
				if [ X$lvuserdbs2 = X0 ]
				then
					log4s info "不创建userdbs2"
					sizeuserdbs2G=0
				else
					echo "userdbs2的目录：    $lvuserdbs2"
					read -p "userdbs2大小，[不输入默认为0]："		sizeuserdbs2G
				fi
				if [ X$lvuserdbs3 = X0 ]
				then
					log4s info "不创建userdbs3"
					sizeuserdbs3G=0
				else
					echo "userdbs3的目录：    $lvuserdbs3"
					read -p "userdbs3大小，[不输入默认为0]："		sizeuserdbs3G
				fi
				if [ X$lvuserdbs4 = X0 ]
				then
					log4s info "不创建userdbs4"
					sizeuserdbs4G=0
				else
					echo "userdbs4的目录：    $lvuserdbs4"
					read -p "userdbs4大小，[不输入默认为0]："		sizeuserdbs4G
				fi
				if [ X$lvuserdbs5 = X0 ]
				then
					log4s info "不创建userdbs5"
					sizeuserdbs5G=0
				else
					echo "userdbs5的目录：    $lvuserdbs5"
					read -p "userdbs5大小，[不输入默认为0]："		sizeuserdbs5G
				fi
				if [ X$lvchargedbs1 = X0 ]
				then
					log4s info "不创建chargedbs1"
					sizechargedbs1G=0
				else
					echo "chargedbs1的目录：  $lvchargedbs1"
					read -p "chargedbs1大小，[不输入默认为0]："	sizechargedbs1G
				fi
				if [ X$lvchargedbs2 = X0 ]
				then
					log4s info "不创建chargedbs2"
					sizechargedbs2G=0
				else
					echo "chargedbs2的目录：  $lvchargedbs2"
					read -p "chargedbs2大小，[不输入默认为0]："	sizechargedbs2G
				fi
				if [ X$lvminfodbs1 = X0 ]
				then
					log4s info "不创建minfodbs1"
					sizeminfodbs1G=0
				else
					echo "minfodbs1的目录：   $lvminfodbs1"
					read -p "minfodbs1大小，[不输入默认为0]："  sizeminfodbs1G
				fi
				if [ X$lvminfodbs2 = X0 ]
				then
					log4s info "不创建minfodbs2"
					sizeminfodbs2G=0
				else
					echo "minfodbs2的目录：   $lvminfodbs2"
					read -p "minfodbs2大小，[不输入默认为0]："  sizeminfodbs2G
				fi
				if [ X$lvservdbs1 = X0 ]
				then
					log4s info "不创建servdbs1"
					sizeservdbs1G=0
				else
					echo "servdbs1的目录：    $lvservdbs1"
					read -p "servdbs1大小，[不输入默认为0]："		sizeservdbs1G
				fi
				if [ X$lvservdbs2 = X0 ]
				then
					log4s info "不创建servdbs2"
					sizeservdbs2G=0
				else
					echo "servdbs2的目录：    $lvservdbs2"
					read -p "servdbs2大小，[不输入默认为0]："		sizeservdbs2G
				fi

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
				echo "设置的dbs的大小如下："
				echo "rootdbs1大小：      $sizerootdbs1G"
				echo "tempdbs1大小：      $sizetempdbs1G"
				echo "tempdbs2大小：      $sizetempdbs2G"
				echo "logdbs1大小：       $sizelogdbs1G"
				echo "phydbs1大小：       $sizephydbs1G"
				echo "userdbs1大小：      $sizeuserdbs1G"
				echo "userdbs2大小：      $sizeuserdbs2G"
				echo "userdbs3大小：      $sizeuserdbs3G"
				echo "userdbs4大小：      $sizeuserdbs4G"
				echo "userdbs5大小：      $sizeuserdbs5G"
				echo "chargedbs1大小：    $sizechargedbs1G"
				echo "chargedbs2大小：    $sizechargedbs2G"
				echo "minfodbs1大小：     $sizeminfodbs1G"
				echo "minfodbs2大小：     $sizeminfodbs2G"
				echo "sizeservdbs1大小： $sizeservdbs1G"
				echo "sizeservdbs2大小： $sizeservdbs2G"
				read -p "是否确认调整后的大小[Y/N]，[默认为n]：" shifouquerenlvsize
				while [[ X$shifouquerenlvsize = X ]]
				do
					log4s info "是否确认调整后的大小，不能为空，请重新输入"
					read -p "是否确认调整后的大小[Y/N]，[默认为n]：" shifouquerenlvsize
				done
				while [[ $shifouquerenlvsize != [YyNn] ]]
				do
					log4s info "是否确认调整后的大小，输入非法，请重新输入"
					read -p "是否确认调整后的大小[Y/N]，[默认为n]：" shifouquerenlvsize
				done
				#先判断是否所有大小都是数字
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
					echo "输入dbs有不为数字的情况，请重新输入。"
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
		#不创建lv，指定lv路径结束
	fi
	#使用lv方式结束
	
	#使用fs方式开始
	if [ X$lvorfs = Xfs ]
	then
		#写这里
		log4s info "选择使用文件系统方式创建dbs，目录为$idshome/dbfiles，请输入各dbs大小"
		lvrootdbs1=$idshome/dbfiles/rootdbs1
		lvtempdbs1=$idshome/dbfiles/tempdbs1
		lvtempdbs2=$idshome/dbfiles/tempdbs2
		lvlogdbs1=$idshome/dbfiles/logdbs1
		lvphydbs1=$idshome/dbfiles/phydbs1
		lvuserdbs1=$idshome/dbfiles/userdbs1
		lvuserdbs2=$idshome/dbfiles/userdbs2
		lvuserdbs3=$idshome/dbfiles/userdbs3
		lvuserdbs4=$idshome/dbfiles/userdbs4
		lvuserdbs5=$idshome/dbfiles/userdbs5
		lvchargedbs1=$idshome/dbfiles/chargedbs1
		lvchargedbs2=$idshome/dbfiles/chargedbs2
		lvminfodbs1=$idshome/dbfiles/minfodbs1
		lvminfodbs2=$idshome/dbfiles/minfodbs2
		lvservdbs1=$idshome/dbfiles/servdbs1
		lvservdbs2=$idshome/dbfiles/servdbs2
		while [[ $shifouquerendbssize != [Yy] ]]
		do
			echo "请输设置的各dbs的大小，单位为G，只需要输入数字即可，请确保实际硬盘大小满足dbs"
			echo "如果不需要某个dbs则设置大小为0或者N或者n或者不输入都可以。"
			echo "rootdbs1的目录：    $lvrootdbs1" 
			read -p "rootdbs1大小，  [必须创建]："					sizerootdbs1G
			Pnum_sizerootdbs1G=`Pnum $sizerootdbs1G`
			while [[ X$sizerootdbs1G = X || X$sizerootdbs1G = XN || X$sizerootdbs1G = Xn || X$sizerootdbs1G = X0 || X$Pnum_sizerootdbs1G = Xno ]]
			do
				log4s info "rootdbs1大小输入非法，请重新输入"
				read -p "rootdbs1大小，  [必须创建]：" 			sizerootdbs1G
				Pnum_sizerootdbs1G=`Pnum $sizerootdbs1G`
			done
			echo "tempdbs1的目录：    $lvtempdbs1" 
			read -p "tempdbs1大小，  [必须创建]："					sizetempdbs1G
			Pnum_sizetempdbs1G=`Pnum $sizetempdbs1G`
			while [[ X$sizetempdbs1G = X || X$sizetempdbs1G = XN || X$sizetempdbs1G = Xn || X$sizetempdbs1G = X0 || X$Pnum_sizetempdbs1G = Xno ]]
			do
				log4s info "tempdbs1大小输入非法，请重新输入"
				read -p "tempdbs1大小，  [必须创建]：" 			sizetempdbs1G
				Pnum_sizetempdbs1G=`Pnum $sizetempdbs1G`
			done
			echo "tempdbs2的目录：    $lvtempdbs2" 
			read -p "tempdbs2大小，  [必须创建]："					sizetempdbs2G
			Pnum_sizetempdbs2G=`Pnum $sizetempdbs2G`
			while [[ X$sizetempdbs2G = X || X$sizetempdbs2G = XN || X$sizetempdbs2G = Xn || X$sizetempdbs2G = X0 || X$Pnum_sizetempdbs2G = Xno ]]
			do
				log4s info "tempdbs2大小输入非法，请重新输入"
				read -p "tempdbs2大小，  [必须创建]：" 			sizetempdbs2G
				Pnum_sizetempdbs2G=`Pnum $sizetempdbs2G`
			done
			echo "logdbs1的目录：     $lvlogdbs1"
			read -p "logdbs1大小，   [必须创建]："					sizelogdbs1G
			Pnum_sizelogdbs1G=`Pnum $sizelogdbs1G`
			while [[ X$sizelogdbs1G = X || X$sizelogdbs1G = XN || X$sizelogdbs1G = Xn || X$sizelogdbs1G = X0 || X$Pnum_sizelogdbs1G = Xno ]]
			do
				log4s info "logdbs1大小输入非法，请重新输入"
				read -p "logdbs1大小，   [必须创建]：" 			sizelogdbs1G
				Pnum_sizelogdbs1G=`Pnum $sizelogdbs1G`
			done
			echo "phydbs1的目录：     $lvphydbs1"
			read -p "phydbs1大小，   [必须创建]："					sizephydbs1G
			Pnum_sizephydbs1G=`Pnum $sizephydbs1G`
			while [[ X$sizephydbs1G = X || X$sizephydbs1G = XN || X$sizephydbs1G = Xn || X$sizephydbs1G = X0 || X$Pnum_sizephydbs1G = Xno ]]
			do
				log4s info "phydbs1大小输入非法，请重新输入"
				read -p "phydbs1大小，   [必须创建]：" 			sizephydbs1G
				Pnum_sizephydbs1G=`Pnum $sizephydbs1G`
			done
			echo "userdbs1的目录：    $lvuserdbs1"
			read -p "userdbs1大小，  [必须创建]："					sizeuserdbs1G
			Pnum_sizeuserdbs1G=`Pnum $sizeuserdbs1G`
			while [[ X$sizeuserdbs1G = X || X$sizeuserdbs1G = XN || X$sizeuserdbs1G = Xn || X$sizeuserdbs1G = X0 || X$Pnum_sizeuserdbs1G = Xno ]]
			do
				log4s info "userdbs1大小输入非法，请重新输入"
				read -p "userdbs1大小，  [必须创建]：" 			sizeuserdbs1G
				Pnum_sizeuserdbs1G=`Pnum $sizeuserdbs1G`
			done
			echo "userdbs2的目录：    $lvuserdbs2"
			read -p "userdbs2大小，[不输入默认为0]："		sizeuserdbs2G
			echo "userdbs3的目录：    $lvuserdbs3"
			read -p "userdbs3大小，[不输入默认为0]："		sizeuserdbs3G
			echo "userdbs4的目录：    $lvuserdbs4"
			read -p "userdbs4大小，[不输入默认为0]："		sizeuserdbs4G
			echo "userdbs5的目录：    $lvuserdbs5"
			read -p "userdbs5大小，[不输入默认为0]："		sizeuserdbs5G
			echo "chargedbs1的目录：  $lvchargedbs1"
			read -p "chargedbs1大小，[不输入默认为0]："	sizechargedbs1G
			echo "chargedbs2的目录：  $lvchargedbs2"
			read -p "chargedbs2大小，[不输入默认为0]："	sizechargedbs2G
			echo "minfodbs1的目录：   $lvminfodbs1"
			read -p "minfodbs1大小，[不输入默认为0]："		sizeminfodbs1G
			echo "minfodbs2的目录：   $lvminfodbs2"
			read -p "minfodbs2大小，[不输入默认为0]："		sizeminfodbs2G
			echo "servdbs1的目录：    $lvservdbs1"
			read -p "servdbs1大小，[不输入默认为0]："		sizeservdbs1G
			echo "servdbs2的目录：    $lvservdbs2"
			read -p "servdbs2大小，[不输入默认为0]："		sizeservdbs2G
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
			echo "设置的dbs的大小如下："
			echo "rootdbs1大小：      $sizerootdbs1G"
			echo "tempdbs1大小：      $sizetempdbs1G"
			echo "tempdbs2大小：      $sizetempdbs2G"
			echo "logdbs1大小：       $sizelogdbs1G"
			echo "phydbs1大小：       $sizephydbs1G"
			echo "userdbs1大小：      $sizeuserdbs1G"
			echo "userdbs2大小：      $sizeuserdbs2G"
			echo "userdbs3大小：      $sizeuserdbs3G"
			echo "userdbs4大小：      $sizeuserdbs4G"
			echo "userdbs5大小：      $sizeuserdbs5G"
			echo "chargedbs1大小：    $sizechargedbs1G"
			echo "chargedbs2大小：    $sizechargedbs2G"
			echo "minfodbs1大小：     $sizeminfodbs1G"
			echo "minfodbs2大小：     $sizeminfodbs2G"
			echo "sizeservdbs1大小： $sizeservdbs1G"
			echo "sizeservdbs2大小： $sizeservdbs2G"
			read -p "是否确认设置大小[y/n]：" shifouquerendbssize
			while [[ $shifouquerendbssize != [YyNn] ]]
			do
				read -p "输入不能为空，是否确认设置大小[y/n]：" shifouquerendbssize
			done
		done
	fi
	let sizerootdbs1=sizerootdbs1G*1000000
	let sizetempdbs1=sizetempdbs1G*1000000
	let sizetempdbs2=sizetempdbs2G*1000000
	let sizelogdbs1=sizelogdbs1G*1000000
	let sizephydbs1=sizephydbs1G*1000000
	let sizeuserdbs1=sizeuserdbs1G*1000000
	let sizeuserdbs2=sizeuserdbs2G*1000000
	let sizeuserdbs3=sizeuserdbs3G*1000000
	let sizeuserdbs4=sizeuserdbs4G*1000000
	let sizeuserdbs5=sizeuserdbs5G*1000000
	let sizechargedbs1=sizechargedbs1G*1000000
	let sizechargedbs2=sizechargedbs2G*1000000
	let sizeminfodbs1=sizeminfodbs1G*1000000
	let sizeminfodbs2=sizeminfodbs2G*1000000
	let sizeservdbs1=sizeservdbs1G*1000000
	let sizeservdbs2=sizeservdbs2G*1000000
}
ZhanWeiflag()
{
	#第一阶段，基本参数占位符修改
	if [ X$hdrflag = Xonly ]
	then
		xiugai "hdrflag=XXXXXX"                 "hdrflag=only"
	fi
	if [ X$hdrflag = Xpri ]
	then
		#这里内存和文件不一致，是因为文件是给备机用的
		xiugai "hdrflag=XXXXXX"                 "hdrflag=sec"
	fi
	xiugai "^peizhiqueren=XXXXXX"               "peizhiqueren=$peizhiqueren"
	xiugai "^priINFORMIXSERVER=XXXXXX"			"priINFORMIXSERVER=$priINFORMIXSERVER"
	xiugai "^secINFORMIXSERVER=XXXXXX"			"secINFORMIXSERVER=$secINFORMIXSERVER"
	xiugai "^priDBSERVERALIASES=XXXXXX"			"priDBSERVERALIASES=$priDBSERVERALIASES"
	xiugai "^secDBSERVERALIASES=XXXXXX"			"secDBSERVERALIASES=$secDBSERVERALIASES"
	xiugai "^priip=XXXXXX"                      "priip=$priip"
	xiugai "^secip=XXXXXX"                      "secip=$secip"
	xiugai "^priappip=XXXXXX"                   "priappip=$priappip"
	xiugai "^secappip=XXXXXX"                   "secappip=$secappip"
	xiugai "^priONCONFIG=XXXXXX"                "priONCONFIG=$priONCONFIG"
	xiugai "^secONCONFIG=XXXXXX"                "secONCONFIG=$secONCONFIG"
	xiugai "^ltapedev=XXXXXX"                   "ltapedev=$ltapedev"
	#第二阶段，硬盘划分占位符修改
	xiugai "^shifouquerenlvorfs=XXXXXX"         "shifouquerenlvorfs=$shifouquerenlvorfs"
	xiugai "^lvorfs=XXXXXX"                     "lvorfs=$lvorfs"
	xiugai "^shifouquerendbssize=XXXXXX"        "shifouquerendbssize=$shifouquerendbssize"
	
	xiugai "^shifouchuangjianpv=XXXXXX"         "shifouchuangjianpv=$shifouchuangjianpv"
	xiugai "^shifouqueredevname=XXXXXX"         "shifouqueredevname=$shifouqueredevname"
	xiugai "^devname=XXXXXX"                    "devname=$devname"
	
	xiugai "^shifouchuangjianvg=XXXXXX"			"shifouchuangjianvg=$shifouchuangjianvg"
	xiugai "^vgname=XXXXXX"                     "vgname=$vgname"
	xiugai "^shifouqueredevname1=XXXXXX"        "shifouqueredevname1=$shifouqueredevname1"
	
	xiugai "^shifouchuangjianlv=XXXXXX"			"shifouchuangjianlv=$shifouchuangjianlv"
	xiugai "^vgname=XXXXXX"                     "vgname=$vgname"
	xiugai "^shifoutiaozhenglvsize=XXXXXX"		"shifoutiaozhenglvsize=$shifoutiaozhenglvsize"
	xiugai "^shifouquerenlvsize=XXXXXX"			"shifouquerenlvsize=$shifouquerenlvsize"
	xiugai "^sizerootdbs1G=XXXXXX"              "sizerootdbs1G=$sizerootdbs1G"
	xiugai "^sizetempdbs1G=XXXXXX"              "sizetempdbs1G=$sizetempdbs1G"
	xiugai "^sizetempdbs2G=XXXXXX"              "sizetempdbs2G=$sizetempdbs2G"
	xiugai "^sizelogdbs1G=XXXXXX"               "sizelogdbs1G=$sizelogdbs1G"
	xiugai "^sizephydbs1G=XXXXXX"               "sizephydbs1G=$sizephydbs1G"
	xiugai "^sizeuserdbs1G=XXXXXX"              "sizeuserdbs1G=$sizeuserdbs1G"
	xiugai "^sizeuserdbs2G=XXXXXX"              "sizeuserdbs2G=$sizeuserdbs2G"
	xiugai "^sizeuserdbs3G=XXXXXX"              "sizeuserdbs3G=$sizeuserdbs3G"
	xiugai "^sizeuserdbs4G=XXXXXX"              "sizeuserdbs4G=$sizeuserdbs4G"
	xiugai "^sizeuserdbs5G=XXXXXX"              "sizeuserdbs5G=$sizeuserdbs5G"
	xiugai "^sizechargedbs1G=XXXXXX"            "sizechargedbs1G=$sizechargedbs1G"
	xiugai "^sizechargedbs2G=XXXXXX"            "sizechargedbs2G=$sizechargedbs2G"
	xiugai "^sizeminfodbs1G=XXXXXX"             "sizeminfodbs1G=$sizeminfodbs1G"
	xiugai "^sizeminfodbs2G=XXXXXX"             "sizeminfodbs2G=$sizeminfodbs2G"
	xiugai "^sizeservdbs1G=XXXXXX"              "sizeservdbs1G=$sizeservdbs1G"
	xiugai "^sizeservdbs2G=XXXXXX"              "sizeservdbs2G=$sizeservdbs2G"
	
	xiugai "^lvrootdbs1=XXXXXX"                 "lvrootdbs1=$lvrootdbs1"
	xiugai "^lvtempdbs1=XXXXXX"                 "lvtempdbs1=$lvtempdbs1"
	xiugai "^lvtempdbs2=XXXXXX"                 "lvtempdbs2=$lvtempdbs2"
	xiugai "^lvlogdbs1=XXXXXX"                  "lvlogdbs1=$lvlogdbs1"
	xiugai "^lvphydbs1=XXXXXX"                  "lvphydbs1=$lvphydbs1"
	xiugai "^lvuserdbs1=XXXXXX"                 "lvuserdbs1=$lvuserdbs1"
	xiugai "^lvuserdbs2=XXXXXX"                 "lvuserdbs2=$lvuserdbs2"
	xiugai "^lvuserdbs3=XXXXXX"                 "lvuserdbs3=$lvuserdbs3"
	xiugai "^lvuserdbs4=XXXXXX"                 "lvuserdbs4=$lvuserdbs4"
	xiugai "^lvuserdbs5=XXXXXX"                 "lvuserdbs5=$lvuserdbs5"
	xiugai "^lvchargedbs1=XXXXXX"               "lvchargedbs1=$lvchargedbs1"
	xiugai "^lvchargedbs2=XXXXXX"               "lvchargedbs2=$lvchargedbs2"
	xiugai "^lvminfodbs1=XXXXXX"                "lvminfodbs1=$lvminfodbs1"
	xiugai "^lvminfodbs2=XXXXXX"                "lvminfodbs2=$lvminfodbs2"
	xiugai "^lvservdbs1=XXXXXX"                 "lvservdbs1=$lvservdbs1"
	xiugai "^lvservdbs2=XXXXXX"                 "lvservdbs2=$lvservdbs2"
	xiugai "^lvmuluqueren=XXXXXX"               "lvmuluqueren=$lvmuluqueren"
}
touchfsdbs()
{
	#$1是dbs目录，$2是dbs大小，大小为0的不创建，$3是dbs名称
	if [ $2  = 0 ]
	then
		log4s info "$3 设置大小为0，不创建"
	else
		log4s info "$3 设置大小为${2}G，开始创建"
		touch $1
		if [ $? = 0 ]
		then
			log4s info "$3创建成功"
		else
			log4s error "$3创建失败，请检查目录$1"
			exit 1;
		fi
	fi
}
startdisk()
{
	if [ $lvorfs = lv ]
	then
		if [ $shifouchuangjianlv = y ] || [ $shifouchuangjianlv = Y ]
		then
			if [ $devname != XXXXXX ]
			then
				if [ $shifouqueredevname = Y ] || [ $shifouqueredevname = y ]
				then
					log4s info "开始创建pv"
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
					log4s info "开始创建vg，vg名为：$vgname，pv名为：$devname"
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
						log4s info "开始创建lv"
						makelv rootdbs1		$sizerootdbs1G		$vgname
						makelv tempdbs1		$sizetempdbs1G		$vgname
						makelv tempdbs2		$sizetempdbs2G		$vgname
						makelv logdbs1		$sizelogdbs1G       $vgname
						makelv phydbs1		$sizephydbs1G       $vgname
						makelv userdbs1		$sizeuserdbs1G		$vgname
						makelv userdbs2		$sizeuserdbs2G		$vgname
						makelv userdbs3	    $sizeuserdbs3G		$vgname
						makelv userdbs4		$sizeuserdbs4G		$vgname
						makelv userdbs5		$sizeuserdbs5G		$vgname
						makelv chargedbs1	$sizechargedbs1G	$vgname
						makelv chargedbs2   $sizechargedbs2G	$vgname
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
	fi
	if [ $lvorfs = fs ]
	then
		let needsize=sizerootdbs1G+sizetempdbs1G+sizetempdbs2G+sizelogdbs1G+sizephydbs1G+sizeuserdbs1G+sizeuserdbs2G+sizeuserdbs3G+sizeuserdbs4G+sizeuserdbs5G+sizechargedbs1G+sizechargedbs2G+sizeminfodbs1G+sizeminfodbs2G+sizeservdbs1G+sizeservdbs2G
		let needsizek=needsize*1000000
		truesize=`df -kP $idshome|tail -1|awk '{print $4}'`
		if [ $truesize -lt $needsize ]
		then
			log4s error "需要的空间大小为${needsize}G，但实际只有${truesize}G，请重新设置"
			exit 1;
		else
			touchfsdbs   $lvrootdbs1     $sizerootdbs1G     rootdbs
			touchfsdbs   $lvtempdbs1     $sizetempdbs1G     tempdbs1
			touchfsdbs   $lvtempdbs2     $sizetempdbs2G     tempdbs2
			touchfsdbs   $lvlogdbs1      $sizelogdbs1G      logdbs1
			touchfsdbs   $lvphydbs1      $sizephydbs1G      phydbs1
			touchfsdbs   $lvuserdbs1     $sizeuserdbs1G     userdbs1
			touchfsdbs   $lvuserdbs2     $sizeuserdbs2G     userdbs2
			touchfsdbs   $lvuserdbs3     $sizeuserdbs3G     userdbs3
			touchfsdbs   $lvuserdbs4     $sizeuserdbs4G     userdbs4
			touchfsdbs   $lvuserdbs5     $sizeuserdbs5G     userdbs5
			touchfsdbs   $lvchargedbs1   $sizechargedbs1G   chargedbs1
			touchfsdbs   $lvchargedbs2   $sizechargedbs2G   chargedbs2
			touchfsdbs   $lvminfodbs1    $sizeminfodbs1G    minfodbs1
			touchfsdbs   $lvminfodbs2    $sizeminfodbs2G    minfodbs2
			touchfsdbs   $lvservdbs1     $sizeservdbs1G     servdbs1
			touchfsdbs   $lvservdbs2     $sizeservdbs2G     servdbs2
		fi
	fi
}










#####################备机区############
huifu()
{
	log4s info "取消rsh的允许启动"
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

	log4s info "取消脚本的自启动"

	rm -rf /tmp/temp.sh

}
beijijianting1()
{
	echo "secbootok" > /tmp/bootok.txt
	tempflag=`nc -l $tongxinduankou1 </tmp/bootok.txt`
	if [ X$tempflag = Xkaishihdr ]
	then
		log4s info  "已通知主机备机安装完成，等待主机搭建hdr"
		log4s debug "已经启动备机监听1"
	  beijihuifu;
	  killall nc
	fi

}

#############安装区##########################
#判断是否已经将软件安装成功并重启，未重启过就正常安装改内核参数重启，重启过就进行下面的步骤。
anzhuang()
{
	stty erase ^H;
	if [ ! -d $idshome ]
	then
		mkdir $idshome
		log4s info "创建安装目录"
	fi
	querenanzhuangbao;
	CheckP;
	InputAndCheck;
	ZhanWeiflag;
	if [ ! -d $idshome/dbfiles ]
	then
		log4s info "创建dbfiles目录"
		mkdir $idshome/dbfiles 1>/dev/null 2>&1
		chown informix:informix $idshome/dbfiles 1>/dev/null 2>&1
		chmod 775 $idshome/dbfiles 1>/dev/null 2>&1
	fi
	startdisk;
	chmod 777 /tmp

	peizhi=$idshome/etc/$ONCONFIG
	wai=`whoami`
	if [ X$wai != Xroot ]
	then
	log4s error "请使用root账户进行安装"
	exit 1;
	fi
	if [ X$X86 != Xx86_64 ]
	then
		log4s error "系统为32位版本，暂时不支持"
		exit 1;
	fi
	if [ ! -f /tmp/$jiaobenming ]
	then
		log4s error "请将本脚本放在/tmp文件夹下"
		exit 1;
	fi
	if [ ! -f /tmp/$anzhuangbao ]
	then
		log4s error "请将$anzhuangbao放到/tmp下";
		exit 1;
	fi
	FILEsize=`stat -c %s /tmp/$anzhuangbao`
	if [ X$FILEsize != X$filesize ]
	then
		log4s error "文件大小不正确，请核对后再进行，大小应为${filesize}字节";
		exit 1;
	fi
	if [ $tXTBB -le 5009 ] || [ $tXTBB -ge 7906 ]
	then
		log4s error "系统版本暂不支持，请联系脚本开发人员"
		exit 1;
	fi
	if [ ! -f $alreadyornolog ]
	then
		touch $alreadyornolog
		log4s info "创建数据库编译标识文件$alreadyornolog"
		initflag=0
	else
		log4s info "安装标识文件存在"
		initflag=`grep "alreadyinstall informix" $alreadyornolog|wc -l|awk '{print $1}'`
	fi
if [ $initflag = 0 ]
then
	#用户是否存在，如果不存在就建立
	log4s debug "安装标识文件中不存在安装标识，可以正常安装"
	userexistflag=`grep informix /etc/passwd|wc -l|awk '{print $1}'`
	if [ X$userexistflag != X1 ]
	then
		#linux安装步骤
		if [ X$XITONG = XLINUX ]
		then
			log4s info "建立用户组"
			groupadd informix;
			log4s info "建立用户"
			useradd -g informix -d $informixhome informix;
			chown informix:informix $idshome
			chmod 770 $idshome
			passwd informix <<EOF
EBupt!@#456
EBupt!@#456
EOF
		fi
		#AIX安装步骤
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
		log4s info "正在将脚本和安装包复制到备机，请手动输入密码（需要多次）"
		mkdir /tmp/scptempdir/
		cp /tmp/tempIFX12.sh /tmp/scptempdir/$jiaobenming
		if [ X$ltapedev = Xalarmapi ]
		then
			cp /tmp/alarmAPI.tar /tmp/scptempdir/alarmAPI.tar
		fi
		mv /tmp/$anzhuangbao /tmp/scptempdir/
		scp -oPort=$sshport -r /tmp/scptempdir/* root@$secip:/tmp/
		mv /tmp/scptempdir/$anzhuangbao /tmp/
		ssh -oPort=$sshport root@$secip "cd /tmp;nohup sh ./$jiaobenming anzhuang >/tmp/anzhuang.log 2>&1 &"
		log4s info "需要交互的内容结束，后面开始全自动安装，包括编译数据库，搭建HDR，请勿在安装过程中做任何操作"
		echo "需要交互的内容结束，后面开始全自动安装，包括编译数据库，搭建HDR，请勿在安装过程中做任何操作"
		echo "需要交互的内容结束，后面开始全自动安装，包括编译数据库，搭建HDR，请勿在安装过程中做任何操作"
		sleep 10;
	fi

	
	
	log4s info "移动安装包到安装目录"
	mv $anzhuangbao $idshome/
	cd $idshome;
	log4s info "解压安装包"
	tar -xvf  $idshome/$anzhuangbao -C $idshome/
	mv $idshome/$anzhuangbao /tmp
	log4s info "开始自动编译数据库"
	$idshome/ids_install <<EOF

1
$idshome/
Y

1
2



EOF
	
	log4s info "编译完成"
	if [ X$ltapedev = Xalarmapi ]
	then
		cp /tmp/alarmAPI.tar $INFORMIXDIR/
		cd $INFORMIXDIR
		ls alarmAPI.tar | xargs -n1 tar xf
		if [[ ! -d "$INFORMIXDIR/alarmAPI" ]]
		then
			log4s error "alarmAPI文件夹不存在，请确保解压后的galarmAPI文件夹在\$INFORMIXDIR中"
			exit 1
		fi
		log4s info "开始编译alarmAPI"
		cd $INFORMIXDIR/alarmAPI
		make -f makefile.$xtong
		if [ $? -eq 0 ]
		then
			log4s info "alarmAPI编译成功"
		else
			log4s error "alarmAPI编译失败"
		fi
	fi
	log4s info "修改内核参数"
	kernel_shmmaxnum=`grep "kernel.shmmax" /etc/sysctl.conf|wc -l`
	kernel_shmmninum=`grep "kernel.shmmni" /etc/sysctl.conf|wc -l`
	kernel_shmallnum=`grep "kernel.shmall" /etc/sysctl.conf|wc -l`
	kernel_semnum=`grep "kernel.sem" /etc/sysctl.conf|wc -l`
	if [ $kernel_shmmaxnum = 0 ]
	then
		echo "kernel.shmmax = 4398046511104" >> /etc/sysctl.conf
	else
		log4s error "已经存在kernel.shmmax 参数，请人工判断，informix需要值为 \"kernel.shmmax = 4398046511104\""
	fi
	if [ $kernel_shmmninum = 0 ]
	then
		echo "kernel.shmmni = 4096" >> /etc/sysctl.conf
	else
		log4s error "已经存在kernel.shmmni 参数，请人工判断，informix需要值为 \"kernel.shmmni = 4096\""
	fi
	if [ $kernel_shmallnum = 0 ]
	then
		echo "kernel.shmall = 67108864" >> /etc/sysctl.conf
	else
		log4s error "已经存在kernel.shmall 参数，请人工判断，informix需要值为 \"kernel.shmall = 67108864\""
	fi
	if [ $kernel_semnum = 0 ]
	then
		echo "kernel.sem = 250 32000 32 4096" >> /etc/sysctl.conf
	else
		log4s error "已经存在kernel.sem 参数，请人工判断，informix需要值为 \"kernel.sem = 250 32000 32 4096\""
	fi


	log4s info "检查内核参数写入是否正确"

	kernel_shmmaxok=`grep "kernel.shmmax = 4398046511104" /etc/sysctl.conf|wc -l`
	kernel_shmmniok=`grep "kernel.shmmni = 4096" /etc/sysctl.conf|wc -l`
	kernel_shmallok=`grep "kernel.shmall = 67108864" /etc/sysctl.conf|wc -l`
	kernel_semok=`grep "kernel.sem = 250 32000 32 4096" /etc/sysctl.conf|wc -l`
	if [ X$kernel_shmmaxok != X1 ] || [ X$kernel_shmmniok != X1 ] || [ X$kernel_shmallok != X1 ] || [ X$kernel_semok != X1 ]
	then
	log4s error "内核参数写入异常，请检查"
	fi
	log4s info "写入内核数据更新标识"
	echo "alreadyinstall informix" >> $alreadyornolog
	cp /tmp/$jiaobenming $idshome/

	if [ ! -d $idshome/dbfiles ]
	then
		log4s info "创建dbfiles目录"
		mkdir $idshome/dbfiles
		chown informix:informix $idshome/dbfiles
		chmod 775 $idshome/dbfiles
	fi
	
	chmod 777 $idshome/$jiaobenming
	chmod 777 $alreadyornolog


	log4s info "创建连接文件中"
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
	

	log4s info "增加5.9或者6.5的特定配置"
	log4s info "系统版本为$XTBANBEN"
	if [ $tXTBB -ge 5009 ] && [ $tXTBB -le 6005 ]
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
	elif [ $tXTBB -gt 6005 ] && [ $tXTBB -le 7005 ]
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
	else
		log4s error "tXTBB值为 $tXTBB ，无在5.9和7.5之间，所以将两种93rule都加进去尝试使用，如有异常请手动解决"
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
		chown  informix:informix       $lvrootdbs1 
		chown  informix:informix       $lvtempdbs1 
		chown  informix:informix       $lvtempdbs2 
		chown  informix:informix       $lvlogdbs1  
		chown  informix:informix       $lvphydbs1  
		chown  informix:informix       $lvuserdbs1 
		chown  informix:informix       $lvuserdbs2 
		chown  informix:informix       $lvuserdbs3 
		chown  informix:informix       $lvuserdbs4 
		chown  informix:informix       $lvuserdbs5 
		chown  informix:informix       $lvchargedbs1
		chown  informix:informix       $lvchargedbs2
		chown  informix:informix       $lvminfodbs1
		chown  informix:informix       $lvminfodbs2
		chown  informix:informix       $lvservdbs1 
		chown  informix:informix       $lvservdbs2 
		chmod  660       $lvrootdbs1 
		chmod  660       $lvtempdbs1 
		chmod  660       $lvtempdbs2 
		chmod  660       $lvlogdbs1  
		chmod  660       $lvphydbs1  
		chmod  660       $lvuserdbs1 
		chmod  660       $lvuserdbs2 
		chmod  660       $lvuserdbs3 
		chmod  660       $lvuserdbs4 
		chmod  660       $lvuserdbs5 
		chmod  660       $lvchargedbs1
		chmod  660       $lvchargedbs2
		chmod  660       $lvminfodbs1
		chmod  660       $lvminfodbs2
		chmod  660       $lvservdbs1 
		chmod  660       $lvservdbs2 
	fi
	
	log4s info "修改informix的环境变量配置文件"
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
	
	log4s info "写入.rhosts文件，如果有需要请自己修改.rhost文件，默认为+"
	echo '+' > /home/informix/.rhosts
	chown informix:informix /home/informix/.rhosts
	chmod 660 /home/informix/.rhosts
	
	log4s info "开始修改配置文件"
	cp $idshome/etc/onconfig.std $peizhi
	chmod 660 $peizhi
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
	if [ X$hdrflag = Xonly ]
	then
		ltapedev=alarmprogram
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
	tihuan "^SHMVIRTSIZE 32656" "SHMVIRTSIZE 1000000";
	tihuan "^SHMADD 8192" "SHMADD 80000";
	tihuan "^CKPTINTVL 300" "CKPTINTVL 3600";
	tihuan "^TAPEDEV /dev/tapedev" "TAPEDEV /dev/null";
	tihuan "^TAPEBLK 32" "TAPEBLK 128";
	tihuan "^DEF_TABLE_LOCKMODE.*" "DEF_TABLE_LOCKMODE row"
	if [ X$ltapedev = Xalarmprogram ]
	then
		tihuan "^ALARMPROGRAM.*" "ALARMPROGRAM $idshome/etc/alarmprogram.sh"
		tihuan "^LTAPEDEV.*" "LTAPEDEV /dev/null"
	elif [ X$ltapedev = Xalarmapi ]
	then
		tihuan "^ALARMPROGRAM.*" "ALARMPROGRAM $idshome/alarmAPI/log_full.sh"
		tihuan "^LTAPEDEV.*" "LTAPEDEV /dev/null"
		chmod +x $INFORMIXDIR/alarmAPI/log_full.sh
	else
		tihuan "^ALARMPROGRAM.*" "ALARMPROGRAM $idshome/etc/alarmprogram.sh"
		tihuan "^LTAPEDEV.*" "LTAPEDEV /dev/null"
	fi
	tihuan "^BAR_ACT_LOG \$INFORMIXDIR/tmp/bar_act.log" "BAR_ACT_LOG /home/informix/bar_act.log";
	tihuan "^OPTCOMPIND 2" "OPTCOMPIND 0";
	tihuan "^DRAUTO                  0" "DRAUTO                  2";
	tihuan "^DUMPDIR \$INFORMIXDIR/tmp" "DUMPDIR /home/informix/tmp";
	tihuan "^DUMPSHMEM 1" "DUMPSHMEM 0";
	tihuan "^CLEANERS.*" "CLEANERS 16";
	tihuan "^LOGBUFF.*"  "LOGBUFF 128"
	if [ $anquan = 1 ]
	then
		tihuan "^LISTEN_TIMEOUT.*" "LISTEN_TIMEOUT 10";
		#tihuanaao "^ADTMODE.*" "ADTMODE 7"
	fi

	tihuan "^BUFFERPOOL default.*" "BUFFERPOOL default,buffers=$BUFFPOOLMEM,lrus=64,lru_min_dirty=0,lru_max_dirty=0.05";
	tihuan "^BUFFERPOOL size.*" "";
	#新增两个stat监控，可以使用onstat -g wst和onstat -g qst进行监控
	tihuan "^QSTATS.*" "QSTATS 1"
	tihuan "^WSTATS.*" "WSTATS 1"

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
	chmod a+r $idshome/etc/sqlhosts
	if [ -f /etc/hosts.equiv ]
	then
		log4s info "更新/etc/hosts.equiv"
		eq1=`grep "$priINFORMIXSERVER" /etc/hosts.equiv|wc -l|awk '{print $1}'`
		log4s debug "eq1值为$eq1"
		if [ X$eq1 != X1 ]
		then
			echo $priINFORMIXSERVER >> /etc/hosts.equiv
		fi
		if [ X$hdrflag != Xonly ]
		then
			eq2=`grep "$secINFORMIXSERVER" /etc/hosts.equiv|wc -l|awk '{print $1}'`
			log4s debug "eq2值为$eq2"
			if [ X$eq2 != X1 ]
			then
				echo $secINFORMIXSERVER >> /etc/hosts.equiv
			fi
		fi
		eq3=`grep "$priDBSERVERALIASES" /etc/hosts.equiv|wc -l|awk '{print $1}'`
		log4s debug "eq3值为$eq3"
		if [ X$eq3 != X1 ]
		then
			echo $priDBSERVERALIASES >> /etc/hosts.equiv
		fi
		if [ X$hdrflag != Xonly ]
		then
			eq4=`grep "$secDBSERVERALIASES" /etc/hosts.equiv|wc -l|awk '{print $1}'`
			log4s debug "eq4值为$eq4"
			if [ X$eq4 != X1 ]
			then
				echo $secDBSERVERALIASES >> /etc/hosts.equiv
			fi
		fi
		eq5=`grep "+" /etc/hosts.equiv|wc -l|awk '{print $1}'`
		log4s debug "eq5值为$eq5"
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
	log4s info "更新hosts文件"
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
	log4s info "生效内核参数"
	sysctl -p;
	#备机自动启配置
	if [ X$hdrflag = Xsec ]
	then
		chmod 775 $idshome;
		log4s info "启动备机的rsh服务"
		tihuanbasic ".*disable.*" "        disable                 = no" /etc/xinetd.d/rsh
		echo "rsh" >> /etc/securetty
		/etc/rc.d/init.d/xinetd restart
		log4s info "备机安装完成，等待主机接收通知"
		beijijianting1
	fi
	#主机自启动配置
	if [ X$hdrflag = Xpri ] || [ X$hdrflag = Xonly ]
	then
		log4s info "主机开始初始化"
		chmod 775 $idshome 1>/dev/null 2>&1;
		chmod 777 $log4slog 1>/dev/null 2>&1
		echo "su - informix -c '. /home/informix/.bash_profile;sh /tmp/tempIFX12.sh chushihua'" >/tmp/temp.sh
		chmod 777 /tmp/temp.sh
		
		
		vgname=`echo $lvrootdbs1 |awk -F'/' '{print $3}'`



		chmod 777 /tmp/tempIFX12.sh
		chmod 777 /tmp/temp.sh
		sh /tmp/temp.sh
		
	fi
else
	log4s info "安装标识文件中存在安装标识，请清理安装目录$idshome后再重新运行脚本"
fi


}
###################搭建hdr区###############
client()
{
	querenanzhuangbao
	#安装客户端模式
	hdrflag=client
	if [ X$hdrflag = Xclient ]
	then
		while [[ $clientpeizhiqueren != [Yy] ]]
		do
			isserver=server
			read -p "请输入主机数据库对外提供服务的ip："				client_pri_serverip
			read -p "请输入主机数据库对外提供服务的端口："			client_pri_serverport
			read -p "请输入主机数据库对外提供服务的实例名："		client_pri_serverservername
			read -p "请输入备机数据库对外提供服务的ip："				client_sec_serverip
			read -p "请输入备机数据库对外提供服务的端口："			client_sec_serverport
			read -p "请输入备机数据库对外提供服务的实例名："		client_sec_serverservername
			read -p "请设置需要安装的客户端个数，一次最多5个："	clientcount

			if [ X$clientcount != X1 ] && [ X$clientcount != X2 ] && [ X$clientcount != X3 ] && [ X$clientcount != X4 ] && [ X$clientcount != X5 ]
			then
				echo "输入不为1-5，默认认为是1个客户端"
				clientcount=1
			fi
			if [ $clientcount -ge 1 ]
			then
				read -p "请输入客户端1的ip："							clientip1
				read -p "请输入客户端1的主机名："					clienthostname1
				read -p "请输入客户端1的ssh的端口号："		clientport1
				read -p "请输入客户端1的账户："						clientusername1
			fi
			if [ $clientcount -ge 2 ]
			then
				read -p "请输入客户端2的ip："							clientip2
				read -p "请输入客户端2的主机名："					clienthostname2
				read -p "请输入客户端2的ssh的端口号："		clientport2
				read -p "请输入客户端2的账户："						clientusername2
			fi
			if [ $clientcount -ge 3 ]
			then
				read -p "请输入客户端3的ip："							clientip3
				read -p "请输入客户端3的主机名："					clienthostname3
				read -p "请输入客户端3的ssh的端口号："		clientport3
				read -p "请输入客户端3的账户："						clientusername3
			fi
			if [ $clientcount -ge 4 ]
			then
				read -p "请输入客户端4的ip："							clientip4
				read -p "请输入客户端4的主机名："					clienthostname4
				read -p "请输入客户端4的ssh的端口号："		clientport4
				read -p "请输入客户端4的账户："						clientusername4
			fi
			if [ $clientcount -ge 5 ]
			then
				read -p "请输入客户端5的ip："							clientip5
				read -p "请输入客户端5的主机名："					clienthostname5
				read -p "请输入客户端5的ssh的端口号："		clientport5
				read -p "请输入客户端5的账户："						clientusername5
			fi
			echo "主机数据库对外提供服务的ip：        $client_pri_serverip"
			echo "主机数据库对外提供服务的端口：      $client_pri_serverport"
			echo "主机数据库对外提供服务的实例名：    $client_pri_serverservername"
			echo "备机数据库对外提供服务的ip：        $client_sec_serverip"
			echo "备机数据库对外提供服务的端口：      $client_sec_serverport"
			echo "备机数据库对外提供服务的实例名：    $client_sec_serverservername"
			echo "需要安装的客户端个数：              $clientcount"
			if [ $clientcount -ge 1 ]
			then
				echo "客户端1的ip为：                     $clientip1"
				echo "客户端1的主机名为：                 $clienthostname1"
				echo "客户端1的ssh端口号为：              $clientport1"
				echo "客户端1的账户为：                   $clientusername1"
			fi
			if [ $clientcount -ge 2 ]
			then
				echo "客户端2的ip为：                     $clientip2"
				echo "客户端2的主机名为：                 $clienthostname2"
				echo "客户端2的ssh端口号为：              $clientport2"
				echo "客户端2的账户为：                   $clientusername2"
			fi
			if [ $clientcount -ge 3 ]
			then
				echo "客户端3的ip为：                     $clientip3"
				echo "客户端3的主机名为：                 $clienthostname3"
				echo "客户端3的ssh端口号为：              $clientport3"
				echo "客户端3的账户为：                   $clientusername3"
			fi
			if [ $clientcount -ge 4 ]
			then
				echo "客户端4的ip为：                     $clientip4"
				echo "客户端3的主机名为：                 $clienthostname3"
				echo "客户端4的ssh端口号为：              $clientport4"
				echo "客户端4的账户为：                   $clientusername4"
			fi
			if [ $clientcount -ge 5 ]
			then
				echo "客户端5的ip为：                     $clientip5"
				echo "客户端5的主机名为：                 $clienthostname5"
				echo "客户端5的ssh端口号为：              $clientport5"
				echo "客户端5的账户为：                   $clientusername5"
			fi
			read -p "是否确认客户端配置[YyNn]：" clientpeizhiqueren
		done
		if [ $clientpeizhiqueren = y ] || [ $clientpeizhiqueren = Y ]
		then
			if [ X$isserver = Xserver ]
			then
				if [ $clientcount -ge 1 ]
				then
					log4s info "开始准备客户端1的安装脚本"
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
					log4s info "准备完成"
					log4s info "开始拷贝安装脚本到$clientip1"
					scp -oPort=$clientport1 -r /tmp/scptempdir/* root@$clientip1:/tmp/
					log4s info "开始远程执行安装脚本"
					ssh -oPort=$clientport1 root@$clientip1 "cd /tmp;nohup sh ./$jiaobenming client >/tmp/anzhuang.log 2>&1 &"
					#su - informix -c ". ./.bash_profile;echo 'grant dba to $clientusername1'|dbaccess sysmater"
					log4s info "需要针对哪个库进行授权，请dbaccess对应库中执行grant dba to 账户名"
					log4s info "待客户端主机的/tmp/anzhuang.log中提示安装完成即可使用"
				fi
				if [ $clientcount -ge 2 ]
				then
					log4s info "开始准备客户端2的安装脚本"
					echo "$clientip2     $clienthostname2" >> /etc/hosts
					echo "$clienthostname2" >> /etc/hosts.equiv
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
					xiugai "^clientip=XXXXXX"											"clientip=$clientip2"
					xiugai "^clientport=XXXXXX"										"clientport=$clientport2"
					xiugai "^clientusername=XXXXXX"								"clientusername=$clientusername2"
					cp /tmp/tempIFX12.sh /tmp/scptempdir/$jiaobenming
					log4s info "准备完成"
					log4s info "开始拷贝安装脚本到$clientip2"
					scp -oPort=$clientport2 -r /tmp/scptempdir/* root@$clientip2:/tmp/
					log4s info "开始远程执行安装脚本"
					ssh -oPort=$clientport2 root@$clientip2 "cd /tmp;nohup sh ./$jiaobenming client >/tmp/anzhuang.log 2>&1 &"
					#su - informix -c ". ./.bash_profile;echo 'grant dba to $clientusername2'|dbaccess sysmater"
					log4s info "需要针对哪个库进行授权，请dbaccess对应库中执行grant dba to 账户名"
					log4s info "待客户端主机的/tmp/anzhuang.log中提示安装完成即可使用"
				fi
				if [ $clientcount -ge 3 ]
				then
					log4s info "开始准备客户端3的安装脚本"
					echo "$clientip3     $clienthostname3" >> /etc/hosts
					echo "$clienthostname3" >> /etc/hosts.equiv
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
					xiugai "^clientip=XXXXXX"										"clientip=$clientip3"
					xiugai "^clientport=XXXXXX"									"clientport=$clientport3"
					xiugai "^clientusername=XXXXXX"							"clientusername=$clientusername3"
					cp /tmp/tempIFX12.sh /tmp/scptempdir/$jiaobenming
					log4s info "准备完成"
					log4s info "开始拷贝安装脚本到$clientip3"
					scp -oPort=$clientport3 -r /tmp/scptempdir/* root@$clientip3:/tmp/
					log4s info "开始远程执行安装脚本"
					ssh -oPort=$clientport3 root@$clientip3 "cd /tmp;nohup sh ./$jiaobenming client >/tmp/anzhuang.log 2>&1 &"
					#su - informix -c ". ./.bash_profile;echo 'grant dba to $clientusername3'|dbaccess sysmater"
					log4s info "需要针对哪个库进行授权，请dbaccess对应库中执行grant dba to 账户名"
					log4s info "待客户端主机的/tmp/anzhuang.log中提示安装完成即可使用"
				fi
				if [ $clientcount -ge 4 ]
				then
					log4s info "开始准备客户端4的安装脚本"
					echo "$clientip4     $clienthostname4" >> /etc/hosts
					echo "$clienthostname4" >> /etc/hosts.equiv
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
					xiugai "^clientip=XXXXXX"										"clientip=$clientip4"
					xiugai "^clientport=XXXXXX"									"clientport=$clientport4"
					xiugai "^clientusername=XXXXXX"							"clientusername=$clientusername4"
					cp /tmp/tempIFX12.sh /tmp/scptempdir/$jiaobenming
					log4s info "准备完成"
					log4s info "开始拷贝安装脚本到$clientip4"
					scp -oPort=$clientport4 -r /tmp/scptempdir/* root@$clientip4:/tmp/
					log4s info "开始远程执行安装脚本"
					ssh -oPort=$clientport4 root@$clientip4 "cd /tmp;nohup sh ./$jiaobenming client >/tmp/anzhuang.log 2>&1 &"
					#su - informix -c ". ./.bash_profile;echo 'grant dba to $clientusername4'|dbaccess sysmater"
					log4s info "需要针对哪个库进行授权，请dbaccess对应库中执行grant dba to 账户名"
					log4s info "待客户端主机的/tmp/anzhuang.log中提示安装完成即可使用"
				fi
				if [ $clientcount -ge 5 ]
				then
					log4s info "开始准备客户端1的安装脚本"
					echo "$clientip5     $clienthostname5" >> /etc/hosts
					echo "$clienthostname5" >> /etc/hosts.equiv
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
					xiugai "^clientip=XXXXXX"										"clientip=$clientip5"
					xiugai "^clientport=XXXXXX"									"clientport=$clientport5"
					xiugai "^clientusername=XXXXXX"							"clientusername=$clientusername5"
					cp /tmp/tempIFX12.sh /tmp/scptempdir/$jiaobenming
					log4s info "准备完成"
					log4s info "开始拷贝安装脚本到$clientip1"
					scp -oPort=$clientport5 -r /tmp/scptempdir/* root@$clientip5:/tmp/
					log4s info "开始远程执行安装脚本"
					ssh -oPort=$clientport5 root@$clientip5 "cd /tmp;nohup sh ./$jiaobenming client >/tmp/anzhuang.log 2>&1 &"
					#su - informix -c ". ./.bash_profile;echo 'grant dba to $clientusername5'|dbaccess sysmater"
					log4s info "需要针对哪个库进行授权，请dbaccess对应库中执行grant dba to 账户名"
					log4s info "待客户端主机的/tmp/anzhuang.log中提示安装完成即可使用"
				fi
				mv /tmp/scptempdir/$anzhuangbao /tmp/
				log4s info "客户端已经开始安装，请等待"
				exit 0;
			fi
			#X$isserver=Xserver的if结束
			if [ X$isserver=Xclient ]
			then
				CheckP;
				if [ ! -d $idshome ]
				then
					mkdir $idshome
					log4s info "创建安装目录"
					chown informix:informix $idshome
					chown 777 $idshome
				fi
				peizhi=$idshome/etc/$ONCONFIG
				wai=`whoami`
				if [ X$wai != Xroot ]
				then
				log4s error "请使用root账户进行安装"
				exit 1;
				fi
				if [ X$X86 != Xx86_64 ]
				then
					log4s error "系统为32位版本，暂时不支持"
					exit 1;
				fi
				if [ ! -f /tmp/$jiaobenming ]
				then
					log4s error "请将本脚本放在/tmp文件夹下"
					exit 1;
				fi
				if [ ! -f /tmp/$anzhuangbao ]
				then
					log4s error "请将$anzhuangbao放到/tmp下";
					exit 1;
				fi
				FILEsize=`stat -c %s /tmp/$anzhuangbao`
				if [ X$FILEsize != X$filesize ]
				then
					log4s error "文件大小不正确，请核对后再进行，大小应为${filesize}字节";
					exit 1;
				fi
				if [ $tXTBB -lt 5009 ] || [ $tXTBB -ge 7906 ]
				then
					log4s error "系统版本暂不支持，请联系脚本开发人员"
					exit 1;
				fi
				if [ ! -f $alreadyornolog ]
				then
					touch $alreadyornolog
					log4s info "创建数据库编译标识文件$alreadyornolog"
					initflag=0
				else
					log4s info "安装标识文件存在"
					initflag=`grep "alreadyinstall informix" $alreadyornolog|wc -l|awk '{print $1}'`
				fi
				if [ $initflag = 0 ]
				then
					#用户是否存在，如果不存在就建立
					log4s info "安装标识文件中不存在安装标识"
					userexistflag=`grep informix /etc/passwd|wc -l|awk '{print $1}'`
					if [ X$userexistflag != X1 ]
					then
						#linux安装步骤
						if [ X$XITONG = XLINUX ]
						then
							log4s info "建立用户组"
							groupadd informix;
							log4s info "建立用户"
							useradd -g informix -d $informixhome informix;
							chown informix:informix $idshome
							chmod 770 $idshome
							passwd informix <<EOF
EBupt!@#456
EBupt!@#456
EOF
							fi
							#AIX安装步骤
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
						#[ X$userexistflag != X1 ]的if结束
						chown informix:informix $idshome
						chmod 775 $idshome
						INFORMIXDIR=$idshome
						export INFORMIXDIR
						log4s info "移动安装包到安装目录"
						mv $anzhuangbao $idshome/
						cd $idshome;
						log4s info "解压安装包"
						tar -xvf  $idshome/$anzhuangbao -C $idshome/
						mv $idshome/$anzhuangbao /tmp
						log4s info "开始自动编译数据库"
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
						#写入informix账户环境变量
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
						
						log4s info "写入.rhosts文件，如果有需要请自己修改.rhost文件，默认为+"
						echo '+' > /home/informix/.rhosts
						chown informix:informix /home/informix/.rhosts
						chmod 660 /home/informix/.rhosts
						
						log4s info "写入sqlhosts文件"
						echo "$client_pri_serverservername     onsoctcp     $client_pri_serverip     $client_pri_serverport" >> $idshome/etc/sqlhosts
						echo "$client_sec_serverservername     onsoctcp     $client_sec_serverip     $client_sec_serverport" >> $idshome/etc/sqlhosts
						chown informix:informix $idshome/etc/sqlhosts
						chown informix:informix $idshome/etc/*
						chmod a+r $idshome/etc/sqlhosts
				fi
				#$initflag = 0的if结束
			fi
			#X$isserver=Xclient的if结束
			log4s info "客户端安装完成"
		fi
		#[ $clientpeizhiqueren = y ] || [ $clientpeizhiqueren = Y ]的if结束
		exit 0
	fi
	#X$hdrflag = Xclient的if结束
}

hdr()
{
	wai1=`whoami`
	hdfflag=pri
	if [ $wai1 != informix ]
	then
		echo "请用informix账户启动"
		exit 0;
	fi
	onmode -ky;
	oninit;
	log4s info "开始零备并恢复备库"
	ontape -t STDIO -s -L 0 -F|rsh $secip "cd /home/informix;. ./.bash_profile ; ontape -t STDIO -p";
	ontaperesult=`echo $?`
	if [ $ontaperesult = 0 ]
	then
		log4s info "零备恢复完成"
	else
		log4s error "零备恢复失败，请根据报错进行核查，修复问题后，使用命令如下进行零备恢复，之后重新设置主备状态"
		log4s error "ontape -t STDIO -s -L 0 -F|rsh $secip \"cd /home/informix;. ./.bash_profile ; ontape -t STDIO -p\";"
		exit 1;
	fi
	sleep 5;
	log4s info "开始设置主备库状态"
	onmode -d primary $secINFORMIXSERVER;
	rsh $secip "cd /home/informix;. ./.bash_profile ; onmode -d secondary $priINFORMIXSERVER";
	sleep 1;
	log4s info "HDR搭建完成，请观察主备机状态"
	while true
	do
	zhubeihdrokle=`echo "beijikaishihuifu"|nc $secip $tongxinduankou2`
		if [ X$zhubeihdrokle = Xbeijidengdaihuifu ]
		then
			log4s info "备机恢复rsh等设置"
			if [ X$ltapedev = Xalarmapi ]
			then
				log4s info "因为选择了使用alarmapi，请自己根据实际情况修改$idshome/alarmAPI下相关配置"
			fi
			break;
		fi
	sleep 1;
	done;

}
#########################初始化区##############
#使用的前提是已经修改好sqlhosts文件和/etc/hosts.*文件
chushihua()
{
	wai1=`whoami`
	if [ $wai1 != informix ]
	then
		echo "请用informix账户启动"
		exit 0;
	fi
	chmod 775 $idshome 1>/dev/null 2>&1;
	chmod 775 $idshome/dbfiles 1>/dev/null 2>&1;
	
	oninit -ivy;
	bulidsysmasterok=`grep "'sysmaster' database built successfully." /home/informix/online.log|wc -l|awk '{print $1}'`
	bulidsysadminok=`grep "'sysadmin' database built successfully." /home/informix/online.log|wc -l|awk '{print $1}'`
	bulidsysuserok=`grep "'sysuser' database built successfully." /home/informix/online.log|wc -l|awk '{print $1}'`
	bulidsysutilsok=`grep "'sysutils' database built successfully." /home/informix/online.log|wc -l|awk '{print $1}'`
	let buildoknum=bulidsysmasterok+bulidsysadminok+bulidsysuserok+bulidsysutilsok
	dengdainum=0
	while [ $buildoknum -lt 4 ]
	do
		log4s info "等待系统库创建完成"
		sleep 10;
		bulidsysmasterok=`grep "'sysmaster' database built successfully." /home/informix/online.log|wc -l|awk '{print $1}'`
		bulidsysadminok=`grep "'sysadmin' database built successfully." /home/informix/online.log|wc -l|awk '{print $1}'`
		bulidsysuserok=`grep "'sysuser' database built successfully." /home/informix/online.log|wc -l|awk '{print $1}'`
		bulidsysutilsok=`grep "'sysutils' database built successfully." /home/informix/online.log|wc -l|awk '{print $1}'`
		let buildoknum=bulidsysmasterok+bulidsysadminok+bulidsysuserok+bulidsysutilsok
		let dengdainum=dengdainum+1
		if [ $dengdainum -gt 10 ]
		then
			log4s info "等待时间过长，可能是由于数据库在虚拟机上安装有可能初始化异常，请观察online.log日志"
			log4s info "如果确定sysmaster，sysadmin，sysuser，sysutils，四个库初始化异常，或者有某个库没有初始化"
			read -p  "请输入[xiufu]" xiufuflag
			if [ X$xiufuflag = Xxiufu ]
			then
				sh /tmp/$jiaobenming xiufu
				dengdainum=0
			fi
		fi
	done
	chmod a+r $idshome/etc/sqlhosts
	log4s info "数据库初始化完成，开始增加dbs";
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
	ontape -s -L 0;
	if [ $testflag = 1 ]
	then
		onstat -l;
	fi
	onmode -l;
	onmode -c;
	onmode -l;
	onmode -c;
	onmode -l;
	onmode -c;
	onstat -l;
	if [ $testflag = 1 ]
	then
		onstat -l;
	fi
	log4s debug "开始删除逻辑日志"
	if [ $testflag = 1 ]
	then
		onstat -l;
	fi
	onparams -d -l 1 <<EOF
y
EOF
	if [ $testflag = 1 ]
	then
		log4s debug "删除逻辑日志1结束"
		onstat -l;
	fi
	onparams -d -l 2 <<EOF
y
EOF
	if [ $testflag = 1 ]
	then
		log4s debug "删除逻辑日志2结束"
		onstat -l;
	fi
	onparams -d -l 3 <<EOF
y
EOF
	if [ $testflag = 1 ]
	then
		log4s debug "删除逻辑日志3结束"
		onstat -l;
	fi
	let Msizelogdbs1=sizelogdbs1G*1000
	let numofllog=Msizelogdbs1/200
	let beginnumofllog=numofllog-2
	tempi=1
	pnumofllog=`Pnum "$Msizelogdbs1"`
	pbeginnumofllog=`Pnum "$beginnumofllog"`
	if [ $pnumofllog = ok ] && [ $pbeginnumofllog = ok ]
	then
		while [ $tempi -le $beginnumofllog ]
		do
			onparams -a -d logdbs -s 200000;
			let tempi=tempi+1
			ontape -s -L 0;
		done
		log4s debug "增加逻辑日志结束"

		onmode -l;
		onmode -c;
		onparams -d -l 4 <<EOF
y
EOF
		if [ $testflag = 1 ]
		then
			log4s debug "删除逻辑日志4结束"
			onstat -l;
		fi
		onparams -d -l 5 <<EOF
y
EOF
		if [ $testflag = 1 ]
		then
			log4s debug "删除逻辑日志5结束"
			onstat -l;
		fi
		onparams -d -l 6 <<EOF
y
EOF
		if [ $testflag = 1 ]
		then
			log4s debug "删除逻辑日志6结束"
			onstat -l;
		fi
	else
	for i in {1..36}
	do
		onparams -a -d logdbs -s 200000;
		let i+=1

	done
	onmode -l;
	onmode -c;
	onparams -d -l 3 <<EOF
y
EOF
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
	onmode -l;
	onmode -c;
	onmode -l;
	onmode -c;
	onmode -l;
	onmode -c;
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
	fi

	let physize=sizephydbs1*75/100
	onparams -p -s $physize -d phydbs -y;
	ontape -s -L 0;
	log4s info "主机安装完成：等待备机安装完成信号。"
	if [ X$hdrflag != Xonly ]
	then
		while true
		do
			beijiqidongflag=`echo "kaishihdr"|nc $secip $tongxinduankou1`
				if [ X$beijiqidongflag = Xsecbootok ]
				then
					log4s info "备机安装完成。开始搭建HDR"
					break;
				fi
			sleep 1;
		done;
		hdr
	fi
	if [ X$hdrflag = Xonly ]
	then
		onmode -m;
		log4s info "单机安装完成"
		killall nc;
		killall nc;
		exit 0;
	fi 
	
}

qinglilv()
{
	lvremove $1<<EOF
y
EOF
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
		shifouchuangjianpv=`grep "^shifouchuangjianpv=" tempIFX12.sh |awk -F'=' '{print $2}'`
		shifouchuangjianvg=`grep "^shifouchuangjianvg=" tempIFX12.sh |awk -F'=' '{print $2}'`
		shifouchuangjianlv=`grep "^shifouchuangjianlv=" tempIFX12.sh |awk -F'=' '{print $2}'`
		vgname=`grep "^vgname=" tempIFX12.sh |awk -F'=' '{print $2}'`
		devname=`grep "^devname=" tempIFX12.sh |awk -F'=' '{print $2}'`
		if [ X$shifouchuangjianlv = Xy ] && [ X$vgname != X ]
		then
			qinglilv /dev/$vgname/rootdbs1;
			qinglilv /dev/$vgname/tempdbs1;
			qinglilv /dev/$vgname/tempdbs2;
			qinglilv /dev/$vgname/logdbs1;
			qinglilv /dev/$vgname/phydbs1;
			qinglilv /dev/$vgname/userdbs1;
			qinglilv /dev/$vgname/userdbs2;
			qinglilv /dev/$vgname/userdbs3;
			qinglilv /dev/$vgname/userdbs4;
			qinglilv /dev/$vgname/userdbs5;
			qinglilv /dev/$vgname/chargedbs1;
			qinglilv /dev/$vgname/chargedbs2;
			qinglilv /dev/$vgname/minfodbs1;
			qinglilv /dev/$vgname/minfodbs2;
			qinglilv /dev/$vgname/servdbs1;
			qinglilv /dev/$vgname/servdbs2;
		fi
		if [ X$vgname != X ] && [ X$shifouchuangjianvg = Xy ]
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
		if [ X$devname != X ] && [ X$shifouchuangjianpv = Xy ]
		then
			pvremove $devname
		fi
		rm -rf /tmp/tempIFX12.sh
	else
		echo "需要用root账户"
	fi
}
xiufu()
{
	wai2=`whoami`
	if [ X$wai2 = Xinformix ]
	then
		log4s info "修改配置文件运行初始化"
		tempanzhuangwenjian=`grep "^priONCONFIG" /tmp/tempIFX12.sh |awk -F'=' '{print $2}'`
		peizhi=$idshome/etc/$tempanzhuangwenjian
		tihuan "^FULL_DISK_INIT.*" "FULL_DISK_INIT  1"
		log4s info "停止数据库"
		onmode -ky;
		log4s info "清空online.log"
		>/home/informix/online.log
		sleep 3;
		log4s info "重新初始化数据库"
		oninit -ivy 
	else
		log4s error "需要用informix账户"
		exit 1
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
if [ $# = 1 ] && [ $1 = xiufu ]
then
	xiufu
fi