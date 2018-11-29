RESULTS_FILES = results/pre.txt results/post.txt

BENCHMARKS = Richards DeltaBlue Crypto RayTrace EarleyBoyer RegExp Splay PdfJS \
			 CodeLoad Box2D Typescript

# The following to too few nursery GCs to be useful:
#   Mandreel
#   NavierStokes
#   Gameboy
#   zlib

GRAPH_FILES = $(foreach set, pre post both, \
                $(foreach benchmark, $(BENCHMARKS), \
                  output/$(set)/$(benchmark).svg))

HTML_FILES = $(foreach benchmark, $(BENCHMARKS), \
               output/$(benchmark).html)

INTERMEDIATES = $(foreach benchmark, $(BENCHMARKS), \
				  data/$(benchmark)/pre.dat \
				  data/$(benchmark)/post.dat)

all: $(GRAPH_FILES) $(HTML_FILES)

.PHONY: clean
clean:
	rm -rf data/* output/*

.PRECIOUS: $(INTERMEDIATES)

data/%/pre.dat: results/pre_log.txt bin/extractResults
	mkdir -p $(@D)
	bin/extractResults $* $< > $@

data/%/post.dat: results/post_log.txt bin/extractResults
	mkdir -p $(@D)
	bin/extractResults $* $< > $@

PLOT_OPTIONS = -x "Time" -y "Nursery size" -l linespoints -r [][0:16]

output/pre/%.svg: data/%/pre.dat
	mkdir -p $(@D)
	eplot -d -m $^ -t "Pre" $(PLOT_OPTIONS) -s $(shell bin/calcSize $^) -g -o $@

output/post/%.svg: data/%/post.dat
	mkdir -p $(@D)
	eplot -d -m $^ -t "Post" $(PLOT_OPTIONS) -s $(shell bin/calcSize $^) -g -o $@

output/both/%.svg: data/%/pre.dat data/%/post.dat
	mkdir -p $(@D)
	eplot -d -m $^ -t "Pre@Post" $(PLOT_OPTIONS) -s $(shell bin/calcSize $^) -g -o $@

output/%.html: template/benchmark.html
	mkdir -p $(@D)
	bin/substitute $< $(*F) > $@
