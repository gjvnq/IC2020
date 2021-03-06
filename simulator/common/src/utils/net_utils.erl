% Copyright (C) 2007-2017 Olivier Boudeville
%
% This file is part of the Ceylan Erlang library.
%
% This library is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License or
% the GNU General Public License, as they are published by the Free Software
% Foundation, either version 3 of these Licenses, or (at your option)
% any later version.
% You can also redistribute it and/or modify it under the terms of the
% Mozilla Public License, version 1.1 or later.
%
% This library is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
% GNU Lesser General Public License and the GNU General Public License
% for more details.
%
% You should have received a copy of the GNU Lesser General Public
% License, of the GNU General Public License and of the Mozilla Public License
% along with this library.
% If not, see <http://www.gnu.org/licenses/> and
% <http://www.mozilla.org/MPL/>.
%
% Authors:	Olivier Boudeville (olivier.boudeville@esperide.com)
%			Samuel Thiriot (samuel.thiriot@edf.fr)
%
% Creation date: July 1, 2007.



% Gathering of various convenient net-related facilities.
%
% See net_utils_test.erl for the corresponding test.
%
-module(net_utils).



% Host-related functions.
-export([ ping/1, localhost/0, localhost/1,
		  get_local_ip_addresses/0, get_local_ip_address/0, reverse_lookup/1 ]).


% Node-related functions.
-export([ localnode/0, get_all_connected_nodes/0,
		  check_node_availability/1, check_node_availability/2,
		  get_node_naming_mode/0, get_naming_compliant_hostname/2,
		  generate_valid_node_name_from/1, get_fully_qualified_node_name/3,
		  launch_epmd/0, launch_epmd/1, enable_distribution/2,
		  get_cookie/0, set_cookie/1, set_cookie/2,
		  shutdown_node/0, shutdown_node/1 ]).


% Net-related command line options.
-export([ get_cookie_option/0, get_epmd_environment/1, get_node_name_option/2,
		  get_tcp_port_range_option/1, get_basic_node_launching_command/5 ]).


% Net-related transfers.
-export([ send_file/2, receive_file/1, receive_file/2, receive_file/3 ]).


% Address-related functions.
-export([ is_routable/1 ]).


% Stringifications:
-export([ ipv4_to_string/1, ipv4_to_string/2,
		  ipv6_to_string/1, ipv6_to_string/2,
		  host_to_string/1, url_info_to_string/1 ]).


% Destringifications:
-export([ string_to_url_info/1 ]).


% Exported for convenience:
-export([ wait_unavailable/3 ]).


% Type declarations.

-type ip_v4_address() :: { byte(), byte(), byte(), byte() }.
-type ip_v6_address() :: { byte(), byte(), byte(), byte(), byte(), byte() }.

-type ip_address() :: ip_v4_address() | ip_v6_address().


% We tend to favor atom-based node names (usual in Erlang) to string-based ones:
-type atom_node_name()   :: node().

-type string_node_name() :: nonempty_string().


-type node_name()        :: atom_node_name() | string_node_name().

% See net_kernel:monitor_nodes/2 for more information:
-type node_type() :: 'visible' | 'hidden' | 'all'.


-type atom_host_name()   :: atom().
-type string_host_name() :: nonempty_string().
-type host_name()        :: atom_host_name() | string_host_name().

-type host_identifier() :: string_host_name() | ip_address().


-type check_duration()    :: non_neg_integer().
-type check_node_timing() :: check_duration() | 'immediate' | 'with_waiting'.

-type node_naming_mode() :: 'long_name' | 'short_name'.

-type cookie() :: atom().


-type net_port() :: non_neg_integer().
-type tcp_port() :: net_port().
-type udp_port() :: net_port().

-type tcp_port_range() :: { tcp_port(), tcp_port() }.
-type udp_port_range() :: { udp_port(), udp_port() }.


% The possible protocols for an URL:
%
-type protocol_type() :: 'http' | 'https' | 'ftp'.



% Path of an URL (ex: 'access/login'):
%
-type path() :: string().


-include("net_utils.hrl").


% Full information about an URL:
-type url_info() :: #url_info{}.

% An URL:
-type url() :: string().


-export_type([ ip_v4_address/0, ip_v6_address/0, ip_address/0,
			   atom_node_name/0, string_node_name/0, node_name/0, node_type/0,
			   atom_host_name/0, string_host_name/0, host_name/0,
			   host_identifier/0,
			   check_duration/0, check_node_timing/0,
			   node_naming_mode/0, cookie/0,
			   net_port/0, tcp_port/0, udp_port/0,
			   tcp_port_range/0, udp_port_range/0,
			   protocol_type/0, path/0, url_info/0, url/0 ]).


% For the file_info record:
-include_lib("kernel/include/file.hrl").



% Host-related functions.


% Pings specified hostname, and returns true iff it could be ping'd.
%
% Note: command-line based call, used that way as there is no ICMP stack.
%
% A port could be used also.
%
-spec ping( string_host_name() ) -> boolean().
ping( Hostname ) when is_list( Hostname ) ->

	Command = "/bin/ping " ++ Hostname ++ " -q -c 1 ",

	%io:format( "Ping command: ~s~n.", [ Command ] ),

	case system_utils:run_executable( Command ) of

		{ _ExitCode=0, _Output } ->
			true;

		{ _ExitCode, _Output } ->
			false

	end.



% Returns an appropriate DNS name for the local host (as a string), or throws an
% exception.
%
% Tries to collect a FQDN (Fully Qualified Domain Name).
%
-spec localhost() -> string_host_name().
localhost() ->
	localhost( fqdn ).



