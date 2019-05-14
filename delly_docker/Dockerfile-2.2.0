FROM quay.io/pancancer/pcawg_delly_workflow:feature_gosu_and_icgc_portal

USER root

RUN apt-get update && apt-get install -y \
    cpanminus \
    && rm -rf /var/lib/apt/lists/*

RUN cpanm --no-lwp Capture::Tiny

COPY scripts/run_seqware_workflow.pl /usr/bin/

COPY scripts/start.sh /start.sh
RUN chmod a+rx /start.sh

USER seqware

