class Riemann::Tools::MdstatParser
token ALGORITHM BITMAP BLOCKS BYTE_UNIT CHECK CHUNK DELAYED FAILED FINISH FLOAT IDENTIFIER INTEGER LEVEL MIN PAGES PERSONALITIES PERSONALITY PENDING PROGRESS RECOVER RECOVERY REMOTE RESHAPE RESYNC SPEED SPEED_UNIT SUPER UNIT UNUSED_DEVICES
rule
  target: personalities devices unused_devices { result = val[1] }

  personalities: PERSONALITIES ':' list_of_personalities

  list_of_personalities: list_of_personalities '[' PERSONALITY ']'
                       |

  devices: devices device { result = val[0].merge(val[1]) }
         |                { result = {} }

  device: IDENTIFIER ':' IDENTIFIER PERSONALITY list_of_devices INTEGER BLOCKS super level '[' INTEGER '/' INTEGER ']' '[' IDENTIFIER ']' progress bitmap { result = { val[0][:value] => val[15][:value] } }

  list_of_devices: list_of_devices device
                 | device

  device: IDENTIFIER '[' INTEGER ']' '(' FAILED ')'
        | IDENTIFIER '[' INTEGER ']'

  super: SUPER FLOAT
       |

  level: LEVEL INTEGER ',' INTEGER UNIT CHUNK ',' ALGORITHM INTEGER
       |

  bitmap: BITMAP ':' INTEGER '/' INTEGER PAGES '[' INTEGER BYTE_UNIT ']' ',' INTEGER BYTE_UNIT CHUNK
        |

  progress: PROGRESS progress_action '=' FLOAT '%' '(' INTEGER '/' INTEGER ')' FINISH '=' FLOAT MIN SPEED '=' INTEGER SPEED_UNIT
          | RECOVER '=' REMOTE
          | RESHAPE '=' REMOTE
          | RESYNC '=' REMOTE
          | RESYNC '=' PENDING
          | RESYNC '=' DELAYED
          |

  progress_action: CHECK
                 | RECOVERY
                 | RESHAPE
                 | RESYNC

  unused_devices: UNUSED_DEVICES ':' '<' IDENTIFIER '>'
end

---- header

require 'strscan'

require 'riemann/tools/utils'

---- inner

  def parse(text)
    s = Utils::StringTokenizer.new(text)

    until s.eos? do
      case
      when s.scan(/\n/)               then s.push_token(nil)
      when s.scan(/\s+/)              then s.push_token(nil)

      when s.scan(/\[=*>.*\]/)        then s.push_token(:PROGRESS)
      when s.scan(/%/)                then s.push_token('%')
      when s.scan(/,/)                then s.push_token(',')
      when s.scan(/:/)                then s.push_token(':')
      when s.scan(/</)                then s.push_token('<')
      when s.scan(/=/)                then s.push_token('=')
      when s.scan(/>/)                then s.push_token('>')
      when s.scan(/\(/)               then s.push_token('(')
      when s.scan(/\)/)               then s.push_token(')')
      when s.scan(/\./)               then s.push_token('.')
      when s.scan(/\//)               then s.push_token('/')
      when s.scan(/\[/)               then s.push_token('[')
      when s.scan(/]/)                then s.push_token(']')

      when s.scan(/DELAYED\b/)        then s.push_token(:DELAYED)
      when s.scan(/F\b/)              then s.push_token(:FAILED)
      when s.scan(/KB\b/)             then s.push_token(:BYTE_UNIT)
      when s.scan(/K\/sec\b/)         then s.push_token(:SPEED_UNIT)
      when s.scan(/PENDING\b/)        then s.push_token(:PENDING)
      when s.scan(/Personalities\b/)  then s.push_token(:PERSONALITIES)
      when s.scan(/REMOTE\b/)         then s.push_token(:REMOTE)
      when s.scan(/algorithm\b/)      then s.push_token(:ALGORITHM)
      when s.scan(/bitmap\b/)         then s.push_token(:BITMAP)
      when s.scan(/blocks\b/)         then s.push_token(:BLOCKS)
      when s.scan(/check\b/)          then s.push_token(:CHECK)
      when s.scan(/chunk\b/)          then s.push_token(:CHUNK)
      when s.scan(/finish\b/)         then s.push_token(:FINISH)
      when s.scan(/k\b/)              then s.push_token(:UNIT)
      when s.scan(/level\b/)          then s.push_token(:LEVEL)
      when s.scan(/min\b/)            then s.push_token(:MIN)
      when s.scan(/pages\b/)          then s.push_token(:PAGES)
      when s.scan(/(raid([014-6]|10)|linear|multipath|faulty)\b/) then s.push_token(:PERSONALITY)
      when s.scan(/recover\b/)        then s.push_token(:RECOVER)
      when s.scan(/recovery\b/)       then s.push_token(:RECOVERY)
      when s.scan(/reshape\b/)        then s.push_token(:RESHAPE)
      when s.scan(/resync\b/)         then s.push_token(:RESYNC)
      when s.scan(/speed\b/)          then s.push_token(:SPEED)
      when s.scan(/super\b/)          then s.push_token(:SUPER)
      when s.scan(/unused devices\b/) then s.push_token(:UNUSED_DEVICES)

      when s.scan(/\d+\.\d+/)         then s.push_token(:FLOAT, s.matched.to_f)
      when s.scan(/\d+/)              then s.push_token(:INTEGER, s.matched.to_i)
      when s.scan(/\w+/)              then s.push_token(:IDENTIFIER)
      else
        s.unexpected_token
      end
    end

    @tokens = s.tokens

    do_parse
  end

  def next_token
    @tokens.shift
  end

  def on_error(error_token_id, error_value, value_stack)
    raise(Racc::ParseError, "parse error on value \"#{error_value[:value]}\" (#{token_to_str(error_token_id)}) on line #{error_value[:lineno]}:\n#{error_value[:line]}\n#{' ' * error_value[:pos]}^#{'~' * (error_value[:value].to_s.length - 1)}")
  end
