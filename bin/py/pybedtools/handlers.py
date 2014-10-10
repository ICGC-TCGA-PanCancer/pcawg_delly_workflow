from .bedtool import BedTool

def _jaccard_output_to_dict(s, **kwargs):
    """
    jaccard method doesn't return an interval file, rather, it returns a short
    summary of results.  Here, we simply parse it into a dict for convenience.
    """
    if isinstance(s, str):
        s = open(s).read()
    if hasattr(s, 'next'):
        s = ''.join(i for i in s)
    header, data = s.splitlines()
    header = header.split()
    data = data.split()
    data[0] = int(data[0])
    data[1] = int(data[1])
    data[2] = float(data[2])
    data[3] = int(data[3])
    return dict(list(zip(header, data)))


def _reldist_output_handler(s, **kwargs):
    """
    reldist, if called with -detail, returns a valid BED file with the relative
    distance as the last field.  In that case, return the BedTool immediately.
    If not -detail, then the results are a table, in which case here we parse
    into a dict for convenience.
    """
    if 'detail' in kwargs:
        return BedTool(s)
    if isinstance(s, str):
        iterable = open(s)
    if hasattr(s, 'next'):
        iterable = s
    header = iterable.next().split()
    results = {}
    for h in header:
        results[h] = []
    for i in iterable:
        reldist, count, total, fraction = i.split()
        data = [
            float(reldist),
            int(count),
            int(total),
            float(fraction)
        ]
        for h, d in zip(header, data):
            results[h].append(d)
    return results

