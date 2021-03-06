# Hybrid space plasma simulator

## Attribution

This repository was forked from [pdelamere/Hybrid_3d_buf](https://github.com/pdelamere/Hybrid_3d_buf)

## Compiling

First build and install OpenMPI. We're using version 1.4. You might be able to ge more recent versions to work, but I've had problems with 1.8.

To build the hybrid code run `run.sh`
This will compile and move the binary and supporting files to a separate data folder.
Right now it works well with the Intel compiler.

## Usage

The most commonly used settings are in inputs.dat, dimensions.f, and inputs.f
Yes you will have to recompile if you change the dimensions of the simulation.

Right now that's about all there is to it. It simulates Pluto, if you want something else you have to dig into the codebase and edit it. There's currently no convenient way to change most simulation parameters. You need to understand and edit the code.

## Organization

Program starts in maind.f, but the bulk of the code is in gutsp.f.  
Gutsp.f is the guts of the program for the kinetic simulation.  
Gutsf.f is the guts of the program for the fluid simulation.  
Comments in maind.f explain many of the variable names.  

## Documentation

Documentation including variables, subroutines, and how to run the code as of December 10th 2020 are in the doc folder.

## Contact

View the [original repository](https://github.com/pdelamere/Hybrid_3d_buf) for contact info for the main code.  This fork was maintained by [Ann Marie Mahon](mailto:annmarie.mahon@lasp.colorado.edu)
