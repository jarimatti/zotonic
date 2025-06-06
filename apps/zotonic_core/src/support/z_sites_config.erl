%% @author Marc Worrell <marc@worrell.nl>
%% @copyright 2019-2025 Marc Worrell
%% @doc Load and manage site configuration files.
%% @end

%% Copyright 2019-2025 Marc Worrell
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

-module(z_sites_config).

-export([
    maybe_set_backup_env/1,
    maybe_unset_backup_env/1,

    site_config/1,
    app_is_site/1,
    config_files/1,
    config_files/2,
    security_dir/1,
    read_configs/1,
    merge_global_configs/3
    ]).

-define(CONFIG_FILE, "zotonic_site.*").


%% @doc Iff a site is running in backup environment, and its config files are
%% restored from a remote system, then the environment in the config file is
%% overwritten by the config from the remote environment. To keep the site in
%% backup environment, we write a file "priv/BACKUP". If this file is present
%% then it is hard-coded to set the environment to backup and the site to enabled.
-spec maybe_set_backup_env(Context) -> ok | {error, Reason} when
    Context :: z:context(),
    Reason :: term().
maybe_set_backup_env(Context) ->
    Site = z_context:site(Context),
    case app_is_site(Site) of
        true ->
            case m_site:environment(Context) of
                backup ->
                    case z_path:site_dir(Site) of
                        {error, _} = Error ->
                            Error;
                        SiteDir ->
                            Filename = filename:join([ SiteDir, "priv", "BACKUP" ]),
                            file:write_file(Filename, <<>>)
                    end;
                Other ->
                    {error, Other}
            end;
        false ->
            {error, nosite}
    end.

%% @doc Remove the priv/BACKUP file. After this the site will use the environment
%% from the config files.
-spec maybe_unset_backup_env(Context) -> ok | {error, Reason} when
    Context :: z:context(),
    Reason :: term().
maybe_unset_backup_env(Context) ->
    Site = z_context:site(Context),
    case app_is_site(Site) of
        true ->
            case z_path:site_dir(Site) of
                {error, _} = Error ->
                    Error;
                SiteDir ->
                    Filename = filename:join([ SiteDir, "priv", "BACKUP" ]),
                    case filelib:is_file(Filename) of
                        true ->
                            file:delete(Filename);
                        false ->
                            ok
                    end
            end;
        false ->
            {error, nosite}
    end.


-spec site_config(Site) -> {ok, Config} | {error, Reason} when
    Site :: atom(),
    Config :: map(),
    Reason :: term().
site_config(Site) when is_atom(Site) ->
    case app_is_site(Site) of
        true ->
            ConfigFiles = config_files(Site),
            ZotonicFiles = z_config_files:zotonic_config_files(),
            case read_configs(ConfigFiles) of
                {ok, SiteConfig} ->
                    case read_configs(ZotonicFiles) of
                        {ok, GlobalConfig} when is_map(GlobalConfig) ->
                            SiteConfig1 = merge_global_configs(Site, SiteConfig, GlobalConfig),
                            {ok, SiteConfig1};
                        {error, _} = Error ->
                            Error
                    end;
                {error, _} = Error ->
                    Error
            end;
        false ->
            {error, nosite}
    end.

%% @doc Check if the Erlang application is a Zotonic site. A Zotonic site has a site
%% configuration file in its priv directory.
-spec app_is_site( atom() ) -> boolean().
app_is_site(App) ->
    case site_config_file(App) of
        {error, _} -> false;
        Filename -> filelib:is_regular(Filename)
    end.

%% @doc Return the main configuration file for a site
-spec site_config_file( atom() ) -> file:filename_all() | {error, bad_name}.
site_config_file(Site) ->
    case z_path:site_dir(Site) of
        {error, _} = Error ->
            Error;
        SiteDir ->
            Files = filelib:wildcard( filename:join([ SiteDir, "priv", ?CONFIG_FILE ]) ),
            Files1 = lists:filter(
                fun(F) ->
                    case filename:extension(F) of
                        ".config" -> true;
                        ".yaml" -> true;
                        ".yml" -> true;
                        ".json" -> true;
                        _ -> false
                    end
                end,
                Files),
            case Files1 of
                [] -> {error, bad_name};
                [ File | _ ] -> File
            end
    end.

