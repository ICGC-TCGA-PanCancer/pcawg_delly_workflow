from abc import ABCMeta, abstractmethod
import collections
import sys

try:
    from collections import Counter
except ImportError:
    from counter import Counter


class _Call(object):
    """ A genotype call, a cell entry in a VCF file"""

    __slots__ = ['site', 'sample', 'data', 'gt_nums', 'called']

    def __init__(self, site, sample, data):
        #: The ``_Record`` for this ``_Call``
        self.site = site
        #: The sample name
        self.sample = sample
        #: Dictionary of data from the VCF file
        self.data = data
        try:
            self.gt_nums = self.data.GT
            #: True if the GT is not ./.
            self.called = self.gt_nums is not None
        except AttributeError:
            self.gt_nums = None
            #62 a call without a genotype is not defined as called or not
            self.called = None

    def __repr__(self):
        return "Call(sample=%s, %s)" % (self.sample, str(self.data))

    def __eq__(self, other):
        """ Two _Calls are equal if their _Records are equal
            and the samples and ``gt_type``s are the same
        """
        return (self.site == getattr(other, "site", None)
                and self.sample == getattr(other, "sample", None)
                and self.gt_type == getattr(other, "gt_type", None))

    def __getstate__(self):
        return dict((attr, getattr(self, attr)) for attr in self.__slots__)

    def __setstate__(self, state):
        for attr in self.__slots__:
            setattr(self, attr, state.get(attr))

    def gt_phase_char(self):
        return "/" if not self.phased else "|"

    @property
    def gt_alleles(self):
        '''The numbers of the alleles called at a given sample'''
        # grab the numeric alleles of the gt string; tokenize by phasing
        return self.gt_nums.split(self.gt_phase_char())

    @property
    def gt_bases(self):
        '''The actual genotype alleles.
           E.g. if VCF genotype is 0/1, return A/G
        '''
        # nothing to do if no genotype call
        if self.called:
            # lookup and return the actual DNA alleles
            try:
                return self.gt_phase_char().join(str(self.site.alleles[int(X)]) for X in self.gt_alleles)
            except:
                sys.stderr.write("Allele number not found in list of alleles\n")
        else:
            return None

    @property
    def gt_type(self):
        '''The type of genotype.
           hom_ref  = 0
           het      = 1
           hom_alt  = 2  (we don;t track _which+ ALT)
           uncalled = None
        '''
        # extract the numeric alleles of the gt string
        if self.called:
            alleles = self.gt_alleles
            if all(X == alleles[0] for X in alleles[1:]):
                if alleles[0] == "0":
                    return 0
                else:
                    return 2
            else:
                return 1
        else:
            return None

    @property
    def phased(self):
        '''A boolean indicating whether or not
           the genotype is phased for this sample
        '''
        return self.gt_nums is not None and self.gt_nums.find("|") >= 0

    def __getitem__(self, key):
        """ Lookup value, backwards compatibility """
        return getattr(self.data, key)

    @property
    def is_variant(self):
        """ Return True if not a reference call """
        if not self.called:
            return None
        return self.gt_type != 0

    @property
    def is_het(self):
        """ Return True for heterozygous calls """
        if not self.called:
            return None
        return self.gt_type == 1


