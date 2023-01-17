#!/bin/sh

export JAVA_HOME=/usr/local/hero/jdk1.8.0_261
export JRE_HOME=${JAVA_HOME}/jre
export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib
export PATH=${JAVA_HOME}/bin:$PATH

# ------------------------------ init ----------------------------------------
export SERVER="hero_web"
export JAVA_HOME
export JAVA="$JAVA_HOME/bin/java"
# 获取当前目录
export BASE_DIR=`cd $(dirname $0)/.; pwd`
# 默认加载路径
export DEFAULT_SEARCH_LOCATIONS="classpath:/,classpath:/config/,file:./,file:./config/"
# 自定义默认加载配置文件路径
export CUSTOM_SEARCH_LOCATIONS=${DEFAULT_SEARCH_LOCATIONS},file:${BASE_DIR}/conf/



# ------------------------------ JVM -----------------------------------------
# JAVA_OPT="${JAVA_OPT} -server -Xms512m -Xmx512m -Xmn256 -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=320m"
# JVM configuration
# 吞吐量优先
JAVA_OPT="${JAVA_OPT} -Xms256m -Xmx256m -Xmn125m -XX:MetaspaceSize=128m -Xss512k"
JAVA_OPT="${JAVA_OPT} -XX:+UseParallelGC -XX:+UseParallelOldGC "
JAVA_OPT="${JAVA_OPT} -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintGCDateStamps -XX:+PrintHeapAtGC -Xloggc:${BASE_DIR}/logs/gc-ps-po.log"

# 响应时间优先策略 
# JAVA_OPT="${JAVA_OPT} -Xms256m -Xmx256m -Xmn125m -XX:MetaspaceSize=128m -Xss512k"
# JAVA_OPT="${JAVA_OPT} -XX:+UseParNewGC -XX:+UseConcMarkSweepGC"
# JAVA_OPT="${JAVA_OPT} -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintGCDateStamps -XX:+PrintHeapAtGC -Xloggc:${BASE_DIR}/logs/gc-parnew-cms.log"

# 全功能垃圾收集器 
# JAVA_OPT="${JAVA_OPT} -Xms256m -Xmx256m -XX:MetaspaceSize=128m -Xss512k"
# JAVA_OPT="${JAVA_OPT} -XX:+UseG1GC -XX:MaxGCPauseMillis=100"
# JAVA_OPT="${JAVA_OPT} -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintGCDateStamps -XX:+PrintHeapAtGC -Xloggc:${BASE_DIR}/logs/gc-g-one.log"


JAVA_OPT="${JAVA_OPT} -XX:-OmitStackTraceInFastThrow -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=${BASE_DIR}/logs/java_heapdump.hprof"
JAVA_OPT="${JAVA_OPT} -XX:-UseLargePages"
JAVA_OPT="${JAVA_OPT} -jar ${BASE_DIR}/${SERVER}-*.jar"
JAVA_OPT="${JAVA_OPT} ${JAVA_OPT_EXT}"
JAVA_OPT="${JAVA_OPT} --spring.config.location=${CUSTOM_SEARCH_LOCATIONS}"
# 创建日志文件目录
if [ ! -d "${BASE_DIR}/logs" ]; then
    mkdir ${BASE_DIR}/logs
fi

# 输出变量
echo "$JAVA ${JAVA_OPT}"
# 检查start.out日志输出文件
if [ ! -f "${BASE_DIR}/logs/${SERVER}.out" ]; then
    touch "${BASE_DIR}/logs/${SERVER}.out"
fi

# ------------------------------ start ----------------------------------------
# 启动服务
echo "$JAVA ${JAVA_OPT}" > ${BASE_DIR}/logs/${SERVER}.out 2>&1 &
nohup $JAVA ${JAVA_OPT} hero_web.hero_web >> ${BASE_DIR}/logs/${SERVER}.out 2>&1 &
echo "server is starting，you can check the ${BASE_DIR}/logs/${SERVER}.out"
