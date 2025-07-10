FROM quay.io/nf-core/ubuntu:22.04

RUN apt-get update && apt-get install -y curl wget unzip autoconf libinline-perl git python3 python3-pip python3-biopython libwww-perl
RUN mkdir /opt/vadr
COPY vadr-install.sh /opt/vadr/vadr-install.sh
WORKDIR /opt/vadr
RUN sh vadr-install.sh linux

RUN wget https://ftp.ncbi.nlm.nih.gov/asn1-converters/by_program/table2asn/linux64.table2asn.gz
RUN gunzip linux64.table2asn.gz
RUN mv linux64.table2asn /usr/bin/table2asn
RUN chmod 755 /usr/bin/table2asn
RUN mkdir /opt/sequtils
COPY fasta_rna_to_dna_strict.py /opt/sequtils/fasta_rna_to_dna_strict.py
COPY combined.conf /opt/vadr/combined.conf
COPY greninger-lab-install.sh /opt/vadr/greninger-lab-install.sh
RUN sh greninger-lab-install.sh
COPY split_multi_fasta.py /opt/sequtils/split_multi_fasta.py
COPY generate_sample_fasta_csv.py /opt/sequtils/generate_sample_fasta_csv.py

RUN cpan -T Mozilla::CA

ENV VADRINSTALLDIR=/opt/vadr
ENV VADRSCRIPTSDIR=/opt/vadr/vadr
ENV VADRCONFIGFILE=/opt/vadr/vadr.config
ENV VADRMODELDIR=/opt/vadr
ENV VADRINFERNALDIR=/opt/vadr/infernal/binaries
ENV VADREASELDIR=/opt/vadr/infernal/binaries
ENV VADRHMMERDIR=/opt/vadr/infernal/binaries
ENV VADRBIOEASELDIR=/opt/vadr/Bio-Easel
ENV VADRSEQUIPDIR=/opt/vadr/sequip
ENV VADRBLASTDIR=/opt/vadr/ncbi-blast/bin
ENV VADRFASTADIR=/opt/vadr/fasta/bin
ENV VADRMINIMAP2DIR=/opt/vadr/minimap2
ENV PERL5LIB=$VADRSCRIPTSDIR:$VADRSEQUIPDIR:$VADRBIOEASELDIR/blib/lib:$VADRBIOEASELDIR/blib/arch:$PERL5LIB
ENV PATH=$VADRSCRIPTSDIR:$PATH

RUN mkdir work
WORKDIR /opt/vadr/work

