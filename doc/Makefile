OVERVIEW = txt/overview.txt
OVERVIEW_HTML = $(subst txt/,html/tep/,$(subst .txt,.html,$(OVERVIEW)))
STYLESHEET = stylesheets/doc.css
HTML = $(OVERVIEW_HTML)
TEPS = $(wildcard txt/*.txt)
TEPS_HTML = $(subst txt/,html/tep/,$(subst .txt,.html,$(TEPS)))
TEPS_PDF = $(subst txt/,pdf/tep/,$(subst .txt,.pdf,$(TEPS)))
TEP_STYLESHEET = stylesheets/tep.css

#override for different docutils installations
ifndef RST2HTML
RST2HTML= rst2html
endif
ifndef RST2LATEX
RST2LATEX= rst2latex
endif


all: overview teps pdf

html/tep:
	mkdir -p $@

pdf/tep:
	mkdir -p pdf/tep

$(OVERVIEW_HTML): $(OVERVIEW) $(STYLESHEET) | html/tep
	$(RST2HTML) --stylesheet-path=$(STYLESHEET) --embed-stylesheet $< > $@

html/tep/%.html: txt/%.txt $(TEP_STYLESHEET) | html/tep
	$(RST2HTML) --stylesheet-path=$(TEP_STYLESHEET) --embed-stylesheet $< > $@

pdf/tep/%.tex: txt/%.txt | pdf/tep
	$(RST2LATEX) $< > $@

pdf/tep/%.pdf: pdf/tep/%.tex | pdf/tep
	pdflatex -interaction=batchmode -output-directory pdf/tep $<
	rm $(basename $@).aux
	rm $(basename $@).log
	rm $(basename $@).out
	rm -f $(basename $@).toc

overview: $(OVERVIEW_HTML)

teps: $(TEPS_HTML)

pdf: $(TEPS_PDF)

clean:
	rm -rf html/tep pdf/tep

cleanpdf:
	rm -rf pdf/tep