class _Record(object):
    """ A set of calls at a site.  Equivalent to a row in a VCF file.

        The standard VCF fields CHROM, POS, ID, REF, ALT, QUAL, FILTER,
        INFO and FORMAT are available as properties.

        The list of genotype calls is in the ``samples`` property.
    """
    def __init__(self, CHROM, POS, ID, REF, ALT, QUAL, FILTER, INFO, FORMAT,
            sample_indexes, samples=None):
        self.CHROM = CHROM
        self.POS = POS
        self.ID = ID
        self.REF = REF
        self.ALT = ALT
        self.QUAL = QUAL
        self.FILTER = FILTER
        self.INFO = INFO
        self.FORMAT = FORMAT
        #: 0-based start coordinate
        self.start = self.POS - 1
        #: 1-based end coordinate
        self.end = self.start + len(self.REF)
        #: list of alleles. [0] = REF, [1:] = ALTS
        self.alleles = [self.REF]
        self.alleles.extend(self.ALT)
        #: list of ``_Calls`` for each sample ordered as in source VCF
        self.samples = samples or []
        self._sample_indexes = sample_indexes

    # For Python 2
    def __cmp__(self, other):
        return cmp((self.CHROM, self.POS), (getattr(other, "CHROM", None), getattr(other, "POS", None)))

    # For Python 3
    def __eq__(self, other):
        """ _Records are equal if they describe the same variant (same position, alleles) """
        return (self.CHROM == getattr(other, "CHROM", None) and
                self.POS == getattr(other, "POS", None) and
                self.REF == getattr(other, "REF", None) and
                self.ALT == getattr(other, "ALT", None))

    # For Python 3
    def __lt__(self, other):
        return (self.CHROM, self.POS) < (getattr(other, "CHROM", None), getattr(other, "POS", None))

    def __iter__(self):
        return iter(self.samples)

    def __str__(self):
        return "Record(CHROM=%(CHROM)s, POS=%(POS)s, REF=%(REF)s, ALT=%(ALT)s)" % self.__dict__

    def add_format(self, fmt):
        self.FORMAT = self.FORMAT + ':' + fmt

    def add_filter(self, flt):
        if self.FILTER is None:
            self.FILTER = [flt]
        else:
            self.FILTER.append(flt)

    def add_info(self, info, value=True):
        self.INFO[info] = value

    def genotype(self, name):
        """ Lookup a ``_Call`` for the sample given in ``name`` """
        return self.samples[self._sample_indexes[name]]

    @property
    def num_called(self):
        """ The number of called samples"""
        return sum(s.called for s in self.samples)

    @property
    def call_rate(self):
        """ The fraction of genotypes that were actually called. """
        return float(self.num_called) / float(len(self.samples))

    @property
    def num_hom_ref(self):
        """ The number of homozygous for ref allele genotypes"""
        return len([s for s in self.samples if s.gt_type == 0])

    @property
    def num_hom_alt(self):
        """ The number of homozygous for alt allele genotypes"""
        return len([s for s in self.samples if s.gt_type == 2])

    @property
    def num_het(self):
        """ The number of heterozygous genotypes"""
        return len([s for s in self.samples if s.gt_type == 1])

    @property
    def num_unknown(self):
        """ The number of unknown genotypes"""
        return len([s for s in self.samples if s.gt_type is None])

    @property
    def aaf(self):
        """ A list of allele frequencies of alternate alleles.
           NOTE: Denominator calc'ed from _called_ genotypes.
        """
        num_chroms = 2.0 * self.num_called
        allele_counts = Counter()
        for s in self.samples:
            if s.gt_type is not None:
                allele_counts.update([s.gt_alleles[0]])
                allele_counts.update([s.gt_alleles[1]])
        return [allele_counts[str(i)]/num_chroms for i in range(1, len(self.ALT)+1)]

    @property
    def nucl_diversity(self):
        """
        pi_hat (estimation of nucleotide diversity) for the site.
        This metric can be summed across multiple sites to compute regional
        nucleotide diversity estimates.  For example, pi_hat for all variants
        in a given gene.

        Derived from:
        \"Population Genetics: A Concise Guide, 2nd ed., p.45\"
          John Gillespie.
        """
        # skip if more than one alternate allele. assumes bi-allelic
        if len(self.ALT) > 1:
            return None
        p = self.aaf[0]
        q = 1.0 - p
        num_chroms = float(2.0 * self.num_called)
        return float(num_chroms / (num_chroms - 1.0)) * (2.0 * p * q)

    @property
    def heterozygosity(self):
        """
        Heterozygosity of a site. Heterozygosity gives the probability that
        two randomly chosen chromosomes from the population have different
        alleles, giving a measure of the degree of polymorphism in a population.

        If there are i alleles with frequency p_i, H=1-sum_i(p_i^2)
        """
        allele_freqs = [1-sum(self.aaf)] + self.aaf
        return 1 - sum(map(lambda x: x**2, allele_freqs))

    def get_hom_refs(self):
        """ The list of hom ref genotypes"""
        return [s for s in self.samples if s.gt_type == 0]

    def get_hom_alts(self):
        """ The list of hom alt genotypes"""
        return [s for s in self.samples if s.gt_type == 2]

    def get_hets(self):
        """ The list of het genotypes"""
        return [s for s in self.samples if s.gt_type == 1]

    def get_unknowns(self):
        """ The list of unknown genotypes"""
        return [s for s in self.samples if s.gt_type is None]

    @property
    def is_snp(self):
        """ Return whether or not the variant is a SNP """
        if len(self.REF) > 1:
            return False
        for alt in self.ALT:
            if alt is None or alt.type != "SNV":
                return False
            if alt not in ['A', 'C', 'G', 'T']:
                return False
        return True

    @property
    def is_indel(self):
        """ Return whether or not the variant is an INDEL """
        is_sv = self.is_sv

        if len(self.REF) > 1 and not is_sv:
            return True
        for alt in self.ALT:
            if alt is None:
                return True
            if alt.type != "SNV" and alt.type != "MNV":
                return False
            elif len(alt) != len(self.REF):
                # the diff. b/w INDELs and SVs can be murky.
                if not is_sv:
                    # 1	2827693	.	CCCCTCGCA	C	.	PASS	AC=10;
                    return True
                else:
                    # 1	2827693	.	CCCCTCGCA	C	.	PASS	SVTYPE=DEL;
                    return False
        return False

    @property
    def is_sv(self):
        """ Return whether or not the variant is a structural variant """
        if self.INFO.get('SVTYPE') is None:
            return False
        return True

    @property
    def is_transition(self):
        """ Return whether or not the SNP is a transition """
        # if multiple alts, it is unclear if we have a transition
        if len(self.ALT) > 1:
            return False

        if self.is_snp:
            # just one alt allele
            alt_allele = self.ALT[0]
            if ((self.REF == "A" and alt_allele == "G") or
                (self.REF == "G" and alt_allele == "A") or
                (self.REF == "C" and alt_allele == "T") or
                (self.REF == "T" and alt_allele == "C")):
                return True
            else:
                return False
        else:
            return False

    @property
    def is_deletion(self):
        """ Return whether or not the INDEL is a deletion """
        # if multiple alts, it is unclear if we have a transition
        if len(self.ALT) > 1:
            return False

        if self.is_indel:
            # just one alt allele
            alt_allele = self.ALT[0]
            if alt_allele is None:
                return True
            if len(self.REF) > len(alt_allele):
                return True
            else:
                return False
        else:
            return False

    @property
    def var_type(self):
        """
        Return the type of variant [snp, indel, unknown]
        TO DO: support SVs
        """
        if self.is_snp:
            return "snp"
        elif self.is_indel:
            return "indel"
        elif self.is_sv:
            return "sv"
        else:
            return "unknown"

    @property
    def var_subtype(self):
        """
        Return the subtype of variant.
        - For SNPs and INDELs, yeild one of: [ts, tv, ins, del]
        - For SVs yield either "complex" or the SV type defined
          in the ALT fields (removing the brackets).
          E.g.:
               <DEL>       -> DEL
               <INS:ME:L1> -> INS:ME:L1
               <DUP>       -> DUP

        The logic is meant to follow the rules outlined in the following
        paragraph at:

        http://www.1000genomes.org/wiki/Analysis/Variant%20Call%20Format/vcf-variant-call-format-version-41

        "For precisely known variants, the REF and ALT fields should contain
        the full sequences for the alleles, following the usual VCF conventions.
        For imprecise variants, the REF field may contain a single base and the
        ALT fields should contain symbolic alleles (e.g. <ID>), described in more
        detail below. Imprecise variants should also be marked by the presence
        of an IMPRECISE flag in the INFO field."
        """
        if self.is_snp:
            if self.is_transition:
                return "ts"
            elif len(self.ALT) == 1:
                return "tv"
            else:  # multiple ALT alleles.  unclear
                return "unknown"
        elif self.is_indel:
            if self.is_deletion:
                return "del"
            elif len(self.ALT) == 1:
                return "ins"
            else:  # multiple ALT alleles.  unclear
                return "unknown"
        elif self.is_sv:
            if self.INFO['SVTYPE'] == "BND":
                return "complex"
            elif self.is_sv_precise:
                return self.INFO['SVTYPE']
            else:
                return self.ALT[0].type
        else:
            return "unknown"

    @property
    def sv_end(self):
        """ Return the end position for the SV """
        if self.is_sv:
            return self.INFO['END']
        return None

    @property
    def is_sv_precise(self):
        """ Return whether the SV cordinates are mapped
            to 1 b.p. resolution.
        """
        if self.INFO.get('IMPRECISE') is None and not self.is_sv:
            return False
        elif self.INFO.get('IMPRECISE') is not None and self.is_sv:
            return False
        elif self.INFO.get('IMPRECISE') is None and self.is_sv:
            return True

    @property
    def is_monomorphic(self):
        """ Return True for reference calls """
        return len(self.ALT) == 1 and self.ALT[0] is None


