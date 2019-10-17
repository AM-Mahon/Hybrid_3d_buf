#!/bin/bash

#SBATCH --nodes=1
#SBATCH --time=01:00:00
#SBATCH --qos=normal
#SBATCH --partition=shas
#SBATCH --ntasks=15
#SBATCH --job-name=Simulation
#SBATCH --output=simulation.%j.out
#SBATCH --mail-user=annmarie.mahon@lasp.colorado.edu
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL

module purge
module load intel/17.4
module load impi/17.3

./run.sh -d /scratch/summit/jama3001/pd/data -i $SLURM_NTASKS
