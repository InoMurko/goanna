-module (goanna_api).
-export([
    start/0,
    trace/1, trace/2, trace/3,
    stop_trace/0, stop_trace/1, stop_trace/2, stop_trace/3
]).

-export([store_trace/2]).

-include_lib("goanna.hrl").

%%------------------------------------------------------------------------
%% API

%% Helper only
start() ->
    [
        application:start(APP) 
        || APP <- 
        [asn1, crypto, public_key, ssl, compiler, inets, syntax_tools, sasl, 
         goldrush, lager, goanna]
    ].

trace(Module) ->
    Opts = trace_options_default() 
        ++ [{trc, #trc_pattern{m=Module}}],
    cluster_foreach({trace, Opts}).

trace(Module, Function) ->
    Opts = trace_options_default() 
        ++ [{trc, #trc_pattern{m=Module,f=Function}}],
    cluster_foreach({trace, Opts}).

trace(Module, Function, Arity) ->
    Opts = trace_options_default() 
        ++ [{trc, #trc_pattern{m=Module,f=Function,a=Arity}}],
    cluster_foreach({trace, Opts}).

trace_options_default() ->
    [{time, {seconds, 5}},
     {messages, 50}
    ].

stop_trace() ->
    cluster_foreach(stop_trace).

stop_trace(Module) ->
    Opts = [{trc, #trc_pattern{m=Module}}],
    cluster_foreach({stop_trace, Opts}).

stop_trace(Module, Function) ->
    Opts = [{trc, #trc_pattern{m=Module,f=Function}}],
    cluster_foreach({stop_trace, Opts}).

stop_trace(Module, Function, Arity) ->
    Opts = [{trc, #trc_pattern{m=Module,f=Function,a=Arity}}],
    cluster_foreach({stop_trace, Opts}).

cluster_foreach(Msg) ->
    lists:foreach(
        fun({Node, Cookie, _Type}) ->
            pidbang_node(Node, Cookie, Msg)
        end, ets:tab2list(nodelist)
    ).
    
pidbang_node(Node, Cookie, Msg) ->
    whereis(goanna_sup:id(Node, Cookie)) ! Msg

%%------------------------------------------------------------------------

store_trace([trace, Node, Cookie],Trace) ->
    pidbang_node(Node, Cookie, {trace_item}),
    goanna_db:store([trace, Node, Cookie],Trace).