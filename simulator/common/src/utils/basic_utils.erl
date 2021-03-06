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
% Author: Olivier Boudeville (olivier.boudeville@esperide.com)
% Creation date: July 1, 2007.


% Gathering of various convenient facilities.
%
% See basic_utils_test.erl for the corresponding test.
%
-module(basic_utils).




% Notification-related functions.
%
-export([ speak/1, notify_user/1, notify_user/2 ]).



% Message-related functions.
%
-export([ flush_pending_messages/0, flush_pending_messages/1,
		  wait_for/2, wait_for/4, wait_for_acks/4, wait_for_acks/5,
		  wait_for_summable_acks/5,
		  wait_for_many_acks/4, wait_for_many_acks/5,
		  send_to_pid_set/2 ]).



% Miscellaneous functions.
%
-export([ size/1, display_process_info/1,
		  checkpoint/1,
		  display/1, display/2, display_timed/2, display_timed/3,
		  display_error/1, display_error/2,
		  debug/1, debug/2,
		  parse_version/1, compare_versions/2,
		  get_process_specific_value/0, get_process_specific_value/2,
		  get_execution_target/0,
		  is_alive/1, is_alive/2,
		  is_debug_mode_enabled/0,
		  generate_uuid/0, create_uniform_tuple/2,
		  stop/0, stop/1, stop_on_success/0, stop_on_failure/0,
		  stop_on_failure/1,
		  ignore/1, freeze/0, crash/0, enter_infinite_loop/0, trigger_oom/0 ]).



% Hints about retrieving the name of the function being currently evaluated by a
% process (as a ?FUNCTION macro could do):
%
% - either:
%
% current_function() ->
%    catch throw( x ), [_, {_, F, _, _} | _] = erlang:get_stacktrace(),
%    F.
%
% - or, maybe better:
%
% erlang:element( 2, erlang:element( 2, erlang:process_info( self(),
%   current_function ) ) ) ).



% To tell that a returned value is not of interest to the caller:
% (could/should be: "-type void() :: 'VoiD'" for example)
%
%-opaque void() :: any().
-type void() :: any().


% Allows to count elements (positive integer, possibly zero):
%
-type count() :: non_neg_integer().


% Describes a mask of bits:
%
-type bit_mask() :: integer().


% A string UUID (ex: "ed64ffd4-74ee-43dc-adba-be37ed8735aa"):
-type uuid() :: string().


% Term designated a reason (which may be any term):
%
% Note: useful to have self-describing types.
%
-type reason() :: any().


-type exit_reason() :: reason().

-type error_reason() :: reason().


% Error term:
-type error_term() :: { 'error', error_reason() }.


% Tells whether an operation succeeded; if not, an error reason is specified (as
% a term).
%
-type base_status() :: 'ok' | error_term().


% Quite often, variables (ex: record fields) are set to 'undefined'
% (i.e. "Nothing") before being set later:
%
-type maybe( T ) :: T | 'undefined'.


% To denote that a piece of data comes from the program boundaries (interfaces)
% and thus may or may not be of the expected type (as long as it has not been
% checked):
%
% (opaque, unspecified type - yet not declared as 'opaque' to avoid a
% compilation warning telling it is "underspecified and therefore meaningless").
%
-type external_data() :: term().


% Designates data whose type and value has not been checked yet.
%
-type unchecked_data() :: term().


% Designates user-specified data (users shall not be trusted either):
-type user_data() :: external_data().


% Designates an accumulator (of any type), to document typically fold-like
% operations:
%
% (useful for documentation purposes)
%
-type accumulator() :: any().



% Corresponds to smart (sortable, insertion-friendly) identifiers.
%
% Sometimes identifiers that can be sorted and that allow introducing any number
% of new identifiers between any two successive ones are needed.
%
% We use list of integers for that, whose default ordering corresponds to this
% need.
%
% For example, if having defined two identifiers [7,2] and [7,3], we can
% introduce two identifiers between them, typically [7,2,1] and [7,2,2], since
% the Erlang term ordering tells us that [7,2] < [7,2,1] < [7,2,2] < [7,3].
%
% As a result, no need to define specific comparison operators, '=:=', '<' and
% '>', hence 'lists:sort/1' are already adequate for that.
%
% Example: lists:sort( [ [7,3], [7,2,1], [7,2,2], [7,2] ] ) =
%   [ [7,2], [7,2,1], [7,2,2], [7,3] ].
%
-type sortable_id() :: [ integer() ].


-type version_number() :: integer().