% Returns an appropriate DNS name (either a FQDN - Fully Qualified Domain Name -
% or a short host name) for the local host (as a string), or throws an
% exception.
%
-spec localhost( 'fqdn' | 'short' ) -> string_host_name().
localhost( fqdn ) ->

	% Depending on the node being launched with either:
	%
	%  - no network name or a short name
	%  - a long name
	% net_adm:localhost() may return respectively "XXX.domain.com" or
	% "XXX.localdomain", both of which are not proper hostnames.
	%
	% On the other hand, "hostname -f" might return 'localhost.localdomain' or
	% even "hostname: Name or service not known" if there are issues in terms of
	% name resolution.

	% Most reliable:
	case system_utils:run_executable( "hostname -f" ) of

		{ _ExitCode=0, _Output="localhost" } ->
			localhost_last_resort();

		{ _ExitCode=0, _Output="localhost.localdomain" } ->
			localhost_last_resort();

		{ _ExitCode=0, Output } ->
			% Must be legit:
			Output;

		{ _ExitCode, _Output } ->
			localhost_last_resort()

	end;


% Returns the host name by itself (at least attempts to do so):
%
localhost( short ) ->

	FQDN = localhost( fqdn ),

	% So that for example "tesla.esperide.com" becomes "tesla":
	hd( string:tokens( FQDN, "." ) ).




% Helper:
-spec localhost_last_resort() -> string_host_name().
localhost_last_resort() ->

	case system_utils:run_executable( "hostname" ) of

		{ _ExitCode=0, _Output="localhost" } ->
			throw( could_not_determine_localhost );


		{ _ExitCode=0, _Output="localhost.localdomain" } ->
			throw( could_not_determine_localhost );


		{ _ExitCode=0, Output } ->
			% Must be legit:
			Output;

		{ ExitCode, Output } ->
			throw( { could_not_determine_localhost, ExitCode, Output } )

	end.



% Returns a list of the potentially usable non-local network interfaces on this
% host, trying to put in first position the "main" one, if any.
%
% Note: IPv6 support should be added.
%
-spec get_local_ip_addresses() -> [ ip_v4_address() ].
get_local_ip_addresses() ->

	IfList = case inet:getifaddrs() of

				 { ok, List } ->
					 List;

				 { error, Reason } ->
					 throw( { local_ip_look_up_failed, Reason } )

	end,

	%io:format( "Interface list:~n~p~n", [ IfList ] ),

	% Rules: put non-routable (network-local) interfaces last (including
	% loopback, i.e. "lo", which must be the very last one), try to put routable
	% "ethX"-like interfaces first, virtual interfaces (ex: "vmnetX")
	% last. Keeps only the actual address (addr).

	% More convenient than a queue:
	filter_interfaces( IfList, _FirstIfs=[], _LastIfs=[], _Loopback=undefined ).


% (helper)
filter_interfaces( _IfList=[], FirstIfs, LastIfs, _Loopback=undefined ) ->
	% No loopback here; quite surprising:
	filter_routable_first( FirstIfs ) ++ filter_routable_first( LastIfs );

filter_interfaces( _IfList=[], FirstIfs, LastIfs, Loopback ) ->
	% We need loopback never to take precedence over any other interface:
	filter_routable_first( FirstIfs ) ++ filter_routable_first( LastIfs )
		++ [ Loopback ];

filter_interfaces( _IfList=[ _If={ Name, Options } | T ], FirstIfs, LastIfs,
				   Loopback ) ->

	%io:format( "Examining interface named '~p', with options ~p.~n",
	%		   [ Name, Options ] ),

	case proplists:get_value( _K=addr, Options ) of

		% Ex: wlan0 might not have a configured address if down:
		undefined ->
			filter_interfaces( T, FirstIfs, LastIfs, Loopback );

		Address ->

			case Name of

				% Assuming up to one loopback, replacing any previous one:
				"lo" ->
					filter_interfaces( T, FirstIfs, LastIfs, Address );

				% For example, eth1:
				"eth" ++ _ ->
					filter_interfaces( T, [ Address | FirstIfs ], LastIfs,
									   Loopback );

				% For example, enp0s25:
				"enp" ++ _ ->
					filter_interfaces( T, [ Address | FirstIfs ], LastIfs,
									   Loopback );

				% Ex: vmnetX, etc.
				_ ->
					filter_interfaces( T, FirstIfs, [ Address | LastIfs ],
									   Loopback )

			end

	end.



% (helper)
filter_routable_first( IfList ) ->
	filter_routable_first( IfList, _RoutableAddrs=[], _NonRoutableAddrs=[] ).


filter_routable_first( _IfList=[], RoutableAddrs, NonRoutableAddrs ) ->
	RoutableAddrs ++ NonRoutableAddrs;

filter_routable_first( _IfList= [ If | T ], RoutableAddrs, NonRoutableAddrs ) ->

	case is_routable( If ) of

		true ->
			filter_routable_first( T, [ If | RoutableAddrs ],
								   NonRoutableAddrs );

		false ->
			filter_routable_first( T, RoutableAddrs, [ If | NonRoutableAddrs ] )

	end.




% Returns the "main" potentially usable non-local network interface on this
% host.
%
-spec get_local_ip_address() -> ip_v4_address().
get_local_ip_address() ->

	case get_local_ip_addresses() of

		[] ->
			throw( no_local_ip_address_established );

		% In some cases, the user wants to select another network interface than
		% the selected one:

		%[ _FirstAddr, SecondAddr | _T ] ->
		%       SecondAddr;

		[ Addr | _T ] ->
				Addr

	end.



% Returns a string specifying the DNS name corresponding to the specified IPv4
% address { N1, N2, N3, N4 }.
%
-spec reverse_lookup( ip_v4_address() ) -> string_host_name() | 'unknown_dns'.
reverse_lookup( IPAddress ) ->

	% Note that the 'host' command is not available on all systems ('dig',
	% 'drill', 'nslookup') might be:
	%
	case executable_utils:lookup_executable( "host" ) of

		false ->
			case executable_utils:lookup_executable( "drill" ) of

				false ->
					case executable_utils:lookup_executable( "dig" ) of
						false ->
							throw( { executables_not_found,
									 [ "host", "drill", "dig" ] } );

						DigPath ->
							reverse_lookup_with_dig_like( IPAddress, DigPath )

					end;

				DrillPath ->
					reverse_lookup_with_dig_like( IPAddress, DrillPath )

			end;

		HostPath ->
			reverse_lookup_with_host( IPAddress, HostPath )

	end.



