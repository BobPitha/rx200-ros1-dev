# kuka-dev

## General
A development environment for the Kuka project at Medacuity, based on 
Bobs-dev-container, a Docker-based development environment I've found useful

This is a basic environment I've used for a few projects. It incorporates ideas and approaches from various past colleagues, most notably Shawn Shaffert, previously at GreyOrange. 

The idea here is that a base image is built that is used as the base image for a development container, and potentially a production container as well. FOr the development container, interactive Linux tools, useful stuff, and IDE support is installed, with the intent being an environment that can support development. 

To include a project, create a folder named workspace and make a symlink in there to your project(s) (which typically are in their own repos).

Most interaction is via make. The most important commands:
* make dev - makes the development container.
* make prod - makes the production container, if it were set up (which it currently isn't)
* make shell - open a shell into the development container, starting it if necessary.
* make stop - stops the running development container
I know, make is a weird way to do this. I keep meaning to tie it up under a shell script so it seems less weird, but I haven't done that yet.

Dockerfile-dev currently contains various commentable sections near the end to download and install VS Code, IntelliJ IDEA, and vim. Others are possible too; I had eclipse in there at one point, and emacs. It would be good to move this out into some better way of choosing what tools to activate at some point, rather than editing the Dockerfile and risking that getting committed accidentally. 

If you create a file named .bashrc_dev, it will be appended to the .bashrc in the container, allowing for customizations.

Dependencies: you need Docker (obviously), make, probably other things.
This is obviously a work in progress

## Kuka stuff
You should add the following before building the docker:
* create a directory named rti/, and put in it:
  * your RTI Linux host .run file (rti_connext_dds-6.1.2-pro-host-x64Linux.run)
  * A Linux target package (rti_connext_dds-6.1.2-pro-target-x64Linux4gcc7.3.0.rtipkg)
  * Your RTI license file (rti_license.dat)
  * The backup of Elizabeth's antique version of the RTI python lib (connextdds-py.zip)

Clone the Kuka repo (helpufully and not at all vaguely named "source") from https://bitbucket.org/medacuityrobotics/source/src/main/

Create a directory named workspace/, and make a symbolic link in it to the 'source' repo. Inside this repo, create a directory named common-idl (don't check this into the source repo by accident!) and copy the three xml files from source/src/idl to source/src/common-idl. 

Now you should be able to go to source/src/dds-emulator/test/pyGui, and type:

    python3 dds_emulator.py