class _AltRecord(object):
    '''An alternative allele record: either replacement string, SV placeholder, or breakend'''
    __metaclass__ = ABCMeta

    def __init__(self, type, **kwargs):
        super(_AltRecord, self).__init__(**kwargs)
        #: String to describe the type of variant, by default "SNV" or "MNV", but can be extended to any of the types described in the ALT lines of the header (e.g. "DUP", "DEL", "INS"...)
        self.type = type

    @abstractmethod
    def __str__(self):
        raise NotImplementedError

    def __eq__(self, other):
        return self.type == getattr(other, 'type', None)


class _Substitution(_AltRecord):
    '''A basic ALT record, where a REF sequence is replaced by an ALT sequence'''

    def __init__(self, nucleotides, **kwargs):
        if len(nucleotides) == 1:
            super(_Substitution, self).__init__(type="SNV", **kwargs)
        else:
            super(_Substitution, self).__init__(type="MNV", **kwargs)
        #: Alternate sequence
        self.sequence = str(nucleotides)

    def __str__(self):
        return self.sequence

    def __repr__(self):
        return str(self)

    def __len__(self):
        return len(self.sequence)

    def __eq__(self, other):
        if isinstance(other, basestring):
            return self.sequence == other
        elif not isinstance(other, self.__class__):
            return False
        return super(_Substitution, self).__eq__(other) and self.sequence == other.sequence


