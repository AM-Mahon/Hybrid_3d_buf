#!/bin/bash

#SBATCH --nodes=1
#SBATCH --time=00:45:00
#SBATCH --qos=normal
#SBATCH --partition=shas
#SBATCH --ntasks=15
#SBATCH --job-name=Simulation-ompi
#SBATCH --output=simulation-ompi.%j.out
#SBATCH --mail-user=annmarie.mahon@lasp.colorado.edu
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL

module purge
module load intel/16.0.3
module load openmpi/1.10.2


./run.sh -d /scratch/summit/jama3001/am/data -i $SLURM_NTASKS