% By default we consider a version is a triplet of numbers:
-type version() :: { version_number(), version_number(), version_number() }.


-type two_digit_version() :: { version_number(), version_number() }.

-type any_version() :: version() | two_digit_version().


% For all non-null index (i.e. the ones that start at 1).
-type positive_index() :: pos_integer().


% To distinguish with the built-in type, which can be a parameterised module:
-type module_name() :: atom().

-type function_name() :: atom().

-type argument() :: any().


% A mfa (module-function-arguments) command:
-type command_spec() :: { module_name(), function_name(), [ argument() ] }.



% To store (UNIX-like) user names:
-type user_name() :: nonempty_string().
-type atom_user_name() :: atom().


% Possible outcome of a partial-order comparison of two elements:
-type comparison_result() :: 'lower' | 'equal' | 'higher'.


% The exception classes that can be raised:
-type exception_class() :: 'throw' | 'exit' | 'error'.

% The status code returned by a shell command:
-type status_code() :: 0..255. % i.e. byte()


% Useful as a temporary type placeholder, during development:
-type fixme() :: any().


-export_type([ void/0, count/0, bit_mask/0, uuid/0, reason/0, exit_reason/0,
			   error_reason/0, error_term/0, base_status/0, maybe/1,
			   external_data/0, unchecked_data/0, user_data/0,
			   accumulator/0, sortable_id/0,
			   version_number/0, version/0, two_digit_version/0, any_version/0,
			   positive_index/0,
			   module_name/0, function_name/0, argument/0, command_spec/0,
			   user_name/0, atom_user_name/0,
			   comparison_result/0, exception_class/0, status_code/0,
			   fixme/0 ]).





% Returns a string containing a new universally unique identifier (UUID), based
% on the system clock plus the system's ethernet hardware address, if present.
%
-spec generate_uuid() -> uuid().
generate_uuid() ->

	case executable_utils:lookup_executable( "uuidgen" ) of

		false ->
			display( text_utils:format(
					   "~nWarning: no 'uuidgen' found on system, "
					   "defaulting to our failsafe implementation.~n", [] ) ),
			uuidgen_internal();

		Exec ->

			% Random-based, rather than time-based (otherwise we end up
			% collecting a rather constant suffix):
			%
			case system_utils:run_executable( Exec ++ " -r" ) of

				{ _ExitCode=0, Res } ->
					Res;

				{ ExitCode, ErrorOutput } ->
					throw( { uuid_generation_failed, ExitCode, ErrorOutput } )

			end

	end.



% Quick and dirty replacement:
%
uuidgen_internal() ->

	% Using /dev/random instead would incur waiting of a few seconds that were
	% deemed too long for this use:
	%
	case system_utils:run_executable(
		   "/bin/dd if=/dev/urandom bs=1 count=32 2>/dev/null" ) of

		{ _ReturnCode=0, Output } ->
			% We translate these bytes into hexadecimal values:
			V = [ string:to_lower( hd(
				  io_lib:format( "~.16B", [ B rem 16 ] ) ) )  || B <- Output ],

			lists:flatten( io_lib:format(
							 "~s~s~s~s~s~s~s~s-~s~s~s~s-~s~s~s~s-~s~s~s~s-~s"
							 "~s~s~s~s~s~s~s~s~s~s~s", V ) );

		{ ErrorCode, ErrorOutput } ->
			throw( { uuidgen_internal_failed, ErrorCode, ErrorOutput } )

	end.



% Creates a tuple of specified size, all elements having the same, specified,
% value.
%
-spec create_uniform_tuple( Size::count(), Value::any() ) -> tuple().
create_uniform_tuple( Size, Value ) ->

	List = lists:duplicate( Size, Value ),

	list_to_tuple( List ).



% Stops smoothly the underlying VM, with a normal, success status code (0).
%
% Also also to potentially override Erlang standard teardown procedure.
%
-spec stop() -> no_return().
stop() ->
	stop( _Success=0 ).



% Stops smoothly, synchronously the underlying VM, with specified error code.
%
% Also allows to potentially override Erlang standard teardown procedure.
%
-spec stop( status_code() ) -> no_return().
stop( StatusCode ) ->

	% Far less brutal than erlang:halt/{0,1}:
	init:stop( StatusCode ),

	% To avoid that the calling process continues with the next instructions:
	freeze().



% Stops smoothly, synchronously the underlying VM, with a normal, success status
% code (0).
%
-spec stop_on_success() -> no_return().
stop_on_success() ->
	stop( _Success=0 ).



