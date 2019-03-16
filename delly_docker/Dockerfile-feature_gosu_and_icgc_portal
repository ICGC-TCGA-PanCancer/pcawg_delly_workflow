############################################################
# Dockerfile to build DELLY workflow container
# Based on Ubuntu
############################################################

# Set the base image to Ubuntu
FROM seqware/seqware_whitestar:1.1.1

# File Author / Maintainer
MAINTAINER Ivica Letunic <letunic@biobyte.de>

USER root
RUN apt-get -m update && apt-get install -y apt-utils tar git curl nano wget dialog net-tools build-essential time python python-dev python-distribute python-pip r-base r-base-dev tabix cython sudo \
    && pip install -i https://pypi.python.org/simple/ --upgrade pip && hash -r \
    && pip install pybedtools==0.7.7 numpy==1.11.0 docopt==0.6.2 PyVCF==0.6.8 wheel==0.29.0 pandas==0.18.1 pysam==0.9.0 \
    && wget https://github.com/samtools/samtools/releases/download/1.2/samtools-1.2.tar.bz2 -O - |tar -xj -C /tmp/ && cd /tmp/samtools-1.2 && make && make install
#RUN echo "source(\"http://bioconductor.org/biocLite.R\")" > /tmp/dnacopy; echo "biocLite()" >> /tmp/dnacopy; R CMD BATCH /tmp/dnacopy
COPY scripts/* /usr/bin/
RUN for i in cleanup.sh cov cov_plot.pl cov_v0.5.6_linux_x86_64bit cov_v0.5.6_parallel_linux_x86_64bit delly delly_pcawg_qc_json.py delly_pcawg_timing_json.py delly_pe_dump.sh delly_prepare_uploader.sh DellySomaticFreqFilter.py delly_v0.6.3_parallel_linux_x86_64bit delly_v0.6.6_parallel_linux_x86_64bit dellyVcf2Tsv.py vcfcombine vcf_index.sh vcf-sort; do chmod a+rx /usr/bin/$i; done;
RUN echo 'install.packages("/usr/bin/DNAcopy_1.38.1.tar.gz")' >> /tmp/dnacopy; R CMD BATCH /tmp/dnacopy

ENV GOSU_VERSION 1.10
RUN set -x \
    && apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
    && dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true \
    && chown root:users /usr/local/bin/gosu \
    && chmod +s /usr/local/bin/gosu
ADD scripts/start.sh /start.sh
RUN chmod a+rx /start.sh

# copy over the workflow src contents
COPY DELLY /home/seqware/DELLY
RUN chown -R seqware /home/seqware/DELLY
USER seqware
WORKDIR /home/seqware/DELLY/

# add godaddy cert bridge
# see http://drcs.ca/blog/adding-godaddy-intermediate-certificates-to-java-jdk/ and
# http://tozny.com/blog/godaddys-ssl-certs-dont-work-in-java-the-right-solution/ for more information on this
RUN wget https://certs.godaddy.com/repository/gdroot-g2_cross.crt && \
    keytool -import -alias cross -file gdroot-g2_cross.crt -trustcacerts -keystore /usr/lib/jvm/java-7-oracle-cloudera/jre/lib/security/cacerts  -storepass changeit

# build the workflow
RUN mvn -B clean install

# configure for no retries and memory for SeqWare whitestar
RUN sed -i 's|OOZIE_RETRY_MAX=.*|OOZIE_RETRY_MAX=0|' /home/seqware/.seqware/settings && \
    echo 'WHITESTAR_MEMORY_LIMIT=160000' >> /home/seqware/.seqware/settings

VOLUME /output /datastore /home/seqware

CMD ["/bin/bash"]
