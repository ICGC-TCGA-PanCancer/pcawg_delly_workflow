############################################################
# Dockerfile to build DELLY workflow container
# Based on Ubuntu
############################################################

# Set the base image to Ubuntu
FROM seqware/seqware_whitestar:1.1.1

# File Author / Maintainer
MAINTAINER Ivica Letunic <letunic@biobyte.de>

USER root
RUN apt-get -m update

RUN apt-get install -y apt-utils tar git curl nano wget dialog net-tools build-essential time
RUN apt-get install -y python python-dev python-distribute python-pip 
RUN apt-get install -y r-base r-base-dev
RUN apt-get install -y tabix cython
RUN pip install pybedtools numpy docopt PyVCF
RUN wget https://github.com/samtools/samtools/releases/download/1.2/samtools-1.2.tar.bz2 -O - |tar -xj -C /tmp/; cd /tmp/samtools-1.2; make; make install
#RUN echo "source(\"http://bioconductor.org/biocLite.R\")" > /tmp/dnacopy; echo "biocLite()" >> /tmp/dnacopy; R CMD BATCH /tmp/dnacopy
COPY scripts/* /usr/bin/
RUN echo 'install.packages("/usr/bin/DNAcopy_1.38.1.tar.gz")' >> /tmp/dnacopy; R CMD BATCH /tmp/dnacopy
COPY DELLY /home/seqware/DELLY
RUN chown -R seqware /home/seqware/DELLY
USER seqware
WORKDIR /home/seqware/DELLY/
RUN mvn clean install
CMD ["/bin/bash", "/start.sh"]