class _Breakend(_AltRecord):
    '''A breakend which is paired to a remote location on or off the genome'''

    def __init__(self, chr, pos, orientation, remoteOrientation, connectingSequence, withinMainAssembly, **kwargs):
        super(_Breakend, self).__init__(type="BND", **kwargs)
        #: The chromosome of breakend's mate.
        if chr is not None:
            self.chr = str(chr)
        else:
            self.chr = None  # Single breakend
        #: The coordinate of breakend's mate.
        if pos is not None:
            self.pos = int(pos)
        else:
            self.pos = None
        #: The orientation of breakend's mate. If the sequence 3' of the breakend's mate is connected, True, else if the sequence 5' of the breakend's mate is connected, False.
        self.remoteOrientation = remoteOrientation
        #: If the breakend mate is within the assembly, True, else False if the breakend mate is on a contig in an ancillary assembly file.
        self.withinMainAssembly = withinMainAssembly
        #: The orientation of breakend. If the sequence 3' of the breakend is connected, True, else if the sequence 5' of the breakend is connected, False.
        self.orientation = orientation
        #: The breakpoint's connecting sequence.
        self.connectingSequence = connectingSequence

    def __repr__(self):
        return str(self)

    def __str__(self):
        if self.chr is None:
            remoteTag = '.'
        else:
            if self.withinMainAssembly:
                remoteChr = self.chr
            else:
                remoteChr = "<" + self.chr + ">"
            if self.remoteOrientation:
                remoteTag = "[" + remoteChr + ":" + str(self.pos) + "["
            else:
                remoteTag = "]" + remoteChr + ":" + str(self.pos) + "]"

        if self.orientation:
            return remoteTag + self.connectingSequence
        else:
            return self.connectingSequence + remoteTag

    def __eq__(self, other):
        if not isinstance(other, self.__class__):
            return False
        return super(_Breakend, self).__eq__(other) \
                and self.chr == getattr(other, "chr", None) \
                and self.pos == getattr(other, "pos", None) \
                and self.remoteOrientation == getattr(other, "remoteOrientation", None) \
                and self.withinMainAssembly == getattr(other, "withinMainAssembly", None) \
                and self.orientation == getattr(other, "orientation", None) \
                and self.connectingSequence == getattr(other, "connectingSequence", None)


class _SingleBreakend(_Breakend):
    '''A single breakend'''

    def __init__(self, orientation, connectingSequence, **kwargs):
        super(_SingleBreakend, self).__init__(None, None, orientation, None, connectingSequence, None, **kwargs)


class _SV(_AltRecord):
    '''An SV placeholder'''

    def __init__(self, type, **kwargs):
        super(_SV, self).__init__(type, **kwargs)

    def __str__(self):
        return "<" + self.type + ">"

    def __repr__(self):
        return str(self)


def make_calldata_tuple(fields):
    """ Return a namedtuple for a given call format """

    class CallData(collections.namedtuple('calldata', fields)):
        __slots__ = ()

        _types = []
        _nums = []

        def __str__(self):
            dat = ", ".join(["%s=%s" % (x, y)
                for (x, y) in zip(self._fields, self)])
            return "CallData(" + dat + ')'

        def __reduce__(self):
            args = super(CallData, self).__reduce__()
            return make_calldata_tuple, (fields, )

    return CallData