% (helper using dig-like commands, i.e. the 'drill'/'dig' ones)
%
reverse_lookup_with_dig_like( IPAddress, DigLikeCmd ) ->

	% We remove empty lines and comments (lines starting with ';;') and extract
	% the host name:
	%
	Cmd = DigLikeCmd ++ " -x " ++ ipv4_to_string( IPAddress )
		++ " | grep -v '^;;' | grep PTR | sed 's|.*PTR\t||1'"
		++ " | sed 's|\.$||1' 2>/dev/null",

	% Following could let non-PTR answers with '900 IN SOA' slip through:
	%
	%Cmd = DigLikeCmd ++ " -x " ++ ipv4_to_string( IPAddress )
	%	++ " | grep . | grep -v '^;;' | sed 's|.*PTR\t||1' | "
	%	++ "sed 's|\.$||1' 2>/dev/null",

	% Alternatively, could have along the lines of:
	%
	% case system_utils:run_executable( Cmd ) of
	%
	%           CleanedResult = text_utils:remove_whitespaces( Output ),
	%
	%			case string:tokens( CleanedResult, "PTR" ) of
	%
	%			[ _Prefix, DomainPlusDot ] ->
	%				% There is a trailing dot:
	%				text_utils:remove_last_characters( DomainPlusDot,
	%												   _Count=1 );
	%
	%			_Other  ->
	%				unknown_dns
	%
	%		end;
	%
	% (however was not really elegant and a leading tabulation was remaining at
	% least in some cases)

	case system_utils:run_executable( Cmd ) of

		{ _ExitCode=0, _Output="" } ->
			unknown_dns;

		{ _ExitCode=0, Output } ->
			Output;

		{ _ExitCode, _ErrorOutput } ->
			%throw( { reverse_lookup_failed, IPAddress, ExitCode,
			%		   ErrorOutput } )
			unknown_dns

	end.



% (helper using the 'host' command)
%
reverse_lookup_with_host( IPAddress, HostCmd ) ->

	Cmd = HostCmd ++ " -W 1 " ++ ipv4_to_string( IPAddress ) ++ " 2>/dev/null",

	case system_utils:run_executable( Cmd ) of

		{ _ExitCode=0, Output } ->

			%io:format( "'host' command: ~s, result: ~s.~n", [ Cmd, Output ] ),

			case string:tokens( Output, " " ) of

				[ _ArpaString, "domain", "name", "pointer", Domain ] ->
					% There is a trailing dot:
					text_utils:remove_last_characters( Domain, _Count=1 );

				_Other  ->
					unknown_dns

			end;

			{ _ExitCode, _ErrorOutput } ->
				%throw( { reverse_lookup_failed, IPAddress, ExitCode,
				%		   ErrorOutput } )
				unknown_dns

	end.





% Node-related functions.


% Returns the name of the local node, as an atom.
%
% It is either a specific node name, or the atom 'local_node' (preferred to
% 'nonode@nohost') - which unfortunately are both atoms...
%
-spec localnode() -> atom_node_name() | 'local_node'.
localnode() ->

	case node() of

		nonode@nohost ->
			local_node;

		OtherNodeName ->
			% Could be 'XX@myhost.example.com':
			OtherNodeName

	end.



% Returns the list of all connected nodes (each being designated by an atom,
% like 'foo@bar.org'), including the local node.
%
-spec get_all_connected_nodes() -> [ atom_node_name() ].
get_all_connected_nodes() ->
	[ node() | nodes() ].



% Returns immediately whether the specified Erlang node is found available.
%
% Nodename can be an atom or a string.
%
-spec check_node_availability( node_name() ) -> boolean().
check_node_availability( Nodename ) when is_list( Nodename ) ->
	check_node_availability( list_to_atom( Nodename ) );

check_node_availability( Nodename ) when is_atom( Nodename ) ->

	% Useful to troubleshoot longer ping durations:
	% (apparently this may come from badly configured DNS)
	%trace_utils:debug_fmt( "Pinging node '~s'...~n", [ Nodename ] ),

	case net_adm:ping( Nodename ) of

		pong ->
			%trace_utils:debug_fmt(
			%   "... node '~s' found available from node '~s'.",
			%	[ Nodename, node() ] ),
			true ;

		pang ->
			%trace_utils:debug_fmt(
			%   "... node '~s' found NOT available from node '~s'.",
			%	[ Nodename, node() ] ),
			false

	end.



% Defining initial and upper bound to waiting durations for node look-up:
-define( check_node_first_waiting_step, 20 ).
-define( check_node_max_waiting_step, 2000 ).



% Tells whether the specified Erlang node is available: returns
% {IsAvailable,Duration} where IsAvailable is a boolean and Duration is the
% number of milliseconds that was used to determine it.
%
% Parameters:
%
% - Nodename is an atom or a string corresponding to the name of the target node
%
% - Timing is either 'immediate', 'with_waiting' or a positive number of
% attempts with exponential back-off:
%
%   - if 'immediate', the target node will be deemed available or not, as soon
%   as the first and only ping attempted returns a result
%
%   - if 'with_waiting', a fixed, default number of attempts with some
%   exponential waiting in-between will be performed, for a standard duration
%
%   - if it is an integer, it will be used as a duration, i.e. the number of
%   milliseconds to be waited for, based on look-ups to be made with exponential
%   waiting in-between until a threshold duration is reached; this checking
%   should last no less than the specified duration, and not much more
%
% This is useful so that, if the node is being launched in the background, it is
% waited for while returning as soon as possible.
%
-spec check_node_availability( node_name(), check_node_timing() ) ->
									 { boolean(), check_duration() }.
