#!/bin/sh

echo "Content-Type:text/plain"
echo

#source $HOME/.bashrc

/usr/bin/R CMD BATCH --vanilla --slave /users/webhome/artes/PlotDiscusUnix.r

