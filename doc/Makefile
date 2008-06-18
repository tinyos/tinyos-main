OVERVIEW = txt/overview.txt
OVERVIEW_HTML = $(subst txt/,,$(subst .txt,.html,$(OVERVIEW)))
STYLESHEET = stylesheets/doc.css
HTML = $(OVERVIEW_HTML)
TEPS = $(wildcard txt/*.txt)
TEPS_HTML = $(subst txt/,,$(subst .txt,.html,$(TEPS)))
TEPS_TEX = $(subst txt/,,$(subst .txt,.tex,$(TEPS)))
TEP_STYLESHEET = stylesheets/tep.css

#override for different docutils installations
ifndef RST2HTML
RST2HTML= rst2html
endif
ifndef RST2LATEX
RST2LATEX= rst2latex
endif


all: overview teps

pdf: $(TEPS_TEX) 



$(OVERVIEW_HTML): $(OVERVIEW) $(STYLESHEET)
	$(RST2HTML) --stylesheet-path=$(STYLESHEET) --embed-stylesheet $< > html/$@

%.html: txt/%.txt $(TEP_STYLESHEET)
	$(RST2HTML) --stylesheet-path=$(TEP_STYLESHEET) --embed-stylesheet $< > html/$@

%.tex: txt/%.txt 
	$(RST2LATEX) $< > pdf/$@
	pdflatex -interaction=batchmode -output-directory pdf $@

overview: $(OVERVIEW_HTML)

teps: $(TEPS_HTML)

clean:
	rm -f html/*.html txt/*~ pdf/*.log pdf/*.out pdf/*.tex pdf/*.aux

cleanpdf:
	rm -f pdf/*.log pdf/*.out pdf/*.tex pdf/*.aux

