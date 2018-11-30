RESULT_SETS = pre post

# The following octane benchmarks do too few nursery GCs to be useful:
#   Mandreel
#   NavierStokes
#   Gameboy
#   zlib
OCTANE_BENCHMARKS = Richards DeltaBlue Crypto RayTrace EarleyBoyer RegExp \
				    Splay PdfJS CodeLoad Box2D Typescript

BENCHMARKS = $(OCTANE_BENCHMARKS) ares6

GRAPH_FILES = $(foreach set, $(RESULT_SETS), \
                $(foreach benchmark, $(BENCHMARKS), \
                  output/$(set)/$(benchmark).svg))

HTML_FILES = $(foreach benchmark, $(BENCHMARKS), \
               output/$(benchmark).html)

SPLIT_DATA_FILES = $(foreach set, $(RESULT_SETS), \
					 $(foreach benchmark, $(OCTANE_BENCHMARKS), \
                       data/$(set)/$(benchmark).dat))

SPLIT_TRIGGER_FILES = $(foreach set, $(RESULT_SETS), data/$(set).split)

ALL_DATA_FILES = $(foreach set, $(RESULT_SETS), \
				   $(foreach benchmark, $(BENCHMARKS), \
                     data/$(set)/$(benchmark).dat))

INTERMEDIATES = $(ALL_DATA_FILES) $(SPLIT_TRIGGER_FILES)

all: $(GRAPH_FILES) $(HTML_FILES)

.PHONY: clean
clean:
	rm -rf data/* output/*

.PRECIOUS: $(INTERMEDIATES)

data/%.split: results/%/octane.txt bin/splitResults
	mkdir -p data/$*
	bin/splitResults data/$* $<
	touch $@

$(SPLIT_DATA_FILES): $(SPLIT_TRIGGER_FILES)

data/%/ares6.dat: results/%/ares6.txt bin/extractAres6
	mkdir -p $(@D)
	bin/extractAres6 $< > $@

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