% Stops smoothly the underlying VM, with a default error status code (1).
%
-spec stop_on_failure() -> no_return().
stop_on_failure() ->
	stop_on_failure( _OurDefaultErrorCode=5 ).


% Stops smoothly the underlying VM, with a default error status code (1).
%
-spec stop_on_failure( status_code() ) -> no_return().
stop_on_failure( StatusCode ) ->
	stop( StatusCode ).



% Ignores specified argument.
%
% Useful to define, for debugging purposes, terms that will be (temporarily)
% unused without blocking the compilation.
%
-spec ignore( any() ) -> void().
ignore( _Term ) ->
	io:format( "Warning: unused term ignored thanks to "
			   "basic_utils:ignore/1.~n" ).



% Freezes the current process immediately.
%
% Useful to block the process while for example an ongoing termination
% occurs.
%
% See also: enter_infinite_loop/0.
%
-spec freeze() -> no_return().
freeze() ->
	receive

		not_expected_to_be_received ->
			freeze()

	end.



% Crashes the current process immediately.
%
% Useful for testing reliability, for example.
%
-spec crash() -> any().
crash() ->

	io:format( "*** Crashing on purpose process ~w ***~n", [ self() ] ),

	% Must outsmart the compiler; there should be simpler solutions:
	A = system_utils:get_core_count(),
	B = system_utils:get_core_count(),

	% Dividing thus by zero:
	1 / ( A - B ).



% Makes the current process enter in an infinite, mostly idle loop.
%
% Useful for testing reliability, for example.
%
% See also: freeze/0.
%
enter_infinite_loop() ->

	io:format( "~p in infinite loop...", [ self() ] ),

	% Loops every minute:
	timer:sleep( 60000 ),

	enter_infinite_loop().



% Triggers a OOM crash, i.e. Out of Memory.
%
% Useful for testing reliability, for example.
%
trigger_oom() ->

	io:format( "~p triggering OOM (out of memory) crash...", [ self() ] ),

	% Expected: Crash dump was written to: erl_crash.dump
	%  binary_alloc: Cannot allocate 1000000000031 bytes of memory (of type
	% "binary").

	<<1:8000000000000>>.






% Notification-related functions.


% Speaks the specified message, using espeak.
%
-spec speak( string() ) -> void().
speak( Message ) ->
	system_utils:run_background_executable(
	  "espeak -s 140 \"" ++ Message ++ "\"" ).



% Notifies the user of the specified message, with log output and synthetic
% voice.
%
-spec notify_user( string() ) -> void().
notify_user( Message ) ->
	io:format( Message ),
	speak( Message ).



% Notifies the user of the specified message, with log output and synthetic
% voice.
%
% Example: 'basic_utils:notify_user( "Hello ~w", [ Name ]).'
%
-spec notify_user( string(), list() ) -> void().
notify_user( Message, FormatList ) ->

	ActualMessage = io_lib:format( Message, FormatList ),

	io:format( ActualMessage ),
	speak( ActualMessage ).



% Message-related section.


% Flushes all the messages still in the mailbox of this process.
%
-spec flush_pending_messages() -> void().
flush_pending_messages() ->

	receive

		_ ->
			flush_pending_messages()

	after 0 ->
		ok

	end.



% Flushes all the messages still in the mailbox of this process that match the
% specified one.
%
-spec flush_pending_messages( any() ) -> void().
flush_pending_messages( Message ) ->

	receive

		Message ->
			flush_pending_messages( Message )

	after 0 ->
		ok

	end.





% Waits (indefinitively) for the specified count of the specified message to be
% received.
%
-spec wait_for( any(), count() ) -> void().
wait_for( _Message, _Count=0 ) ->
	ok;

wait_for( Message, Count ) ->

	%io:format( "Waiting for ~B messages '~p'.~n", [ Count, Message ] ),
	receive

		Message ->
			wait_for( Message, Count-1 )

	end.



% Waits (indefinitively) for the specified count of the specified message to be
% received, displaying repeatedly on the console a notification should the
% duration between two receivings exceed the specified time-out.
%
% Typical usage: basic_utils:wait_for( { foobar_result, done }, _Count=5,
% _Duration=2000, "Still waiting for ~B task(s) to complete" ).
%
-spec wait_for( any(), count(), unit_utils:milliseconds(),
				text_utils:format_string() ) -> void().
wait_for( _Message, _Count=0, _TimeOutDuration, _TimeOutFormatString ) ->
	ok;