check_node_availability( Nodename, Timing ) when is_list( Nodename ) ->
	check_node_availability( list_to_atom( Nodename ), Timing ) ;


check_node_availability( Nodename, _Timing=immediate ) ->

	IsAvailable = check_node_availability( Nodename ),
	{ IsAvailable, _Duration=0 };


check_node_availability( Nodename, _Timing=with_waiting )
  when is_atom( Nodename ) ->

	%io:format( "check_node_availability of node '~s' with default waiting.~n",
	%		   [ Nodename ] ),

	% 3 seconds is a good default:
	check_node_availability( Nodename, _Duration=3000 );


check_node_availability( Nodename, Duration )  ->

	% In all cases, start with one immediate look-up:
	%io:format( "Pinging '~s' (case A) now...", [ Nodename ] ),
	case net_adm:ping( Nodename ) of

		pong ->

			%io:format( " - node '~s' found directly available.~n",
			%		   [ Nodename ] ),

			{ true, 0 } ;

		pang ->

			%io:format( " - node '~s' not yet found available.~n",
			%		   [ Nodename ] ),

			% Hopefully too early, let's retry later:
			check_node_availability( Nodename,
				_CurrentDurationStep=?check_node_first_waiting_step,
				_ElapsedDuration=0,
				_SpecifiedMaxDuration=Duration )

	end.



% Helper function for the actual waiting:
check_node_availability( Nodename, CurrentDurationStep, ElapsedDuration,
						 SpecifiedMaxDuration )
  when ElapsedDuration < SpecifiedMaxDuration ->

	% Still on time here, apparently.

	% Avoid going past the deadline:
	RemainingDuration = SpecifiedMaxDuration - ElapsedDuration,

	ActualDurationStep = erlang:min( CurrentDurationStep, RemainingDuration ),

	%io:format( "check_node_availability: actual step is ~B ms, "
	%			"elapsed is ~B ms, for a specified duration of ~B ms.~n",
	%			[ ActualDurationStep, ElapsedDuration, SpecifiedMaxDuration ] ),

	% By design we are directly following a ping attempt:
	timer:sleep( ActualDurationStep ),

	NewElapsedDuration = ElapsedDuration + ActualDurationStep,

	%io:format( "Pinging '~s' (case B) now...", [ Nodename ] ),
	case net_adm:ping( Nodename ) of

		pong ->
			%io:format( " - node '~s' found available after ~B ms.~n",
			%			[ Nodename, NewElapsedDuration ] ),

			{ true, NewElapsedDuration } ;

		pang ->

			%io:format( " - node '~s' NOT found available after ~B ms.~n",
			%			[ Nodename, NewElapsedDuration ] ),

			% Too early, let's retry later:
			NewCurrentDurationStep = erlang:min( 2 * CurrentDurationStep,
												 ?check_node_max_waiting_step ),

			check_node_availability( Nodename, NewCurrentDurationStep,
									 NewElapsedDuration, SpecifiedMaxDuration )

	end;


% Already too late here (ElapsedDuration >= SpecifiedMaxDuration):
check_node_availability( _Nodename, _CurrentDurationStep, ElapsedDuration,
						 _SpecifiedMaxDuration ) ->

	%io:format( " - node '~s' found NOT available, after ~B ms.~n",
	%		   [ Nodename, ElapsedDuration ] ),

	{ false, ElapsedDuration }.



% Returns the naming mode of this node, either 'short_name' or 'long_name'.
-spec get_node_naming_mode() -> node_naming_mode().
get_node_naming_mode() ->

	% We determine the mode based on the returned node name:
	% (ex: 'foo@bar' vs 'foo@bar.baz.org')
	%
	[ _Node, Host ] = string:tokens( atom_to_list( node() ), "@" ),
	case length( string:tokens( Host, "." ) ) of

		1 ->
			short_name;

		TwoOrMore when TwoOrMore > 1 ->
			long_name

	end.



% Returns a transformed version (as a string) of the specified hostname (itself
% specified as a string) so that it is compliant with the specified node naming
% convention.
%
% For example, if the short_name convention is specified, then a "bar.baz.org"
% hostname will result into "bar".
%
-spec get_naming_compliant_hostname( string_host_name(), node_naming_mode() )
								   -> string_host_name().
get_naming_compliant_hostname( Hostname, short_name ) ->
	hd( string:tokens( Hostname, "." ) );

get_naming_compliant_hostname( Hostname, long_name ) ->
	Hostname.



