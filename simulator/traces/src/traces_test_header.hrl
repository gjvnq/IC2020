% Copyright (C) 2003-2017 Olivier Boudeville
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
% Creation date: Tuesday, January 11, 2011


% Defines some macros and functions useful for trace-using tests.


-ifndef(trace_emitter_categorization).

-define( trace_emitter_categorization, "test" ).

-endif. % trace_emitter_categorization




% Section for trace output macros.


% We moved away from the tracing_activated conditional sections the most severe
% trace sendings (namely fatal, error and warning), as in all cases (whether or
% not the traces are activated), we want them, and both as actual traces and as
% console outputs.



-define( test_fatal( Message ),
		 class_TraceEmitter:send_standalone_safe( fatal, Message )
).


-define( test_fatal_fmt( MessageFormat, FormatValues ),
		 class_TraceEmitter:send_standalone_safe( fatal,
					  text_utils:format( MessageFormat, FormatValues ) )
).


-define( test_error( Message ),
		 class_TraceEmitter:send_standalone_safe( error, Message )
).


-define( test_error_fmt( MessageFormat, FormatValues ),
		 class_TraceEmitter:send_standalone_safe( error,
					  text_utils:format( MessageFormat, FormatValues ) )
).


-define( test_warning( Message ),
		 class_TraceEmitter:send_standalone_safe( warning, Message )
).


-define( test_warning_fmt( MessageFormat, FormatValues ),
		 class_TraceEmitter:send_standalone_safe( warning,
					  text_utils:format( MessageFormat, FormatValues ) )
).





-ifdef(tracing_activated).



-define( test_info( Message ),
		 class_TraceEmitter:send_standalone_safe( info, Message )

).


-define( test_info_fmt( MessageFormat, FormatValues ),
		 class_TraceEmitter:send_standalone_safe( info,
					  text_utils:format( MessageFormat, FormatValues ) )
).



-define( test_trace( Message ),
		 class_TraceEmitter:send_standalone_safe( trace, Message )

).


-define( test_trace_fmt( MessageFormat, FormatValues ),
		 class_TraceEmitter:send_standalone_safe( trace,
					  text_utils:format( MessageFormat, FormatValues ) )

).



-define( test_debug( Message ),
		 class_TraceEmitter:send_standalone_safe( debug, Message )
).


-define( test_debug_fmt( MessageFormat, FormatValues ),
		 class_TraceEmitter:send_standalone_safe( debug,
					  text_utils:format( MessageFormat, FormatValues ) )


).


% 'void' section put near the end of this file.




-else. % tracing_activated



% Here tracing_activated is not defined: non-critical traces are disabled.





-define( test_info( Message ), test_trace_disabled( Message ) ).


-define( test_info_fmt( Message, FormatValues ),
		 test_trace_disabled( Message, FormatValues ) ).



-define( test_trace( Message ), test_trace_disabled( Message ) ).


-define( test_trace_fmt( Message, FormatValues ),
		 test_trace_disabled( Message, FormatValues ) ).



-define( test_debug( Message ), test_trace_disabled( Message ) ).


-define( test_debug_fmt( Message, FormatValues ),
		 test_trace_disabled( Message, FormatValues ) ).



-endif. % tracing_activated



% Void traces muted in all cases:

-define( test_void( Message ), test_trace_disabled( Message ) ).

-define( test_void_fmt( Message, FormatValues ),
		 test_trace_disabled( Message, FormatValues ) ).
