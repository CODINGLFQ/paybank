%% -------------------------------------------------------------------
%%
%% Copyright (c) 2011 Andrew Tunnell-Jones. All Rights Reserved.
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
%% @private
-module(cutkey_drv).

-export([load/0, open/0, close/1, gen_rsa/4]).

-define(DRIVER_NAME, ?MODULE_STRING).

-define(DRV_CMD_INFO, 0).
-define(DRV_CMD_RSA,  1).

load() ->
    {ok, Drivers} = erl_ddll:loaded_drivers(),
    case lists:member(?DRIVER_NAME, Drivers) of
	true -> ok;
	false ->
	    case erl_ddll:load(priv_dir(), ?DRIVER_NAME) of
		ok -> ok;
		{error, Error} ->
		    error_logger:error_msg(
		      ?MODULE_STRING ": Error loading ~p: ~p~n",
		      [?DRIVER_NAME, erl_ddll:format_error(Error)]
		     ),
		    {error, Error}
	    end
    end.

priv_dir() ->
    case code:priv_dir(cutkey) of
	List when is_list(List) -> List;
	{error, bad_name} ->
	    filename:join(filename:dirname(code:which(?MODULE)), "../priv")
    end.

open() ->
    try erlang:open_port({spawn_driver, ?DRIVER_NAME}, [binary])
    catch error:badarg ->
	    case load() of
		ok -> erlang:open_port({spawn_driver, ?DRIVER_NAME}, [binary]);
		{error, _Reason} = Error -> Error
	    end
    end.

close(Port) when is_port(Port) ->
    try erlang:port_close(Port), ok
    catch error:badarg -> ok end.

gen_rsa(Port, Ref, Bits, E)
  when is_port(Port) andalso is_integer(Ref) andalso
       is_integer(Bits) andalso Bits > 0 andalso
       E band 1 =:= 1 ->
    erlang:port_call(Port, ?DRV_CMD_RSA, {Ref, Bits, E}).
