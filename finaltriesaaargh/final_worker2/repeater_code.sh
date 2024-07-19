#!/bin/bash

#### SLURM settings ####
#SBATCH -J mysimplejob           # Job name
#SBATCH -o ./slurm_output/mysimplejob.%j.out    # Specify stdout output file (%j expands to jobId)
#SBATCH -p parallel              # Queue name
#SBATCH -N 1                     # Total number of nodes requested (20 cores/node on a standard Broadwell-node)
#SBATCH -n 1                     # Total number of tasks
#SBATCH --array=1-153
#SBATCH -t 20:00:00              # Run time (hh:mm:ss) - 0.5 hours
#SBATCH --mem 500M
#SBATCH -A m2_jgu-tee            # Specify allocation to charge against

parSet=$SLURM_ARRAY_TASK_ID

# directory and move into it
repeat = (1016 1029 105 1053 1062 1065 1068 107 1070 1071 1074 1077 1079 108 1080 1152 1188 1197 1206 1215 1224 1227 1230 1232 1233 1236 1239 1241 1242 1296 1314 1350 1359 1365 1368 1377 1386 1389 1392 1395 1398 1401 1403 1404 1512 1518 1521 1527 1530 1539 1542 1545 1548 1551 1554 1557 1560 1563 1565 1566 1608 1611 1616 1617 1619 162 1620 225 234 240 243 252 258 260 261 264 267 269 270 318 320 323 384 395 396 411 414 42 420 422 423 426 429 431 432 481 513 53 549 555 558 567 576 582 584 585 588 591 593 594 63 638 648 701 707 71 711 717 72 729 738 744 746 747 750 753 755 756 801 803 804 809 858 87 872 879 882 885 888 891 90 900 906 908 909 912 915 917 918 93 96 98 99) 
spec_repeat = ${repeat[${parset}]}

cd ./output/${spec_repeat}

# Ensure the binary has execution permissions again (in the new directory)
chmod +x myprog

# Run the binary with config.ini
./myprog config.ini