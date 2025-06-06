%% @author Marc Worrell <marc@worrell.nl>
%% @copyright 2009-2025 Marc Worrell
%% @doc Interfaces for command line utilities in zotonic_launcher, some
%% easy shortcuts and error logging functions.
%% @end

%% Copyright 2009-2025 Marc Worrell
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.

-module(z).
-author("Marc Worrell <marc@worrell.nl").

%% interface functions
-export([
    c/1,

    env/1,

    n/2,
    n1/2,
    m/0,
    compile/0,
    flush/0,
    restart/0,

    start/1,
    flush/1,
    restart/1,
    stop/1,

    open/1,
    open_secure/1,

    ld/0,
    ld/1,

    reindex/0,

    is_module_enabled/2,

    shell_stopsite/1,
    shell_startsite/1,
    shell_restartsite/1,

    dispatch_url/1,
    dispatch_path/2,
    dispatch_list/1,

    debug_msg/2,

    log/3,

    debug/2,
    debug/3,
    debug/4,
    info/2,
    info/3,
    info/4,
    notice/2,
    notice/3,
    notice/4,
    warning/2,
    warning/3,
    warning/4,
    error/2,
    error/3,
    error/4,
    fatal/2,
    fatal/3,
    fatal/4
]).

-include("zotonic.hrl").

%% DTAP environment
-type environment() :: development
                    | test
                    | acceptance
                    | production
                    | education
                    | backup.

-type context() :: #context{}.
-type validation_error() :: invalid | novalue | {script, iodata()} | novalidator | string().
-type trans() :: #trans{}.
-type qvalue() :: binary() | string() | #upload{} | term().

-type severity() :: debug | info | notice | warning | error | fatal.

-export_type([
    context/0,
    trans/0,
    environment/0,
    validation_error/0,
    severity/0,
    qvalue/0
]).

% @doc Return a new context
-spec c( atom() ) -> z:context().
c(Site) ->
    z_context:new(Site).

%% @doc Return the current environment
-spec env( Site :: atom() ) -> environment().
env(Site) ->
    m_site:environment(Site).

%% @doc Send an async notification.
n(Msg, Site) when is_atom(Site) ->
    n(Msg, c(Site));
n(Msg, Context) ->
    z_notifier:notify(Msg, Context).

%% @doc Send a notification to the first observer and return the result.
n1(Msg, Site) when is_atom(Site) ->
    n1(Msg, c(Site));
n1(Msg, Context) ->
    z_notifier:first(Msg, Context).

%% @doc (Re)make all erlang source modules and reset the caches.
m() ->
    case compile() of
        ok -> flush(), ok;
        Other -> Other
    end.

%% @doc (Re)make all erlang source modules with the supplied compile
%% options. Do not reset the caches.
compile() ->
    zotonic_filehandler:compile_all().

%% @doc Reset all caches, reload the dispatch rules and rescan all modules.
-spec flush() -> ok.
flush() ->
    zotonic_fileindexer:flush(),
    [ flush(C) || C <- z_sites_manager:get_site_contexts() ],
    z_sites_dispatcher:update_dispatchinfo().

-spec flush( atom() | z:context() ) -> ok.
flush(Site) when is_atom(Site) ->
    flush(c(Site));
flush(Context) ->
    z_depcache:flush(Context),
    z_dispatcher:reload(Context),
    n(module_ready, Context),
    ok.

%% @doc Reindex all sites, find new files.
reindex() ->
    zotonic_fileindexer:flush(),
    z_module_indexer:reindex().

%% @doc Check if a module of a site is enabled.
-spec is_module_enabled( Module :: atom(), Site :: atom() ) -> boolean().
is_module_enabled(Module, Site) ->
    z_module_manager:active(Module, c(Site)).

%% @doc Full restart of Zotonic
restart() ->
    application:stop(zotonic_core),
    application:start(zotonic_core).

%% @doc Start a site
start(Site) ->
    z_sites_manager:start(Site).

%% @doc Restart a site
restart(Site) ->
    z_sites_manager:restart(Site).

%% @doc Stop a site
stop(Site) ->
    z_sites_manager:stop(Site).

