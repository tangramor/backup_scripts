#! /bin/bash
ROOT_PATH=/var/www/
FOLDERS=(site1/public/uploads site1/public/imported site1/config site2/public)
# 备份目标目录
TARGET=/root/backup/site_dump/
# 日志文件
LOG=$TARGET"site_data_backup.log"

TODAY=`date | date +%d -d -`

# 看看存放备份文件的文件夹是否存在，第一次的话就自动创建一个
if !(test -d $TARGET)
then
  mkdir -p $TARGET
fi

# 日志大于1M就备份清空
if [ $(stat -c %s $LOG) -gt 1048576 ]
then
  # 看看上个月的今天是否备份了，有的话就删掉它（这里只备份最近一个月的）
  if test -e $LOG"."$TODAY".tar.bz2"
  then
    rm -f $LOG"."$TODAY".tar.bz2"
  fi

  tar -czpf $LOG"."$TODAY".tar" $LOG
  bzip2 $LOG"."$TODAY".tar"
  echo '' > $LOG
fi

i=0
while [ $i -lt ${#FOLDERS[@]} ]
do
  FOLDER=${FOLDERS[$i]}
  echo ''>>$LOG
  echo `date "+[%F %H:%M:%S]"`"Start to backup "$ROOT_PATH$FOLDER": --------->">>$LOG

  SPACE=`echo $FOLDER | awk -F "/" '{print $1}'`
  if !(test -d $TARGET$SPACE)
  then
    mkdir -p $TARGET$SPACE
  fi

  # 计算‘/’的数量
  NUM_SLASH=`echo $FOLDER | sed -e 's/[^\/]//g' | wc -c`
  # 文件名
  NAME=`echo $FOLDER | awk -F "/" '{print $'$NUM_SLASH'}'`

  rsync -avzrtopg --progress --delete $ROOT_PATH${FOLDERS[$i]} $TARGET$SPACE 1>>$LOG 2>>$LOG

  cd $TARGET$SPACE

  # 看看上个月的今天是否备份了，有的话就删掉它（这里只备份最近一个月的）
  if test -e $NAME"_"$TODAY".tar.bz2"
  then
    rm -f $NAME"_"$TODAY".tar.bz2"
  fi

  # 打包压缩
  tar -cpf $NAME"_"$TODAY".tar" $NAME
  bzip2 $NAME"_"$TODAY".tar"

  echo "<---------Backup file "$NAME"_"$TODAY".tar.bz2 successfully created">>$LOG

  let i++
done