wait_for( Message, Count, TimeOutDuration, TimeOutFormatString ) ->

	%io:format( "Waiting for ~B messages '~p'.~n", [ Count, Message ] ),

	receive

		Message ->
			%io:format( "Received message '~p'.~n", [ Message ] ),
			wait_for( Message, Count-1 )

	after TimeOutDuration ->

		io:format( TimeOutFormatString ++ " after ~s",
				   [ Count, text_utils:duration_to_string( TimeOutDuration ) ] )

	end.





% Wait patterns, safer and better defined once for all.




% Waits until receiving from all expected senders the specified acknowledgement
% message, expected to be in the form of { AckReceiveAtom, WaitedSenderPid }.
%
% Throws a { ThrowAtom, StillWaitedSenders } exception on time-out (if any, as
% the time-out can be disabled if set to 'infinity').
%
% See wait_for_many_acks/{4,5} if having a large number of senders waited for.
%
-spec wait_for_acks( [ pid() ], time_utils:time_out(), atom(), atom() ) ->
						   void().
wait_for_acks( WaitedSenders, MaxDurationInSeconds, AckReceiveAtom,
			   ThrowAtom ) ->

	wait_for_acks( WaitedSenders, MaxDurationInSeconds, _DefaultPeriod=1000,
				   AckReceiveAtom, ThrowAtom ).



% Waits until receiving from all expected senders the specified acknowledgement
% message, expected to be in the form of { AckReceiveAtom, WaitedSenderPid },
% ensuring a check is performed at least at specified period.
%
% Throws a { ThrowAtom, StillWaitedSenders } exception on time-out.
%
% See wait_for_many_acks/{4,5} if having a large number of senders waited for.
%
-spec wait_for_acks( [ pid() ], time_utils:time_out(),
					 unit_utils:milliseconds(), atom(), atom() ) -> void().
wait_for_acks( WaitedSenders, MaxDurationInSeconds, Period,
			   AckReceiveAtom, ThrowAtom ) ->

	InitialTimestamp = time_utils:get_timestamp(),

	wait_for_acks_helper( WaitedSenders, InitialTimestamp,
		MaxDurationInSeconds, Period, AckReceiveAtom, ThrowAtom ).



% (helper)
%
wait_for_acks_helper( _WaitedSenders=[], _InitialTimestamp,
			  _MaxDurationInSeconds, _Period, _AckReceiveAtom, _ThrowAtom ) ->
	ok;

wait_for_acks_helper( WaitedSenders, InitialTimestamp, MaxDurationInSeconds,
					  Period, AckReceiveAtom, ThrowAtom ) ->

	receive

		{ AckReceiveAtom, WaitedPid } ->

			NewWaited = list_utils:delete_existing( WaitedPid, WaitedSenders ),

			%io:format( "(received ~p, still waiting for instances ~p)~n",
			%		   [ WaitedPid, NewWaited ] ),

			wait_for_acks_helper( NewWaited, InitialTimestamp,
				  MaxDurationInSeconds, Period, AckReceiveAtom, ThrowAtom )

	after Period ->

			NewDuration = time_utils:get_duration_since( InitialTimestamp ),

			case ( MaxDurationInSeconds =/= infinity ) andalso
					  ( NewDuration > MaxDurationInSeconds ) of

				true ->
					throw( { ThrowAtom, WaitedSenders } );

				false ->
					% Still waiting then:

					%io:format( "(still waiting for instances ~p)~n",
					%   [ WaitedSenders ] ),

					wait_for_acks_helper( WaitedSenders, InitialTimestamp,
						MaxDurationInSeconds, Period, AckReceiveAtom,
						ThrowAtom )

			end

	end.



% Waits until receiving from all expected senders the specified acknowledgement
% message, expected to be in the form of:
% { AckReceiveAtom, ToAdd, WaitedSenderPid }.
%
% Returns the sum of the specified initial value with all the ToAdd received
% values.
%
% Throws a { ThrowAtom, StillWaitedSenders } exception on time-out (if any, as
% the time-out can be disabled if set to 'infinity').
%
-spec wait_for_summable_acks( [ pid() ], number(), time_utils:time_out(),
							  atom(), atom() ) -> number().
wait_for_summable_acks( WaitedSenders, InitialValue, MaxDurationInSeconds,
						AckReceiveAtom, ThrowAtom ) ->

	wait_for_summable_acks( WaitedSenders, InitialValue, MaxDurationInSeconds,
							_DefaultPeriod=1000, AckReceiveAtom, ThrowAtom ).