-spec config_files( atom() ) -> list( file:filename_all() ).
config_files( Site ) ->
    config_files( node(), Site ).

-spec config_files( node(), atom() ) -> list( file:filename_all() ).
config_files(Node, Site) ->
    case site_config_file(Site) of
        {error, _} ->
            [];
        ConfigFile ->
            SitePrivDir = filename:dirname(ConfigFile),
            case z_config_files:config_dir(Node) of
                {ok, ConfigDir} ->
                    [ ConfigFile ]
                    ++ z_config_files:files( filename:join([ ConfigDir, "site_config.d", Site ]) )
                    ++ z_config_files:files( filename:join([ SitePrivDir, "config.d" ]) )
                    ++ maybe_backup( filename:join([ SitePrivDir, "BACKUP" ]) );
                {error, _} ->
                    [ ConfigFile ]
                    ++ z_config_files:files( filename:join([ SitePrivDir, "config.d" ]) )
                    ++ maybe_backup( filename:join([ SitePrivDir, "BACKUP" ]) )
            end
    end.

maybe_backup(F) ->
    case filelib:is_file(F) of
        true -> [ "BACKUP" ];
        false -> []
    end.

-spec security_dir( atom() ) -> {ok, file:filename_all()} | {error, term()}.
security_dir(Site) ->
    case z_config_files:security_dir() of
        {ok, SecurityDir} ->
            {ok, filename:join( SecurityDir, Site)};
        {error, _}=Error ->
            Error
    end.

-spec read_configs( [ file:filename_all() ] ) -> {ok, map()} | {error, term()}.
read_configs(Fs) when is_list(Fs) ->
    lists:foldl(
        fun
            (_, {error, _} = Error) ->
                Error;
            ("BACKUP", {ok, Acc}) ->
                Data = #{
                    environment => backup,
                    enabled => true
                },
                apps_config("BACKUP", [ Data ], Acc);
            (F, {ok, Acc}) ->
                case z_config_files:consult(F) of
                    {ok, Data} ->
                        apps_config(F, Data, Acc);
                    {error, _} = Error ->
                        Error
                end
        end,
        {ok, #{}},
        Fs).

apps_config(_File, [], Cfgs) ->
    % Skip config file with no definitions in it.
    {ok, Cfgs};
apps_config(File, Data, Cfgs) when is_list(Data) ->
    lists:foldl(
        fun
            (AppConfig, Acc) when is_map(AppConfig) ->
                maps:fold(
                    fun
                        (Key, Cfg, {ok, MAcc}) ->
                            {ok, MAcc#{ Key => Cfg }};
                        (_Key, _Cfg, {error, _} = Error) ->
                            Error
                    end,
                    {ok, Acc},
                    AppConfig);
            (AppConfig, Acc) when is_list(AppConfig) ->
                lists:foldl(
                    fun
                        ({Key, Cfg}, {ok, MAcc}) ->
                            {ok, MAcc#{ Key => Cfg }};
                        (Key, {ok, MAcc}) when is_atom(Key) ->
                            {ok, MAcc#{ Key => true }};
                        (Other, {ok, _}) ->
                            {error, {config_file, format, File, {unknown_term, Other}}};
                        (_, {error, _} = Error) ->
                            Error
                    end,
                    {ok, Acc},
                    AppConfig);
            (null, Acc) ->
                % Skip null, this is probably a yml file with a comment.
                {ok, Acc};
            (Term, _Acc) ->
                {error, {config_file, format, File, {unknown_term, Term}}}
        end,
        Cfgs,
        Data).

%% @doc Merge the global config options into the site's options, adding defaults.
-spec merge_global_configs(Sitename, SiteConfig, GlobalConfig) -> MergedConfig when
    Sitename :: atom(),
    SiteConfig :: map(),
    GlobalConfig :: map(),
    MergedConfig :: map().
merge_global_configs( Sitename, SiteConfig, GlobalConfig ) when is_map(SiteConfig), is_map(GlobalConfig) ->
    ZotonicConfig = case maps:get(zotonic, GlobalConfig, #{}) of
        L when is_list(L) -> L;
        M when is_map(M) -> maps:to_list(M)
    end,
    DbOptions = z_db_pool:database_options( Sitename, maps:to_list(SiteConfig), ZotonicConfig ),
    maps:merge(SiteConfig, maps:from_list(DbOptions)).
