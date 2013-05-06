OVERVIEW = txt/overview.txt
OVERVIEW_HTML = $(subst txt/,html/,$(subst .txt,.html,$(OVERVIEW)))
STYLESHEET = stylesheets/doc.css
HTML = $(OVERVIEW_HTML)
TEPS = $(wildcard txt/*.txt)
TEPS_HTML = $(subst txt/,html/,$(subst .txt,.html,$(TEPS)))
TEPS_TEX = $(subst txt/,pdf/,$(subst .txt,.tex,$(TEPS)))
TEPS_PDF = $(subst txt/,pdf/,$(subst .txt,.pdf,$(TEPS)))
TEP_STYLESHEET = stylesheets/tep.css

#override for different docutils installations
ifndef RST2HTML
RST2HTML= rst2html
endif
ifndef RST2LATEX
RST2LATEX= rst2latex
endif


all: overview teps pdf

$(OVERVIEW_HTML): $(OVERVIEW) $(STYLESHEET)
	$(RST2HTML) --stylesheet-path=$(STYLESHEET) --embed-stylesheet $< > $@

html/%.html: txt/%.txt $(TEP_STYLESHEET)
	$(RST2HTML) --stylesheet-path=$(TEP_STYLESHEET) --embed-stylesheet $< > $@

pdf/%.tex: txt/%.txt
	$(RST2LATEX) $< > $@

pdf/%.pdf: pdf/%.tex
	pdflatex -interaction=batchmode -output-directory pdf $<
	rm $(basename $@).aux
	rm $(basename $@).log
	rm $(basename $@).out
	rm -f $(basename $@).toc

overview: $(OVERVIEW_HTML)

teps: $(TEPS_HTML)

pdf: $(TEPS_PDF)

clean: cleanpdf
	rm -f html/tep*.html html/overview.html html/porting.html txt/*~

cleanpdf:
	rm -f pdf/*.log pdf/*.out pdf/*.tex pdf/*.aux pdf/*.toc pdf/tep*.pdf pdf/overview.pdf pdf/porting.pdf