% Waits until receiving from all expected senders the specified acknowledgement
% message, expected to be in the form of:
% { AckReceiveAtom, ToAdd, WaitedSenderPid }
%
% ensuring a check is performed at least at specified period and summing all
% ToAdd values with the specified initial one
%
% Throws a { ThrowAtom, StillWaitedSenders } exception on time-out.
%
%
-spec wait_for_summable_acks( [ pid() ], number(), time_utils:time_out(),
		   unit_utils:milliseconds(), atom(), atom() ) -> number().
wait_for_summable_acks( WaitedSenders, CurrentValue, MaxDurationInSeconds,
						Period, AckReceiveAtom, ThrowAtom ) ->

	InitialTimestamp = time_utils:get_timestamp(),

	wait_for_summable_acks_helper( WaitedSenders, CurrentValue,
								   InitialTimestamp, MaxDurationInSeconds,
								   Period, AckReceiveAtom, ThrowAtom ).



% (helper)
%
wait_for_summable_acks_helper( _WaitedSenders=[], CurrentValue,
							   _InitialTimestamp, _MaxDurationInSeconds,
							   _Period, _AckReceiveAtom, _ThrowAtom ) ->
	CurrentValue;

wait_for_summable_acks_helper( WaitedSenders, CurrentValue, InitialTimestamp,
			MaxDurationInSeconds, Period, AckReceiveAtom, ThrowAtom ) ->

	receive

		{ AckReceiveAtom, ToAdd, WaitedPid } ->

			NewWaited = list_utils:delete_existing( WaitedPid, WaitedSenders ),

			%io:format( "(received ~p, still waiting for instances ~p)~n",
			%		   [ WaitedPid, NewWaited ] ),

			wait_for_summable_acks_helper( NewWaited, CurrentValue + ToAdd,
				  InitialTimestamp, MaxDurationInSeconds, Period,
				  AckReceiveAtom, ThrowAtom )

	after Period ->

			NewDuration = time_utils:get_duration_since( InitialTimestamp ),

			case ( MaxDurationInSeconds =/= infinity ) andalso
					  ( NewDuration > MaxDurationInSeconds ) of

				true ->
					throw( { ThrowAtom, WaitedSenders } );

				false ->
					% Still waiting then:

					%io:format( "(still waiting for instances ~p)~n",
					%   [ WaitedSenders ] ),

					wait_for_summable_acks_helper( WaitedSenders, CurrentValue,
						InitialTimestamp, MaxDurationInSeconds, Period,
						AckReceiveAtom,	ThrowAtom )

			end

	end.





% Waits until receiving from all expected (numerous) senders the specified
% acknowledgement message.
%
% Throws specified exception on time-out.
%
% Note: each sender shall be unique (as they will be gathered in a set, that
% does not keep duplicates)
%
-spec wait_for_many_acks( set_utils:set( pid() ), unit_utils:milliseconds(),
						  atom(), atom() ) -> void().
wait_for_many_acks( WaitedSenders, MaxDurationInSeconds, AckReceiveAtom,
					ThrowAtom ) ->

	wait_for_many_acks( WaitedSenders, MaxDurationInSeconds,
						_DefaultPeriod=1000, AckReceiveAtom, ThrowAtom ).



% Waits until receiving from all expected (numerous) senders the specified
% acknowledgement message.
%
% Throws specified exception on time-out, checking at the specified period.
%
-spec wait_for_many_acks( set_utils:set( pid() ), unit_utils:milliseconds(),
						  unit_utils:milliseconds(), atom(), atom() ) -> void().
wait_for_many_acks( WaitedSenders, MaxDurationInSeconds, Period,
					AckReceiveAtom, ThrowAtom ) ->

	InitialTimestamp = time_utils:get_timestamp(),

	wait_for_many_acks_helper( WaitedSenders, InitialTimestamp,
		MaxDurationInSeconds, Period, AckReceiveAtom, ThrowAtom ).



% For this version we prefer a look-up optimised list to a plain one.
%
% (helper)
%
wait_for_many_acks_helper( WaitedSenders, InitialTimestamp,
						   MaxDurationInSeconds, Period, AckReceiveAtom,
						   ThrowAtom ) ->

	case set_utils:is_empty( WaitedSenders ) of

		true ->
			ok;

		false ->

			receive

				{ AckReceiveAtom, WaitedPid } ->

					NewWaited = set_utils:safe_delete( WaitedPid,
													   WaitedSenders ),

					wait_for_many_acks_helper( NewWaited, InitialTimestamp,
					   MaxDurationInSeconds, Period, AckReceiveAtom, ThrowAtom )

			after Period ->

					NewDuration = time_utils:get_duration_since(
									InitialTimestamp ),

					case NewDuration > MaxDurationInSeconds of

						true ->
							throw( { ThrowAtom, WaitedSenders } );

						false ->
							% Still waiting then:
							wait_for_many_acks_helper( WaitedSenders,
								InitialTimestamp, MaxDurationInSeconds, Period,
								AckReceiveAtom, ThrowAtom )

					end

			end

	end.



