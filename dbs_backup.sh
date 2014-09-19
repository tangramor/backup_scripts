#!/bin/bash
# This script backup mysql and mongodb databases to /root/backup/db_dump

#---------------------------- Configurations Start ----------------------------
# 备份目标目录
target=/root/backup/db_dump

today=`date | date +%d -d -`

#========== Configuration for MySQL ==========
# MySql需要被dump的数据库
mydbs=(test1 test2 test3)

# MySql数据库用户/密码
myuser=backup
mypass=password

# 这里给MySql备份文件起一个名字: MyBackup_##，##是指当天为该月的第几天
mybackup="MyBackup_"$today

#========== Configuration for MongoDB ==========
# MongoDB数据库用户/密码
mouser=backup
mopass=password

# 这里给MongoDB备份文件起一个名字: MongoBackup_##，##是指当天为该月的第几天
mongobackup="MongoBackup_"$today

#========== Configuration for PostgreSQL ==========
# PostgreSql需要被dump的数据库
pgdbs=(wiki)

# 这里给备份文件起一个名字: PgBackup_##, ##是指当天为该月的第几天
pgbackup="PgBackup_"$today


#---------------------------- Configurations End ----------------------------



# 看看存放备份文件的文件夹是否存在，第一次的话就自动创建一个
if !(test -d $target)
then
	mkdir -p $target
fi
	
# 把mysql 数据库导出、打包并压缩
if (test -d /etc/mysql)
then
	# 看看上个月的今天是否备份了，有的话就删掉它（这里只备份最近一个月的）
	if test -e $target"/"$mybackup".tar.bz2"
	then
		rm -f $target"/"$mybackup".tar.bz2"
	fi

	# 把mysql 数据库导出、打包并压缩
	my_dump_path=/tmp/mysqldump
	if !(test -d $my_dump_path)
	then
		mkdir -p $my_dump_path
	fi

	for db in ${mydbs[*]}
	do
		mysqldump -u$myuser -p$mypass -hlocalhost $db --add-drop-table --add-locks --default-character-set=utf8 -K -e -l --hex-blob=true > $my_dump_path/$db.sql
	done

	cd $my_dump_path

	tar -cpf $target"/"$mybackup".tar" ./*
	bzip2 $target"/"$mybackup".tar"

	cd /tmp
	rm -rf $my_dump_path
fi

# 把mongodb 数据库导出、打包并压缩
if (test -e /etc/mongodb.conf)
then
	# 看看上个月的今天是否备份了，有的话就删掉它（这里只备份最近一个月的）
	if test -e $target"/"$mongobackup".tar.bz2"
	then
		rm -f $target"/"$mongobackup".tar.bz2"
	fi

	# 把 mongodb 数据库导出、打包并压缩
	mongo_dump_path=/tmp/mongodump
	mongo_db_path=`grep 'dbpath' /etc/mongodb.conf | awk -F "=" '{print $2}'`
	if !(test -d $mongo_dump_path)
	then
		mkdir -p $mongo_dump_path
	fi

	mongodump --authenticationDatabase admin --username $mouser --password $mopass --out $mongo_dump_path

	cd $mongo_dump_path
	tar -cpf $target"/"$mongobackup".tar" ./*
	bzip2 $target"/"$mongobackup".tar"

	cd /tmp
	rm -rf $mongo_dump_path
fi


# 把postgresql 数据库导出、打包并压缩
if (test -d /etc/postgresql)
then
	# 看看上个月的今天是否备份了，有的话就删掉它（这里只备份最近一个月的）
	if test -e $target"/"$pgbackup".tar.bz2"
	then
		rm -f $target"/"$pgbackup".tar.bz2"
	fi

	# 把 PostgreSql 数据库导出、打包并压缩
	pg_dump_path=/tmp/postgresqldump
	if !(test -d $pg_dump_path)
	then
		mkdir -p $pg_dump_path
	fi

	chown -R postgres $pg_dump_path

	for db in ${pgdbs[*]}
	do
		su -l postgres -c "pg_dump -b -C $db > $pg_dump_path/$db.sql"
	done

	cd $pg_dump_path
	tar -cpf $target"/"$pgbackup".tar" ./*
	bzip2 $target"/"$pgbackup".tar"

	cd /tmp
	rm -rf $pg_dump_path
fi
