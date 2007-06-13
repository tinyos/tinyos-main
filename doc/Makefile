OVERVIEW = txt/overview.txt
OVERVIEW_HTML = $(subst txt/,,$(subst .txt,.html,$(OVERVIEW)))
TEPS = $(wildcard txt/*.txt)
TEPS_HTML = $(subst txt/,,$(subst .txt,.html,$(TEPS)))
TEP_STYLESHEET = stylesheets/tep.css

#override for different docutils installations
ifndef RST2HTML
RST2HTML= rst2html.py
endif

STYLESHEET = stylesheets/doc.css

HTML = $(OVERVIEW_HTML)

all: overview teps

$(OVERVIEW_HTML): $(OVERVIEW) $(STYLESHEET)
	$(RST2HTML) --stylesheet-path=$(STYLESHEET) --embed-stylesheet $< > html/$@

%.html: txt/%.txt $(TEP_STYLESHEET)
	rst2html.py --stylesheet-path=$(TEP_STYLESHEET) --embed-stylesheet $< > html/$@

overview: $(OVERVIEW_HTML)

teps: $(TEPS_HTML)

clean:
	rm -f html/*.html txt/*~ 