% Sends the specified message to all elements (supposed to be PID) of the
% specified set, and returns the number of sent messages.
%
% (helper)
%
-spec send_to_pid_set( term(), set_utils:set( pid() ) ) -> count().
send_to_pid_set( Message, PidSet ) ->

	% Conceptually (not a basic list, though):
	 % [ Pid ! Message || Pid <- PidSet ]

	% With iterators, it is done slightly slower yet with less RAM rather than
	% first using set_utils:to_list/1 then iterating on the resulting plain
	% list:
	%
	Iterator = set_utils:iterator( PidSet ),

	% Returns the count:
	send_to_pid_set( Message, set_utils:next( Iterator ), _Count=0 ).



% (helper)
%
send_to_pid_set( _Message, none, Count ) ->
	Count;

send_to_pid_set( Message, { Pid, NewIterator }, Count ) ->
	Pid ! Message,
	send_to_pid_set( Message, set_utils:next( NewIterator ), Count+1 ).





% Miscellaneous functions.


% Returns the number of bytes used by specified term.
%
-spec size( term() ) -> system_utils:byte_size().
size( Term ) ->
	system_utils:get_size( Term ).


% Displays information about the process(es) identified by specified PID.
%
-spec display_process_info( pid() | [ pid() ] ) -> void().
display_process_info( PidList ) when is_list( PidList ) ->
	[ display_process_info( Pid ) || Pid <- PidList ];

display_process_info( Pid ) when is_pid( Pid ) ->

	LocalNode = node(),

	% erlang:process_info/1 throws badarg if the process is not local:
	case node( Pid ) of


		LocalNode ->
			case erlang:process_info( Pid ) of

				undefined ->
					io:format( "PID ~w refers to a (local) dead process~n",
							   [ Pid ] );

				PropList ->
					Strings = [ io_lib:format( "~s: ~p", [ K, V ] )
							   || { K, V } <- PropList ],
					io:format( "PID ~w refers to a local live process, "
							   "whose information are:~s",
							   [ Pid,
								  text_utils:strings_to_string( Strings ) ] )

			end;


		OtherNode ->

			% The current module may not be on this node:
			case rpc:call( OtherNode, _M=erlang, _F=process_info, _A=[ Pid ] )
			   of

				{ badrpc, Reason } ->
					io:format( "No information found for process ~w "
							   "running on remote node ~p; reason: ~p.~n",
							   [ Pid, OtherNode, Reason ] );

				undefined ->
					io:format( "PID ~w refers to a dead process on "
							   "remote node ~s.~n", [ Pid, OtherNode ] );

				PropList ->

					Strings = [ io_lib:format( "~s: ~p", [ K, V ] )
								|| { K, V } <- PropList ],

					io:format( "PID ~w refers to a live process on "
							   "remote node ~s, whose information are:~s",
							   [ Pid, OtherNode,
								 text_utils:strings_to_string( Strings ) ] )

			end

	end.



% Displays a numbered checkpoint.
%
% Useful for debugging purposes.
%
-spec checkpoint( integer() ) -> void().
checkpoint( Number ) ->
	display( "----- CHECKPOINT #~B -----", [ Number ] ).



% Displays specified string on the standard output of the console, ensuring as
% much as possible this message is output synchronously, so that it can be
% output on the console even if the virtual machine is to crash just after.
%
-spec display( string() ) -> void().
display( Message ) ->

	% Finally io:format has been preferred to erlang:display, as the latter one
	% displays quotes around the strings.

	io:format( "~s~n", [ Message ] ),
	system_utils:await_output_completion().

	% May not go through group leader (like io:format), thus less likely to
	% crash without displaying the message:
	%
	%erlang:display( lists:flatten( [ Message, ".~n" ] ) ).
	%erlang:display( Message ).



% Displays specified format string filled according to specified values on the
% standard output of the console, ensuring as much as possible this message is
% output synchronously, so that it can be output on the console even if the
% virtual machine is to crash just after.
%
-spec display( text_utils:format_string(), [ any() ] ) -> void().
display( Format, Values ) ->

	%io:format( "Displaying format '~p' and values '~p'.~n",
	%		   [ Format, Values ] ),

	Message = text_utils:format( Format, Values ),

	display( Message ).