% Returns a name (as a string) that is a legal name for an Erlang node, forged
% from the specified name.
%
-spec generate_valid_node_name_from( iolist() ) -> string_node_name().
generate_valid_node_name_from( Name ) when is_list( Name ) ->

	% Replaces each series of spaces (' '), lower than ('<'), greater than
	% ('>'), comma (','), left ('(') and right (')') parentheses, single (''')
	% and double ('"') quotes, forward ('/') and backward ('\') slashes,
	% ampersand ('&'), tilde ('~'), sharp ('#'), at sign ('@'), all other kinds
	% of brackets ('{', '}', '[', ']'), pipe ('|'), dollar ('$'), star ('*'),
	% marks ('?' and '!'), plus ('+'), other punctation signs (';', '.' and ':')
	% by exactly one underscore:
	%
	% (see also: file_utils:convert_to_filename/1)
	re:replace( lists:flatten( Name ),
				"( |<|>|,|\\(|\\)|'|\"|/|\\\\|\&|~|"
				"#|@|{|}|\\[|\\]|\\||\\$|\\*|\\?|!|\\+|;|\\.|:)+", "_",
				[ global, { return, list } ] ).



% Returns the full name of a node (as a string), which has to be used to target
% it from another node, with respect to the specified node naming conventions.
%
% Ex: for a node name "foo", a hostname "bar.org", with short names, we may
% specify "foo@bar" to target the corresponding node with these conventions (not
% a mere "foo", neither "foo@bar.org").
%
-spec get_fully_qualified_node_name( string_node_name(),
		string_host_name(), node_naming_mode() ) -> atom_node_name().
get_fully_qualified_node_name( NodeName, Hostname, NodeNamingMode ) ->

	StringNodeName = NodeName ++ "@"
		++ get_naming_compliant_hostname( Hostname, NodeNamingMode ),

	text_utils:string_to_atom( StringNodeName ).



% Launches as a daemon (in the background) an EPMD instance on the Erlang
% standard port, if needed.
%
% If an EPMD instance is already launched for that port, no extra instance will
% be launched, the former one remaining the active one; there is up to one EPMD
% instance per port.
%
-spec launch_epmd() -> basic_utils:void().
launch_epmd() ->
	launch_epmd( _StandardPort=4369 ).



% Launches as a daemon (in the background) an EPMD instance on the specified
% port, if needed.
%
% If an EPMD instance is already launched for that port, no extra instance will
% be launched, the former one remaining the active one; there is up to one EPMD
% instance per port.
%
-spec launch_epmd( net_port() ) -> basic_utils:void().
launch_epmd( Port ) when is_integer( Port ) ->

	case executable_utils:lookup_executable( "epmd" ) of

		false ->
			throw( { unable_to_launch_epmd, executable_not_found } );

		EPMDPath ->
			% Better through command line than using the environment to specify
			% the port:
			EpmdCmd = text_utils:format( "~s -port ~B", [ EPMDPath, Port ] ),
			%io:format( "Launching EPMD thanks to '~s'.~n", [ EpmdCmd ] ),
			system_utils:run_background_executable( EpmdCmd )

	end.



% Enables the distribution on the current node, supposedly not already
% distributed (otherwise the operation will fail).
%
% Note: an EPMD instance is expected to be already running; see
% launch_epmd/{0,1} in this module for that; apparently no race condition
% happens, hence initially no need for a wait-and-retry mechanism was seen here.
%
% Otherwise following messages might be output:
%  - 'Protocol: "inet_tcp": register/listen error: econnrefused'
%  - '{distribution_enabling_failed,foobar,long_name,{{shutdown,
%         {failed_to_start_child,net_kernel,{'EXIT',nodistribution}}},...
%
% In some cases yet (first time an Erlang program is run after boot?), a
% distribution_enabling_failed exception is raised, like in:
%
% {"init terminating in do_boot",{{nocatch,{distribution_enabling_failed,
% 'A_NODE_NAME',long_name,{{{shutdown,{failed_to_start_child,net_kernel,
% {'EXIT',nodistribution}}},{child,undefined,net_sup_dynamic,
% {erl_distribution,start_link,[['A_NODE_NAME',longnames],false]},permanent,
% 1000,supervisor,[erl_distribution]}},'nonode@nohost'}}},[...]
%
% This does not seem to be linked to a race condition with EPMD, as killing EPMD
% and re-running the program does not fail anymore.
%
% So a (tiny) second-chance mechanism has been introduced.
%
-spec enable_distribution( node_name(), node_naming_mode() ) ->
								 basic_utils:void().
enable_distribution( NodeName, NamingMode ) when is_list( NodeName ) ->
	AtomNodeName = text_utils:string_to_atom( lists:flatten( NodeName ) ),
	enable_distribution( AtomNodeName, NamingMode );

enable_distribution( NodeName, NamingMode=long_name )
  when is_atom( NodeName ) ->
	enable_distribution_helper( NodeName, longnames, NamingMode,
								_RemainingAttempts=5 );

enable_distribution( NodeName, NamingMode=short_name )
  when is_atom( NodeName ) ->
	enable_distribution_helper( NodeName, shortnames, NamingMode,
								_RemainingAttempts=5 ).



% NamingMode kept for error message.
%
% (helper)
%
enable_distribution_helper( NodeName, NameType, NamingMode,
							RemainingAttempts ) ->

	%io:format( "Starting distribution for node name ~s, as '~w'.~n",
	%		   [ NodeName, NameType ] ),

	case net_kernel:start( [ NodeName, NameType ] ) of

		{ error, Reason } ->

			case RemainingAttempts of

				0 ->
					ExtraReason = case net_kernel:stop() of

						ok ->
							{ was_distributed, node(), Reason };

						{ error, not_allowed } ->
							{ not_allowed, node(), Reason };

						{ error, not_found } ->
							{ extra_reason, node(), Reason }

					end,

					throw( { distribution_enabling_failed, NodeName, NamingMode,
							 ExtraReason } );

				N ->
					io:format( "(attempt of enabling ~p distribution for "
							   "node '~s' failed, retrying...)~n",
							   [ NamingMode, NodeName ] ),
					timer:sleep( 300 ),
					enable_distribution_helper( NodeName, NameType, NamingMode,
												N - 1 )

			end;

		%{ ok, _NetKernelPid } ->
		R ->
			R

	end.



% Returns the Erlang cookie of the current node if that node is alive, otherwise
% the 'nocookie' atom.
%
-spec get_cookie() -> cookie() | 'nocookie'.
get_cookie() ->
	erlang:get_cookie().



% Sets the Erlang cookie for the current node, as well as for the one of all
% unknown nodes.
%
-spec set_cookie( cookie() ) -> basic_utils:void().
set_cookie( Cookie ) ->

	case erlang:is_alive() of

		true ->
			set_cookie( Cookie, node() );

		false ->
			throw( local_node_not_alive )

	end.



% Sets the Erlang cookie for the specified node.
%
-spec set_cookie( cookie(), atom_node_name() ) -> basic_utils:void().
set_cookie( Cookie, Node ) ->
	erlang:set_cookie( Node, Cookie ).



% Shutdowns current node, and never returns (unlike init:stop/0): it is a
% reliable and synchronous operation.
%
% Throws an exception if not able to terminate it.
%
-spec shutdown_node() -> no_return().
shutdown_node() ->

	init:stop(),

	timer:sleep( 5000 ),

	shutdown_node().



% Shutdowns specified node (specified as a string or an atom), and returns only
% when it cannot be ping'ed anymore: it is a reliable and synchronous operation.
%
% Throws an exception if not able to terminate it.
%
-spec shutdown_node( node_name() ) -> basic_utils:void().
shutdown_node( Nodename ) when is_list( Nodename ) ->
	shutdown_node( list_to_atom( Nodename ) );

shutdown_node( Nodename ) when is_atom( Nodename ) ->

	%io:format( "Request to shut down node '~s' from node '~s'.~n",
	%		  [ Nodename, node() ] ),

	case lists:member( Nodename, nodes() ) of

		true ->

			try

				%io:format( "Sending shutdown command for '~s'.~n",
				%           [ Nodename ] )

				%rpc:cast( Nodename, erlang, halt, [] )

				% Longer yet smoother:
				rpc:cast( Nodename, init, stop, [] )

			catch

				_T:E ->
					io:format( "Error while shutting down node '~s': ~p.~n",
							   [ Nodename, E ] )

			end,

			wait_unavailable( Nodename, _AttemptCount=10, _Duration=150 );
			%ok;

		false ->
			%io:format( "Node '~s' apparently not connected.~n", [ Nodename ] ),
			ok

	end.



wait_unavailable( Nodename, _AttemptCount=0, _Duration ) ->
	throw( { node_not_terminating, Nodename } );

wait_unavailable( Nodename, AttemptCount, Duration ) ->

	% We used to rely on net_adm:ping/1 (see below), but apparently
	% 'noconnection' can be raised and does not seem to be catchable.
	%
	% So we finally just wait until the target node disappears from the list
	% returned by nodes():
	%
	case lists:member( Nodename, nodes() ) of

		true ->
			timer:sleep( Duration ),
			wait_unavailable( Nodename, AttemptCount-1, 2*Duration );

		false ->
			% Additional safety delay to ensure the node had time to fully shut
			% down and to unregister from everything:
			%
			timer:sleep( 200 )

	end.

	%try net_adm:ping( Nodename ) of

	%	pong ->
	%		timer:sleep( Duration ),
	%		wait_unavailable( Nodename, AttemptCount-1, 2*Duration );

	%	pang ->
			% Safety delay to ensure the node had time to fully shut down and to
			% unregister from everything:
	%		timer:sleep( 200 ),
	%		ok

	%catch

	%	_T:E ->

	%		io:format( "Error while pinging node '~s': exception '~p'.~n",
	%				  [ Nodename, E ] )

	%end.




% Net-related command line options.


% Returns the command-line option (a plain string) to be used to run a new
% Erlang node with the same cookie as the current node, whether or not it is
% alive.
%
-spec get_cookie_option() -> string().
get_cookie_option() ->
	case erlang:get_cookie() of

		nocookie ->
			"";

		Cookie ->
			"-setcookie \"" ++ atom_to_list( Cookie ) ++ "\""

	end.



% Returns the command-line option (a plain string) to be used to run a new
% Erlang node with the specified EPMD port specification, which can be either
% the 'undefined' atom or the TCP port number.
%
% Note that if a non-default EPMD port is specified for a new node, this implies
% that the current node usually has to itself respect the same non-standard
% convention (ex: see the FIREWALL_OPT make option in common/GNUmakevars.inc),
% otherwise available nodes will not be found.
%
-spec get_epmd_environment( 'undefined' | tcp_port() ) ->
								  system_utils:environment().
get_epmd_environment( undefined ) ->
	[];

get_epmd_environment( EpmdPort ) when is_integer( EpmdPort ) ->

	% Flatten needed:
	PortString = text_utils:format( "~B", [ EpmdPort ] ),

	[ { "ERL_EPMD_PORT", PortString } ].



% Returns the command-line option (a plain string) to be used to run a new
% Erlang node with the node name (specified as a string) and node naming mode
% (short or long name, specified thanks to atoms).
-spec get_node_name_option( string_node_name(), node_naming_mode() ) ->
								  string().
get_node_name_option( NodeName, NodeNamingMode ) ->

	NodeNameOption = case NodeNamingMode of

		short_name ->
			"-sname";

		long_name ->
			"-name"

	end,

	NodeNameOption ++ " " ++ NodeName.



% Returns the command-line option (a plain string) to be used to run a new
% Erlang node with the specified TCP port restriction, which can be either the
% 'no_restriction' atom or a pair of integers {MinTCPPort,MaxTCPPort}.
%
% If using a specific TCP/IP port range for a new node, the current node may
% have to respect this constraint as well (see the FIREWALL_OPT make option in
% common/GNUmakevars.inc), otherwise inter-node communication could fail.
%
-spec get_tcp_port_range_option( 'no_restriction' | tcp_port_range() ) ->
									   string().
get_tcp_port_range_option( no_restriction ) ->
	"";

get_tcp_port_range_option( { MinTCPPort, MaxTCPPort } )
  when is_integer( MinTCPPort ) andalso is_integer( MaxTCPPort )
	   andalso MinTCPPort < MaxTCPPort ->
	%io:format( "Enforcing following TCP range: [~B,~B].~n",
	%		   [ MinTCPPort, MaxTCPPort ] ),
	io_lib:format( " -kernel inet_dist_listen_min ~B inet_dist_listen_max ~B ",
				   [ MinTCPPort, MaxTCPPort ] ).



% Returns a basic command line (as a plain string) and its related environment
% in order to launch an Erlang node (interpreter) with the specified settings.
%
-spec get_basic_node_launching_command( string_node_name(), node_naming_mode(),
	   'undefined' | tcp_port(), 'no_restriction' | tcp_port_range(),
	   string() ) -> { system_utils:command(), system_utils:environment() }.
get_basic_node_launching_command( NodeName, NodeNamingMode, EpmdSettings,
								  TCPSettings, AdditionalOptions ) ->

	% May end up with a command-line option similar to:
	% 'erl -setcookie 'foobar' -sname hello
	% -kernel inet_dist_listen_min 10000 inet_dist_listen_max 14000
	% -noshell -smp auto +K true +A 8 +P 400000' with an environment with
	% ERL_EPMD_PORT=754

	Command = text_utils:join( _Separator=" ", [
			executable_utils:get_default_erlang_interpreter_name(),
			get_cookie_option(),
			get_node_name_option( NodeName, NodeNamingMode ),
			get_tcp_port_range_option( TCPSettings ),
			AdditionalOptions ] ),

	% Note that specifying the environment that way would work locally only
	% (i.e. of course SSH does not propagate environment) - hence the export in
	% the previous command, that works locally and through SSH:
	%
	EpmdEnv = get_epmd_environment( EpmdSettings ),

	{ Command, EpmdEnv }.




% Net-related transfers.
%
% They are not through a dedicated TCP/IP socket pair, using sendfile.
%
% For proper operation, a sufficient number of async threads should be
% available.
%
% The recipient acts as a server, while the emitter acts as a client.
%
% The sender is to use send_file/2 while the recipient is to use one of the
% receive_file/{1,2,3}. As they synchronize through messages, no specific order
% of these two calls matters (the first will wait for the second).


% We use an ephemeral port number by default:
-define( default_send_file_port, 0 ).



% Sends specified file (probably over the network) to specified recipient PID,
% supposed to have already called on of the receive_file/{1,2,3}.
%
-spec send_file( file_utils:file_name(), pid() ) -> basic_utils:void().
send_file( Filename, RecipientPid ) ->

	case file_utils:is_existing_file( Filename ) of

		true ->
			ok;

		false ->
			throw( { file_to_send_not_found, Filename } )

	end,

	Permissions = case file:read_file_info( Filename ) of

		{ ok, #file_info{ mode=Mode } } ->
			  Mode;

		{ error, ReadInfoReason } ->
			  throw( { read_file_info_failed, ReadInfoReason } )

	end,

	% Strip the directories, keeps only the filename:
	BinFilename = text_utils:string_to_binary( filename:basename( Filename ) ),

	% Notifies the recipient so that it can receive the content:
	% (note: we mimic the WOOPER conventions here)
	RecipientPid ! { sendFile, [ BinFilename, Permissions, self() ] },

	receive

		{ sendFileAcknowledged, [ BinFilename, RemoteIP, Port ] } ->

			% We used to rely on hostnames:
			% Hostname = text_utils:binary_to_string( BinHostname ),

			%io:format( "~w connecting to ~s:~B to send '~s'.~n",
			%		   [ self(), ipv4_to_string( RemoteIP ), Port, Filename ] ),

			DataSocket = case gen_tcp:connect( RemoteIP, Port,
						[ binary, { packet, 0 }, { active, false } ] ) of

				{ ok, Socket } ->
					Socket;

				% Typically, 'econnrefused', 'etimedout' or 'enetunreach':
				{ error, Error } ->
					throw( { send_file_connection_failed,
							 ipv4_to_string( RemoteIP, Port ), Error } )

			end,

			% Two possibilities:

			% First, basic reading and sending:
			% case file:read_file( Filename ) of

			%	{ ok, BinFileContent } ->

			%		%io:format( "Sending ~B elements.~n",
			%		%		  [ size( BinFileContent ) ] ),

			%		case gen_tcp:send( DataSocket, BinFileContent ) of

			%			ok ->
			%				ok;

			%			{ error, SendReason } ->
			%				throw( { sending_failed, SendReason } )

			%		end;

			%	{ error, ReadReason } ->
			%		throw( { reading_failed, ReadReason } )

			% end,

			% Second, more efficient, is using the sendfile kernel
			% function. Moreover even very large files may be transferred this
			% way (whereas the previous approach would fail with 'enomem',
			% trying to load their full content in RAM before their sending), so
			% it is definitively the best solution:
			%

			%:format( "~w performing sendfile, using data socket ~p.~n",
			%		   [ self(), DataSocket ] ),

			case file:sendfile( Filename, DataSocket ) of

				{ ok, _SentByteCount } ->
					%io:format( "~w sent file.~n", [ self() ] ),
					ok;

				{ error, Reason } ->
					throw( { sendfile_failed, Reason } )

			end,

			ok = gen_tcp:close( DataSocket )

	end.





% Receives specified file out of band (through a dedicated TCP socket, not
% thanks to Erlang messages), the emitter being supposed to use send_file/2.
%
% The file will be written in current directory, and the default TCP port will
% be used.
%
% Returns the full path to the received file.
%
-spec receive_file( pid() ) -> file_utils:file_name().
receive_file( EmitterPid ) ->
	receive_file( EmitterPid, file_utils:get_current_directory() ).



% Receives specified file out of band (through a dedicated TCP socket, not
% thanks to Erlang messages) into specified pre-existing directory, the emitter
% being supposed to use send_file/2.
%
% The default TCP port will be used.
%
% Returns the full path to the received file.
%
-spec receive_file( pid(), file_utils:directory_name() ) -> basic_utils:void().
receive_file( EmitterPid, TargetDir ) ->
	receive_file( EmitterPid, TargetDir, ?default_send_file_port ).



% Receives specified file out of band (through a dedicated TCP socket, not
% thanks to Erlang messages) into specified pre-existing directory, the emitter
% being supposed to use send_file/2.
%
% The default TCP port will be used.
%
-spec receive_file( pid(), file_utils:directory_name(), tcp_port() ) ->
						  file_utils:file_name().
receive_file( EmitterPid, TargetDir, Port ) ->

	% We prefer relying on IP addresses rather than hostnames, as a surprisingly
	% high number of systems have no usable DNS service:
	%
	% BinHostname = text_utils:string_to_binary( localhost() ),
	LocalIP = get_local_ip_address(),

	%io:format( "~w (on ~w) determined its local IP: ~w.~n",
	%		   [ self(), node(), LocalIP ] ),

	receive

		{ sendFile, [ BinFilename, Permissions, EmitterPid ] } ->

			case gen_tcp:listen( Port, [ binary, { active, false },
										 { packet,0 } ] ) of

				{ ok, ListenSock } ->

					% An ephemeral port (0) may have been specified:
					{ ok, ActualPort } = inet:port( ListenSock ),

					EmitterPid ! { sendFileAcknowledged,
								  [ BinFilename, LocalIP, ActualPort ] },

					Filename = file_utils:join( TargetDir,
								 text_utils:binary_to_string( BinFilename ) ),

					%io:format( "Writing received file in '~s'.~n",
					%		  [ Filename ] ),

					% Do not know the units for { delayed_write, Size, Delay }:
					OutputFile = file_utils:open( Filename, [ write, raw,
													 binary, delayed_write ] ),

					% Mono-client, yet using a separate socket for actual
					% sending:
					%
					case gen_tcp:accept( ListenSock ) of

						{ ok, DataSocket } ->

							receive_file_chunk( DataSocket, OutputFile ),
							ok = gen_tcp:close( ListenSock );

						Other ->
							throw( { accept_failed, Other } )

					end,

					case file:write_file_info( Filename,
									  #file_info{ mode=Permissions } ) of

						ok ->
							Filename;

						{ error, WriteInfoReason } ->
							throw( { write_file_info_failed, WriteInfoReason } )

					end;

				{ error, Reason } ->
					throw( { listen_failed, Reason } )

			end

	end.



% Reads next chunk of transferred file.
%
% (helper)
%
receive_file_chunk( DataSocket, OutputFile ) ->

	inet:setopts( DataSocket, [ { active, once } ] ),

	receive

		{ tcp, DataSocket, Data } ->
			%io:format( "Received chunk of ~B elements.~n", [ size( Data ) ] ),
			file_utils:write( OutputFile, Data ),
			receive_file_chunk( DataSocket, OutputFile );

		{ tcp_closed, DataSocket } ->
			%io:format( "Connection closed.~n" ),
			ok = gen_tcp:close( DataSocket ),
			file_utils:close( OutputFile )

	end.




% Address-related functions.


% Tells whether the specified IPv4 address is routable.
%
% Note: the loopback ({127,0,0,1}, or {0,0,0,0,0,0,0,1}) is deemed routable.
%
-spec is_routable( ip_v4_address() ) -> boolean().
is_routable( { 10, _, _, _ } ) ->
	false;

is_routable( { 172, N, _, _ } ) when N >= 16 andalso N < 32 ->
	false;

is_routable( { 192, 168, _, _ } ) ->
	false;

is_routable( _ ) ->
	true.



% Returns a string describing the specified IPv4 address.
%
-spec ipv4_to_string( ip_v4_address() ) -> string().
ipv4_to_string( { N1, N2, N3, N4 } ) ->
	text_utils:format( "~B.~B.~B.~B", [ N1, N2, N3, N4 ] ).


% Returns a string describing the specified IPv4 address and port.
%
-spec ipv4_to_string( ip_v4_address(), net_port() ) -> string().
ipv4_to_string( { N1, N2, N3, N4 }, Port ) ->
	text_utils:format( "~B.~B.~B.~B:~B", [ N1, N2, N3, N4, Port ] ).



% Returns a string describing the specified IPv6 address.
%
-spec ipv6_to_string( ip_v6_address() ) -> string().
ipv6_to_string( { N1, N2, N3, N4, N5, N6 } ) ->
	text_utils:format( "~B.~B.~B.~B", [ N1, N2, N3, N4, N5, N6 ] ).


% Returns a string describing the specified IPv6 address and port.
%
-spec ipv6_to_string( ip_v6_address(), net_port() ) -> string().
ipv6_to_string( Ipv6={ _N1, _N2, _N3, _N4, _N5, _N6 }, Port ) ->
	text_utils:format( "~s:~B", [ ipv6_to_string( Ipv6 ), Port ] ).




% Returns a string describing the specified host.
%
-spec host_to_string( host_identifier() ) -> string().
host_to_string( IPv4={ _N1, _N2, _N3, _N4 } ) ->
	ipv4_to_string( IPv4 );

host_to_string( IPv6={ _N1, _N2, _N3, _N4, _N5, _N6 } ) ->
	ipv6_to_string( IPv6 );

host_to_string( Address ) ->
	Address.


% Returns a string describing the specified URL information.
%
-spec url_info_to_string( url_info() ) -> string().
url_info_to_string( #url_info{ protocol=Protocol, host_identifier=Host,
							   port=Port, path=Path } ) ->

	text_utils:format( "~s://~s:~B/~s", [ Protocol, host_to_string( Host ),
										  Port, Path ] ).



% Decodes specified string in an url_info, by extracting protocol, host, port
% and path information.
%
% Note that other information (query, user) will be ignored and lost.
%
-spec string_to_url_info( string() ) -> url_info().
string_to_url_info( String ) ->
	case http_uri:parse( String ) of

		{ ok, { Scheme, _UserInfo, Host, Port, Path, _Query } } ->
			#url_info{ protocol=Scheme,
					   host_identifier=Host,
					   port=Port,
					   path=Path };

		{ ok, { Scheme, _UserInfo, Host, Port, Path, _Query, _Fragment } } ->
			#url_info{ protocol=Scheme,
					   host_identifier=Host,
					   port=Port,
					   path=Path };

		{ error, Reason } ->
			throw( { url_info_parsing_failed, String, Reason } )

	end.
