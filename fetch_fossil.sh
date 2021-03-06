#!/bin/bash

base="$PWD"
set -e

echo "Checking that fossil is available..."
which fossil

if [ ! -e fossil.fossil ] ; then
    echo "Fetching fossil sources..."
    fossil clone http://www.fossil-scm.org fossil.fossil
fi

if [ ! -e fossil ] ; then
    echo "Checking out fossil sources..."
    mkdir -p fossil
    cd fossil
    fossil open ../fossil.fossil
    ./configure
fi

echo "Ok, we have fossil sources, configured. Time to play!"