% Displays specified string on the standard output of the console, ensuring as
% much as possible this message is output synchronously, so that it can be
% output on the console even if the virtual machine is to crash just after.
%
-spec display_timed( string(), time_utils:time_out() ) -> void().
display_timed( Message, TimeOut ) ->

	% Finally io:format has been preferred to erlang:display, as the latter one
	% displays quotes around the strings.

	io:format( "~s~n", [ Message ] ),
	system_utils:await_output_completion( TimeOut ).

	% May not go through group leader (like io:format), thus less likely to
	% crash without displaying the message:
	%
	%erlang:display( lists:flatten( [ Message, ".~n" ] ) ).
	%erlang:display( Message ).



% Displays specified format string filled according to specified values on the
% standard output of the console, ensuring as much as possible this message is
% output synchronously, so that it can be output on the console even if the
% virtual machine is to crash just after.
%
-spec display_timed( text_utils:format_string(), [ any() ],
					 time_utils:time_out() ) -> void().
display_timed( Format, Values, TimeOut ) ->

	%io:format( "Displaying format '~p' and values '~p'.~n",
	%		   [ Format, Values ] ),

	Message = text_utils:format( Format, Values ),

	display_timed( Message, TimeOut ).





% Displays specified string on the standard error output of the console,
% ensuring as much as possible this message is output synchronously, so that it
% can be output on the console even if the virtual machine is to crash just
% after.
%
-spec display_error( string() ) -> void().
display_error( Message ) ->

	% At least once, following call resulted in no output at all (standard_error
	% not functional):
	%
	%io:format( standard_error, "~s~n", [ Message ] ),

	% So:
	io:format( "~s~n", [ Message ] ),

	system_utils:await_output_completion().



% Displays specified format string filled according to specified values on the
% standard error output of the console, ensuring as much as possible this
% message is output synchronously, so that it can be output on the console even
% if the virtual machine is to crash just after.
%
-spec display_error( text_utils:format_string(), [ any() ] ) -> void().
display_error( Format, Values ) ->
	%io:format( standard_error, Format ++ "~n", Values ),
	io:format( Format ++ "~n", Values ),
	system_utils:await_output_completion().




% Displays, for debugging purposes, specified string, ensuring as much as
% possible this message is output synchronously, so that it can be output on the
% console even if the virtual machine is to crash just after.
%
-spec debug( string() ) -> void().
debug( Message ) ->
	%io:format( "## Debug: ~s.~n", [ Message ] ),
	%system_utils:await_output_completion().
	erlang:display( "## Debug: " ++ Message ).



% Displays, for debugging purposes, specified format string filled according to
% specified values, ensuring as much as possible this message is output
% synchronously, so that it can be output on the console even if the virtual
% machine is to crash just after.
%
-spec debug( text_utils:format_string(), [ any() ] ) -> void().
debug( Format, Values ) ->
	debug( io_lib:format( Format, Values ) ).





% Parses specified textual version.
%
% Ex: "4.2.1" should become {4,2,1}, and "2.3" should become {2,3}.
%
-spec parse_version( string() ) -> any_version().
parse_version( VersionString ) ->

	% First transform "4.22.1" into ["4","22","1"]:
	Elems = string:tokens( VersionString, "." ),

	% Then simply switch to {4,22,1}:
	list_to_tuple( [ text_utils:string_to_integer(E) || E <- Elems ] ).



% Compares the two pairs or triplets, which describe two version numbers (ex:
% {0,1,0} or {4,2}) and returns either first_bigger, second_bigger, or equal.
%
% The two compared versions must have the same number of digits.
%
% Note: the default term order is already what we needed.
%
-spec compare_versions( any_version(), any_version() ) ->
							  'equal' | 'first_bigger' | 'second_bigger'.
compare_versions( {A1,A2,A3}, {B1,B2,B3} ) ->

	case {A1,A2,A3} > {B1,B2,B3} of

		true ->
			first_bigger;

		false ->

			case {A1,A2,A3} =:= {B1,B2,B3} of

				true ->
					equal;

				false ->
					second_bigger

			end

	end;

compare_versions( {A1,A2}, {B1,B2} ) ->

	case {A1,A2} > {B1,B2} of

		true ->
			first_bigger;

		false ->

			case {A1,A2} =:= {B1,B2} of

				true ->
					equal;

				false ->
					second_bigger

			end

	end.




