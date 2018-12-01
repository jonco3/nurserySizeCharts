RESULT_SETS = pre post

# The following octane benchmarks do too few nursery GCs to be useful:
#   Mandreel
#   NavierStokes
#   Gameboy
#   zlib
OCTANE_BENCHMARKS = Richards DeltaBlue Crypto RayTrace EarleyBoyer RegExp \
				    Splay PdfJS CodeLoad Box2D Typescript

# The following talos benchmarks also do too few nursery GCs to be useful:
#   tp6_*
TALOS_BENCHMARKS = ares6 speedometer

GRAPH_FILES = $(foreach set, $(RESULT_SETS), \
                $(foreach benchmark, $(OCTANE_BENCHMARKS), \
                  output/octane/$(set)/$(benchmark).svg) \
                $(foreach benchmark, $(TALOS_BENCHMARKS), \
                  output/talos/$(set)/$(benchmark).svg))

HTML_FILES = output/index.html \
             $(foreach benchmark, $(OCTANE_BENCHMARKS), \
               output/octane/$(benchmark).html) \
			 $(foreach benchmark, $(TALOS_BENCHMARKS), \
               output/talos/$(benchmark).html)

DATA_FILES = $(foreach set, $(RESULT_SETS), \
			   $(foreach benchmark, $(OCTANE_BENCHMARKS), \
                 data/octane/$(set)/$(benchmark).dat)) \
             $(foreach set, $(RESULT_SETS), \
			   $(foreach benchmark, $(TALOS_BENCHMARKS), \
                 data/talos/$(set)/$(benchmark).dat))

all: $(DATA_FILES) $(GRAPH_FILES) $(HTML_FILES)

.PHONY: clean
clean:
	rm -rf data/* output/*

# Split octane results into separate files for each sub benchmark.
.SECONDEXPANSION:
data/octane/%.dat: results/$$(dir $$*)/octane.txt
	mkdir -p $(@D)
	bin/splitResults $(@D) $<

# Extract data from talos log files with special case for ARES6.
data/talos/%.dat: results/talos/%.txt bin/extractTalos
	mkdir -p $(@D)
	bin/extractTalos $< > $@
data/talos/%/ares6.dat: results/talos/%/ares6.txt bin/extractAres6
	mkdir -p $(@D)
	bin/extractAres6 $< > $@

# Plot a graph for each benchmark.
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

# Generate HTML to compare graphs side by side.
output/%.html: Makefile
	mkdir -p $(@D)
	echo '<title>Results for $(*F)</title>' > $@
	echo '<h1>Results for $(*F)</h1>' >> $@
	echo '$(foreach set, $(RESULT_SETS), <p><img src="./$(set)/$(*F).svg"></p>)' >> $@
output/index.html: Makefile
	mkdir -p $(@D)
	echo '<title>Benchmarks</title>' > $@
	echo '<h1>Benchmarks</h1>' >> $@
	echo '<ul>$(foreach benchmark, $(OCTANE_BENCHMARKS), \
                <li><a href="./octane/$(benchmark).html">$(benchmark)</a></li>)</ul>' >> $@
	echo '<ul>$(foreach benchmark, $(TALOS_BENCHMARKS), \
                <li><a href="./talos/$(benchmark).html">$(benchmark)</a></li>)</ul>' >> $@
