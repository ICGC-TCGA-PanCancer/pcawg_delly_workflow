import pybedtools
from pybedtools.featurefuncs import add_color
a = pybedtools.example_bedtool('a.bed')
def modify_scores(f):
    fields = f.fields
    fields[4] = str(f[2])
    return pybedtools.create_interval_from_list(fields)

a = a.each(modify_scores).saveas()
print(a)


from matplotlib import cm
cmap = cm.jet

norm  = a.colormap_normalize()

a = a.each(add_color, cmap=cmap, norm=norm).saveas()
print(a)
