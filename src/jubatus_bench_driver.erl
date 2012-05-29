%% -------------------------------------------------------------------
%%
%% basho_bench: Benchmarking Suite
%%
%% Copyright (c) 2009-2010 Basho Techonologies
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.    
%%
%% -------------------------------------------------------------------
-module(jubatus_bench_driver).

-export([new/1,
         run/4]).

-include_lib("basho_bench/include/basho_bench.hrl").
-include_lib("jubatus/include/classifier.hrl").

%% ====================================================================
%% API
%% ====================================================================

-record(state, { host, port }).

new(_Id) ->
    inets:start(),
    mprc:start(),
    case code:which(classifier) of
        non_existing ->
            ?FAIL_MSG("~s requires classifier module to be available on code path.\n",
                      [?MODULE]);
        _ ->
            ok
    end,

    Host = basho_bench_config:get(host, localhost),
    Port = basho_bench_config:get(port, 9199),
    {ok,MPRC} = classifier:connect([{Host,Port}]),
    Config0 = [<<"PA">>,
	       [
		{[]},%string_filter_types,
		[],  %string_filter_rules,
		{[]},%num_filter_types,
		[],  %num_filter_rules,
		{[]},%string_types,
		[],  %string_rules,
		{[]},%num_types,
		[[<<"*">>, <<"num">>]]   %num_rules
	       ]],
    {ok,MPRC1} = classifier:set_config(MPRC, test,Config0),
    classifier:close(MPRC1),
    {ok, #state{host=Host,port=Port}}.

run(get, _KeyGen, ValueGen, #state{host=H,port=P}=State) ->
    Value0 = io_lib:format("~p", [ValueGen()]),
    Value1 = io_lib:format("~p", [ValueGen()]),
    {ok,MPRC} = classifier:connect([{H,P}]),
    case classifier:classify(MPRC, test,
			     [#datum{string_values=[{Value0,Value0},
						    {Value1,Value1}],
				     num_values=[]}]) of
	{ok, MPRC1, _} ->
	    classifier:close(MPRC1),
	    {ok, State};
	{error,E} -> {error,E}
    end;
run(put, KeyGen, ValueGen, #state{host=H,port=P}=State) ->
    Key = KeyGen(),
    Value0 = io_lib:format("~p", [ValueGen()]),
    Value1 = io_lib:format("~p", [ValueGen()]),
    {ok,MPRC}=Classifier = classifier:connect([{H,P}]),
    case classifier:train(MPRC, test,
			  [{Key, #datum{string_values=[{Value0,Value0},
						       {Value1,Value1}],
					num_values=[]}}]) of
	{ok, MPRC1} ->
	    classifier:close(MPRC1),
	    {ok, State};
	{error, E} -> {error,E}
    end;
run(delete, KeyGen, ValueGen, State) ->
    run(put, KeyGen, ValueGen, State).
