RESULTS_FILES = results/pre.txt results/post.txt

BENCHMARKS = Richards DeltaBlue Crypto RayTrace EarleyBoyer RegExp Splay PdfJS \
			 Gameboy CodeLoad Box2D zlib Typescript

# The following don't do any nursery GCs:
#   Mandreel
#   NavierStokes

GRAPH_FILES = $(foreach benchmark, $(BENCHMARKS), output/$(benchmark).svg)

INTERMEDIATES = $(foreach benchmark, $(BENCHMARKS), \
				  data/$(benchmark)/pre.dat \
				  data/$(benchmark)/post.dat)

all: $(GRAPH_FILES)

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

output/%.svg: data/%/pre.dat data/%/post.dat
	mkdir -p $(@D)
	eplot -d -m $^ -t "Pre@Post" -x "Time" -y "Nursery size" --ylog -g -o $@
