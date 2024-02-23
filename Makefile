SSHELL     := bash 
MAKEFLAGS += --warn-undefined-variables
.SILENT: 

help          :  ## show help
	awk 'BEGIN {FS = ":.*?## "; print "\nmake [WHAT]" } \
			/^[^[:space:]].*##/ {printf "   \033[36m%-10s\033[0m : %s\n", $$1, $$2} \
			' $(MAKEFILE_LIST)

saved         : ## save and push to main branch 
	read -p "commit msg> " x; y=$${x:-saved}; git commit -am "$$y}"; git push;  git status; echo "$$y, saved!"
 

FILES=$(wildcard *.jl)
docs: 
	$(MAKE) -B $(addprefix docs/, $(FILES:.jl=.md))
 

docs/%.md : %.jl
	echo "# $^ ==> $@"
	gawk -f etc/jl2md.awk $^ > $@

~/tmp/%.pdf   : %.jl  ## jl ==> pdf
	mkdir -p ~/tmp
	echo "$@" 
	a2ps                           \
		-qBr                          \
		--chars-per-line 100           \
		--file-align=fill               \
		--line-numbers=1                 \
		--borders=no                      \
		--pro=color                        \
		--columns  3                        \
		-M letter                            \
		-o ~/tmp/$^.ps $^ ;                   \
	ps2pdf ~/tmp/$^.ps $@ ;  rm ~/tmp/$^.ps; \

name:
	read -p "word> " w; figlet -f mini -W $$w  | gawk '$$0 {print "#        "$$0}' |pbcopy
