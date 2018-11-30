RESULT_SETS = pre post

BENCHMARKS = Richards DeltaBlue Crypto RayTrace EarleyBoyer RegExp Splay PdfJS \
			 CodeLoad Box2D Typescript

# The following to too few nursery GCs to be useful:
#   Mandreel
#   NavierStokes
#   Gameboy
#   zlib

GRAPH_FILES = $(foreach set, $(RESULT_SETS), \
                $(foreach benchmark, $(BENCHMARKS), \
                  output/$(benchmark)/$(set).svg))

HTML_FILES = $(foreach benchmark, $(BENCHMARKS), \
               output/$(benchmark).html)

SPLIT_DATA_FILES = $(foreach set, $(RESULT_SETS), \
					 $(foreach benchmark, $(BENCHMARKS), \
                       data/$(benchmark)/$(set).dat))

INTERMEDIATES = $(SPLIT_DATA_FILES)

all: $(GRAPH_FILES) $(HTML_FILES)

.PHONY: clean
clean:
	rm -rf data/* output/*

.PRECIOUS: $(INTERMEDIATES)

data/%/pre.dat: results/pre/octane.txt bin/extractResults
	mkdir -p $(@D)
	bin/extractResults $* $< > $@

data/%/post.dat: results/post/octane.txt bin/extractResults
	mkdir -p $(@D)
	bin/extractResults $* $< > $@

output/%.svg: data/%.dat
	mkdir -p $(@D)
	gnuplot -e "\
		set terminal svg size $(shell bin/calcSize $^); \
		set xlabel 'Collection'; \
		set ylabel 'Nursery size'; \
		set y2label 'Promotion rate / %'; \
		set border 11 back; \
		set xtics nomirror; \
		set ytics nomirror; \
		set y2tics; \
		plot [][0:16][][0:20] '$^' using 1 with linespoints title 'Nursery size', \
			'' using 2 with linespoints axes x1y2 title 'Promotion rate'; " > $@

output/%.html: template/benchmark.html
	mkdir -p $(@D)
	bin/substitute $< $(*F) > $@
