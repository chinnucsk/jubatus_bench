.PHONY: compile xref eunit clean doc check make

all: compile xref
test: eunit

# for busy typos
m: all
ma: all
mak: all
make: all

dialyze:
	@./rebar check-plt
	@./rebar dialyze

compile:
	@./rebar compile

xref:
	@./rebar xref

eunit: compile
	@./rebar skip_deps=true eunit

clean:
	@./rebar clean

doc:
	@./rebar doc