%% @doc Open a site in Chrome or the default browser(macOS)
open(Site) ->
    z_exec_browser:open(Site).

%% @doc Open a site in a new fresh Chrome
open_secure(Site) ->
    z_exec_browser:chrome(Site, [], #{ secure => true }).

%% @doc Reload all changed Erlang modules
ld() ->
    zotonic_filehandler:reload_modules().

%% @doc Reload an Erlang module
ld(Module) ->
    zotonic_filehandler:reload_module(Module).

%% @doc Shell commands: start a site
shell_startsite(Site) ->
    case z_sites_manager:get_site_status(Site) of
        {ok, running} ->
            running;
        {ok, _Status} ->
            z_sites_manager:start(Site);
        {error, bad_name} ->
            bad_name
    end.

%% @doc Shell commands: stop a site
shell_stopsite(Site) ->
    case z_sites_manager:get_site_status(Site) of
        {ok, stopped} ->
            stopped;
        {ok, _Status} ->
            z_sites_manager:stop(Site);
        {error, bad_name} ->
            bad_name
    end.

%% @doc Shell commands: stop a site
shell_restartsite(Site) ->
    z_sites_manager:stop(Site),
    shell_startsite(Site).

%% @doc Dispatch an URL - find matching site and dispatch the path
dispatch_url(Url) ->
    case uri_string:parse(Url) of
        #{ host := Host, path := Path } ->
            case z_sites_dispatcher:get_site_for_hostname(Host) of
                {ok, Site} ->
                    dispatch_path(Path, Site);
                undefined ->
                    case z_sites_dispatcher:get_fallback_site() of
                        {ok, FallbackSite} ->
                            dispatch_path(Path, FallbackSite);
                        undefined ->
                            {error, unknown_host}
                    end
            end;
        _ ->
            {error, url}
    end.

%% @doc Shell command: dispatch a path, return trace
dispatch_path(Path, Site) when is_atom(Site), is_binary(Path) ->
    case z_sites_manager:get_site_status(Site) of
        {ok, running} ->
            dispatch_path(Path, z_context:new(Site));
        {ok, Status} ->
            {error, Status};
        {error, bad_name} ->
            {error, bad_name}
    end;
dispatch_path(Path, #context{} = Context) when is_binary(Path) ->
    z_sites_dispatcher:dispatch_trace(Path, Context).

%% @doc Return the complete dispatch information for the site.
dispatch_list(SiteOrContext) ->
    case z_sites_dispatcher:fetch_dispatchinfo(SiteOrContext) of
        {ok, #site_dispatch_list{
                site=Site, hostname=Hostname, smtphost=SmtpHost, hostalias=Hostalias,
                redirect=Redirect, dispatch_list=DispatchList
            }} ->
            DL = lists:map(
                fun({Disp, Path, Controller, Opts}) ->
                    #{
                        dispatch => Disp,
                        path => Path,
                        controller => Controller,
                        controller_options => Opts
                    }
                end,
                DispatchList),
            {ok, #{
                site => Site,
                hostname => Hostname,
                smtphost => SmtpHost,
                hostalias => Hostalias,
                is_redirect => Redirect,
                dispatch_list => DL
            }};
        {error, _} = Error ->
            Error
    end.

%% @doc Echo and return a debugging value. This is useful for adding
%% debug anywhere in the code, as the passed argument is also returned.
%% Example: <tt>foo( ?DEBUG(Arg) )</tt> will add Arg as a notice to the logs
%% and still call  <tt>foo(Arg)</tt>.
debug_msg(Msg, Meta) ->
    logger:log(notice, "DEBUG: ~tp", [ Msg ], Meta),
    Msg.

