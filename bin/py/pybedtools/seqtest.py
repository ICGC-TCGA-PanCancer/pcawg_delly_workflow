import pybedtools

def generator():
    seqsize = 3
    for i in range(100):
        strand = '+'
        if i % 2 == 0:
            strand = '-'
        yield pybedtools.create_interval_from_list([
            'chr1',
            str(seqsize * i),
            str(seqsize * i + seqsize),
            'region_%s' % i,
            '.',
            strand
        ])
    return

x = pybedtools.BedTool(generator())

x.sequence(
    fi=pybedtools.example_filename('test.fa'),
    fo='example',
    name=True,
    s=True)

print(open('example').read())