% Returns a value (a strictly positive integer) expected to be as much as
% possible specific to the current process.
%
% Mostly based on its PID.
%
% Useful for example when a large number of similar processes try to access to
% the same resource (ex: a set of file descriptors) over time: they can rely on
% some random waiting based on that process-specific value in order to smooth
% the accesses over time.
%
% We could imagine taking into account as well the current time, the process
% reductions, etc. or generating a reference.
%
-spec get_process_specific_value() -> pos_integer().
get_process_specific_value() ->

	% PID are akin to <X.Y.Z>.

	PidAsText = lists:flatten( io_lib:format( "~w", [ self() ] ) ),

	%io:format( "PID: ~w.~n", [ self() ] ) ,
	% Ex: ["<0","33","0>"]:
	[ [ $< | First ], Second, Third ] = string:tokens( PidAsText, "." ),

	% We add 1 to x and z as they might be null:
	{ F, [] } = string:to_integer( First ),
	{ S, [] } = string:to_integer( Second ),

	[ $> | ExtractedThird ] = lists:reverse( Third ),

	{ T, [] } = string:to_integer( ExtractedThird ),

	X = F+1,
	Y = S,
	Z = T+1,
	%io:format( "Res = ~w.~n", [X*Y*Z] ),
	X*Y*Z.



% Returns a process-specific value in [Min,Max[.
%
-spec get_process_specific_value( integer(), integer() ) -> integer().
get_process_specific_value( Min, Max ) ->

	Value = get_process_specific_value(),

	{ H, M, S } = erlang:time(),

	( ( ( H + M + S + 1 ) * Value ) rem ( Max - Min ) ) + Min.



% Returns the execution target this module was compiled with, i.e. either the
% atom 'development' or 'production'.


% Dispatched in actual clauses, otherwise Dialyzer will detect an
% underspecification:
%
% -spec get_execution_target() -> 'production' | 'development'.

-ifdef(exec_target_is_production).

-spec get_execution_target() -> 'production'.
get_execution_target() ->
	production.

-else. % exec_target_is_production

-spec get_execution_target() -> 'development'.
get_execution_target() ->
	development.

-endif. % exec_target_is_production



% Tells whether the specified process, designated by its PID, by a textual
% representation of it (like "<9092.61.0>") or by a registred name (local
% otherwise global) like 'foobar_service') was still existing at the moment of
% this call.
%
% Note:
% - the process may run on the local node or not
% - generally not to be used when relying on a good design.
%
-spec is_alive( pid() | string() | naming_utils:registration_name() ) -> boolean().
is_alive( TargetPid ) when is_pid( TargetPid ) ->
	is_alive( TargetPid, node( TargetPid ) );

is_alive( TargetPidString ) when is_list( TargetPidString ) ->
	TargetPid = list_to_pid( TargetPidString ),
	is_alive( TargetPid, node( TargetPid ) );

is_alive( TargetPidName ) when is_atom( TargetPidName ) ->
	TargetPid = naming_utils:get_registered_pid_for( TargetPidName,
						_RegistrationType=local_otherwise_global ),
	is_alive( TargetPid, node( TargetPid ) ).



% Tells whether the specified process (designated by its PID) supposed to run on
% specified node (specified as an atom) was still existing at the moment of this
% call.
%
% Note: generally not to be used when relying on a good design; and is_alive/1
% should be preferred.
%
-spec is_alive( pid(), net_utils:atom_node_name() ) -> boolean().
is_alive( TargetPid, Node ) when is_pid( TargetPid ) ->

	% erlang:is_process_alive/1 is more intended for debugging purposes...

	case node() of

		Node ->
			% Would fail with 'badarg' if the process ran on another node:
			erlang:is_process_alive( TargetPid );

		_OtherNode ->
			%io:format( "Testing liveliness of process ~p on node ~p.~n",
			%		  [ TargetPid, Node ] ),
			rpc:call( Node, _Mod=erlang, _Fun=is_process_alive,
					  _Args=[ TargetPid ] )

	end.



% Returns whether the debug mode is activated for the compilation of this
% module.

% Dispatched in actual clauses, otherwise Dializer will detect an
% underspecification:
%
%-spec is_debug_mode_enabled() -> boolean().

-ifdef(debug_mode_is_enabled).

-spec is_debug_mode_enabled() -> true.
is_debug_mode_enabled() ->
	true.

-else. % debug_mode_is_enabled

-spec is_debug_mode_enabled() -> false.
is_debug_mode_enabled() ->
	false.

-endif. % debug_mode_is_enabled
