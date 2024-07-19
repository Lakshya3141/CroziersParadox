#!/bin/bash

#### SLURM settings ####
#SBATCH -J mysimplejob           # Job name
#SBATCH -o ./slurm_output/mysimplejob.%A_%a.out    # Specify stdout output file (%j expands to jobId)
#SBATCH -p parallel              # Queue name
#SBATCH -N 1                     # Total number of nodes requested (20 cores/node on a standard Broadwell-node)
#SBATCH -n 1                     # Total number of tasks
#SBATCH --array=1-152
#SBATCH -t 20:00:00              # Run time (hh:mm:ss) - 0.5 hours
#SBATCH --mem 500M
#SBATCH -A m2_jgu-tee            # Specify allocation to charge against

module load compiler/GCC/11.2.0
parSet=$SLURM_ARRAY_TASK_ID

# directory and move into it
repeat = (1014 102 1041 1044 105 1053 1059 1068 107 1070 1071 1074 1077 1079 108 1080 1089 1119 1126 1197 1206 1224 1230 1233 1236 1239 1241 1242 1281 1289 1353 1368 1377 1386 1389 1392 1395 1398 1401 1403 1404 1442 1457 1458 150 1511 1512 1521 1527 1530 1533 1538 1548 1551 1554 1557 1560 1563 1565 1566 159 1617 204 222 224 225 234 252 255 258 260 261 264 267 269 270 276 312 318 321 324 396 405 417 420 422 423 426 429 431 432 474 484 540 558 567 57 576 579 582 584 585 588 591 593 594 63 636 643 647 68 690 711 717 72 720 726 729 735 741 744 746 747 750 753 756 78 807 810 870 873 879 882 89 891 90 900 903 905 906 909 912 915 917 918 924 93 96 965 969 98 99)

# Convert 1-based SLURM_ARRAY_TASK_ID to 0-based index for the array
spec_repeat=${repeat[$((parSet - 1))]}

# Move into the specified directory
cd ./output/${spec_repeat} || { echo "Directory not found: ./output/${spec_repeat}"; exit 1; }

# Ensure the binary has execution permissions again (in the new directory)
chmod +x myprog

# Run the binary with config.ini
./myprog config.ini