%% @doc Log a debug message to the logs and the database, with extra meta data.
%% To add the current source location, use the <tt>?zDebug</tt> macro.
debug(Msg, Context)                 -> log(debug, Msg, #{}, Context).
debug(Msg, Meta, Context)           -> log(debug, Msg, Meta, Context).
debug(Format, Args, Meta, Context)  -> log(debug, Format, Args, Meta, Context).

%% @doc Log an informational message to the logs and the database, with extra meta data.
%% To add the current source location, use the <tt>?zInfo</tt> macro.
info(Msg, Context)                  -> log(info, Msg, #{}, Context).
info(Msg, Meta, Context)            -> log(info, Msg, Meta, Context).
info(Format, Args, Meta, Context)   -> log(info, Format, Args, Meta, Context).

%% @doc Log a  notice to the logs and the database, with extra meta data.
%% To add the current source location, use the <tt>?zNotice</tt> macro.
notice(Msg, Context)                -> log(notice, Msg, #{}, Context).
notice(Msg, Meta, Context)          -> log(notice, Msg, Meta, Context).
notice(Format, Args, Meta, Context) -> log(notice, Format, Args, Meta, Context).

%% @doc Log a warning to the logs and the database, with extra meta data.
%% To add the current source location, use the <tt>?zWarning</tt> macro.
warning(Msg, Context)              -> log(warning, Msg, #{}, Context).
warning(Msg, Meta, Context)        -> log(warning, Msg, Meta, Context).
warning(Format, Args, Meta, Context)->log(warning, Format, Args, Meta, Context).

%% @doc Log a error to the logs and the database, with extra meta data.
%% To add the current source location, use the <tt>?zError</tt> macro.
error(Msg, Context)                -> log(error, Msg, #{}, Context).
error(Msg, Meta, Context)          -> log(error, Msg, Meta, Context).
error(Format, Args, Meta, Context) -> log(error, Format, Args, Meta, Context).

%% @doc Log a fatal error to the logs and the database, with extra meta data.
%% To add the current source location, use the <tt>?zError</tt> macro.
fatal(Msg, Context)                -> log(fatal, Msg, #{}, Context).
fatal(Msg, Meta, Context)          -> log(fatal, Msg, Meta, Context).
fatal(Format, Args, Meta, Context) -> log(fatal, Format, Args, Meta, Context).


-spec log( Level::severity(), Format::string(), Args::list(),
           Meta::proplists:proplist() | map(), Context::z:context() ) -> ok.
log(Type, Format, Args, Meta, Context) when is_list(Args) ->
    Msg1 = lists:flatten(io_lib:format(Format, Args)),
    log(Type, Msg1, Meta, Context).

-spec log( Level::severity(), Meta::proplists:proplist() | map(), Context::z:context() ) -> ok.
log(Type, Meta, Context) ->
    log(Type, <<>>, Meta, Context).

-spec log( Level::severity(), Msg::iodata(), Meta::proplists:proplist() | map(), Context::z:context() ) -> ok.
log(Type, Msg, Meta, Context) when is_list(Meta) ->
    log(Type, Msg, maps:from_list(Meta), Context);
log(Type, Msg, Meta, Context) ->
    Line = maps:get(line, Meta, 0),
    UserId = case maps:get(user_id, Meta, none) of
        none -> z_acl:user(Context);
        UId -> UId
    end,
    LoggerMeta = #{
        site => z_context:site(Context),
        environment => m_site:environment(Context),
        line => Line,
        node => node(),
        user_id => UserId
    },
    LoggerMeta1 = case maps:get(mfa, Meta, undefined) of
        undefined ->
            LoggerMeta;
        {_, _, _} = MFA ->
            LoggerMeta#{ mfa => MFA }
    end,
    LoggerMeta2 = maps:merge(Meta, LoggerMeta1),
    Msg1 = unicode:characters_to_list(Msg),
    case Msg1 of
        "" -> logger:log(logger_level(Type), LoggerMeta2);
        _ -> logger:log(logger_level(Type), Msg1, LoggerMeta2)
    end,
    z_notifier:notify(
        #zlog{
            type = Type,
            user_id = UserId,
            timestamp = os:timestamp(),
            props = #log_message{
                type = Type,
                message = Msg1,
                props = maps:to_list(Meta),
                user_id = UserId
            }
        },
        Context),
    ok.

logger_level(fatal) -> alert;
logger_level(error) -> error;
logger_level(warning) -> warning;
logger_level(notice) -> notice;
logger_level(info) -> info;
logger_level(debug) -> debug.
