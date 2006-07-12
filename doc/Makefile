OVERVIEW = txt/overview.txt
OVERVIEW_HTML = $(subst txt/,,$(subst .txt,.html,$(OVERVIEW)))
TEPS = $(wildcard txt/*.txt)
TEPS_HTML = $(subst txt/,,$(subst .txt,.html,$(TEPS)))
TEP_STYLESHEET = stylesheets/tep.css
 

STYLESHEET = stylesheets/doc.css

HTML = $(OVERVIEW_HTML)

all: overview teps

$(OVERVIEW_HTML): $(OVERVIEW) $(STYLESHEET)
	rst2html.py --stylesheet-path=$(STYLESHEET) --embed-stylesheet $< > html/$@

%.html: txt/%.txt $(TEP_STYLESHEET)
	rst2html.py --stylesheet-path=$(TEP_STYLESHEET) --embed-stylesheet $< > html/$@

overview: $(OVERVIEW_HTML)

teps: $(TEPS_HTML)

clean:
	rm -f html/*.html txt/*~ 

