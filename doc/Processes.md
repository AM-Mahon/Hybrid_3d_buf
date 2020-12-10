# Processes

## Getting the code

The easiest way to stay up to date with the code is to use Git.  There are many tutorials online as Git is surprisingly complicated.  The cheatsheet I use the most for Git commands is [here](https://education.github.com/git-cheat-sheet-education.pdf).  The original code from Peter is [here](https://github.com/pdelamere/Hybrid_3d_buf), and the code updated by Ann Marie is [here](https://github.com/AM-Mahon/Hybrid_3d_buf).  The most basic command you need is git pull.  For the AM branch the full syntax is `git pull https://github.com/AM-Mahon/Hybrid_3d_buf.git`.  If you are unable to use git for any reason you can also download a zip of the code using the green code button.

## Updating the code

If you have a Github account and permission to post in the repository (or have created your own) you can use git to update the code as well.  If for example I edited inputs.dat I would go through the following steps:  

- Add the file  
`git add inputs.dat`
- Commit the change (with a comment)  
`git commit -m "comment here"`
- Push (upload) the changes to Github  
`git push`

At this point I would be prompted to enter my Github login credentials if they are not saved.  You will also need to set your name and email during initial setup with `git config user.name [name]` and `git config user.email [email]`.  Other configurations may be needed, especially if you are using branches.  View tutorials for full info.

## Getting the code on to Summit

If the code on Github is up to date, Summit can use git pull as described above.  If you can't, then you can use Globus to get files on to Summit.  More details below.

## Getting files off of Summit

FTP is possible I think but I've never used it.  What I use is [Globus](https://www.globus.org/).  First install [Globus Connect Personal](https://www.globus.org/globus-connect-personal), then sign in.  On the Globus website you can sign in using your Identikey login, and then in the file manager sign in to the CURC collection using Identikey and Duo 2fa.

IMPORTANT NOTE: Files in the /scratch/summit directory will expire after a period of time.  Make sure you download them all or move them to the project/home directory so you don't lose them.  Details about the CURC filesystem are [here](https://curc.readthedocs.io/en/latest/compute/filesystems.html).

## Running the code

Most jobs are submitted using scripts.  Summit_run is one, and is modified each run for timesteps and run duration.  It would also need to be modified to save in the correct directory and email the right user.  inputs.dat is also an important file to modify each run, as it contains several simulation parameters.  CURC has full documentation on scripts [here](https://curc.readthedocs.io/en/latest/running-jobs/batch-jobs.html).

## Graphing results

IDL code to graph results are stored in this [repository](https://github.com/AM-Mahon/IDL-Plotting-Europa).  It only shows values from one slice, no stitching is done.  Make sure to update all the appropriate variables when compiling so the code pulls data from the correct files and saves the graphs in the correct location.
