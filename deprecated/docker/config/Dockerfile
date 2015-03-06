############################################################
# Dockerfile to build DELLY workflow container
# Based on Ubuntu
############################################################

# Set the base image to Ubuntu
FROM ubuntu

# File Author / Maintainer
MAINTAINER Ivica Letunic

RUN apt-get -m update

RUN apt-get install -y tar git curl nano wget dialog net-tools build-essential
RUN apt-get install -y python python-dev python-distribute python-pip
RUN apt-get install -y r-base r-base-dev
RUN apt-get install -y tabix
RUN apt-get install -y libdata-uuid-perl libjson-perl libxml-xpath-perl libxml-dom-perl libxml-libxml-perl
RUN pip install cython
RUN pip install pybedtools
RUN pip install numpy
RUN pip install docopt
RUN pip install PyVCF
RUN pip install samtools
RUN echo "source(\"http://bioconductor.org/biocLite.R\")" > /tmp/dnacopy; echo "biocLite()" >> /tmp/dnacopy; R CMD BATCH /tmp/dnacopy
#RUN echo "biocLite()" >> /tmp/dnacopy
#RUN R CMD BATCH /tmp/dnacopy
RUN curl  http://smart.embl.de/delly_bin.tar |tar xv -C /usr/bin/
RUN mkdir /work
