#!/bin/sh


#==================================================================
# Defaults
#==================================================================

SCRIPT_NAME="Cam Control Script"
VERSION="0.0.2"

CAM_SITE=/home/citrus/domains/cam.citrusme.com/current
CAM_IMAGE_DIR=$CAM_SITE/images
CAM_IMAGE_BACKUP=$CAM_SITE/backups



#==================================================================
# Utility Functions
#==================================================================

get_pid() {
  pid=0
  if [ -e /var/run/motion.pid ]; then 
    pid=`cat /var/run/motion.pid`
  fi
  echo $pid
}

get_status(){
  status="stopped"
  if [ `get_pid` -gt 0 ]; then 
    status="running"
  fi
  echo "$status"
}

get_start() {
  if [ -e $CAM_SITE/log/cam.start ]; then
    echo `cat $CAM_SITE/log/cam.start`
  else
    echo 'not running'
  fi
}

get_images() {
  echo `sudo ls $CAM_IMAGE_DIR -1`
}

get_count() {
  count=`sudo ls $CAM_IMAGE_DIR -1 | wc -l`
  if [ $count -gt 0 ]; then
    count=`expr $count - 1`
  fi
  echo $count
}




#==================================================================
# Tasks
#==================================================================

help() {

  cat <<HELP
------------------------------------
$SCRIPT_NAME
------------------------------------

TASKS
  [start]     starts camera
  [stop]      stops camera
  [stats, -s] shows camera stats
  [restart]   restarts camera
  [backup]    backs up camera images
  [flush]     flushes image directory
  [-h]        help
  [-v]        version
  
USAGE:
  backsup [task]
  
VERSION:
  $SCRIPT_NAME $VERSION

HELP

  exit 0
  
}

stats() {
  cat <<STATS
  
Camera Statistics
------------------------------------
 Status:           `get_status`
 Process ID:       `get_pid`
 Total Images:     `get_count`
 Recording since:  `get_start`
  
STATS
  exit 0
}

start() {
  if [ `get_pid` -eq 0 ]; then
    echo "Starting Camera.."
    sudo motion
    if [ `get_pid` -gt 0 ]; then
      echo $(date +"%m/%d/%Y @ %H:%M:%S") > $CAM_SITE/log/cam.start
      echo "Camera started.."
    else
      echo "Camera failed to start."
    fi
  else
    echo "Camera already running"
  fi 
}

stop() {
  if [ `get_pid` -gt 0 ]; then
    echo "Stopping Camera, PID `get_pid`.."
    sudo kill `get_pid`
    sleep 2
    if [ `get_pid` -eq 0 ]; then
      echo "Camera stopped."
    else
      echo "Camera failed to stop."
    fi
  else
    echo "No PID file found. Camera must not be running."
  fi
}

restart() {
  stop
  sleep 1
  start
}

backup() {
  NOW=$(date +"%m-%d-%Y_%H-%M-%S")
  FILE="images.$NOW.tar.gz"
  
  if [ ! -d $CAM_IMAGE_BACKUP ]; then
    mkdir $CAM_IMAGE_BACKUP
  fi
  
  echo "Creatin Backup $FILE"
  cd $CAM_IMAGE_DIR
  tar czvf $CAM_IMAGE_BACKUP/$FILE `get_images`
  echo "$FILE created.."
  
}

flush() {
  echo "Deleting `get_count` images.."
  if [ -d $CAM_IMAGE_DIR ];then 
    sudo rm $CAM_IMAGE_DIR/*
  fi
}




#==================================================================
# Main Loop
#==================================================================

if [ -z "$1" ]; then
  echo "Please include an argument. Use -h for help"  
  exit 0  
fi

while [ -n "$1" ]; do
  case $1 in
    stats|start|stop|restart|flush|backup)
      $1
      shift 1
      break
      ;;
    -s)
      stats
      shift 1
      break
      ;;
    -h)
      help
      shift 1
      break
      ;;
    -v)
      echo "$SCRIPT_NAME v$VERSION"
      shift 1
      exit 0
      break
      ;;
    *)
      echo "Error: no such option '$1'. Use -h for help";
      shift 1
      break
      ;;
  esac
done

exit 0

