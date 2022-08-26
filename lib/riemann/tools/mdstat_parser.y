class Riemann::Tools::MdstatParser
token ALGORITHM BITMAP BLOCKS BYTE_UNIT CHUNK FAILED FINISH FLOAT IDENTIFIER INTEGER LEVEL MIN PAGES PERSONALITIES PERSONALITY PROGRESS RECOVERY SPEED SPEED_UNIT SUPER UNIT UNUSED_DEVICES
rule
  target: personalities devices unused_devices { result = val[1] }

  personalities: PERSONALITIES ':' list_of_personalities

  list_of_personalities: list_of_personalities '[' PERSONALITY ']'
                       |

  devices: devices device { result = val[0].merge(val[1]) }
         |                { result = {} }

  device: IDENTIFIER ':' IDENTIFIER PERSONALITY list_of_devices INTEGER BLOCKS super level '[' INTEGER '/' INTEGER ']' '[' IDENTIFIER ']' bitmap restore_progress { result = { val[0] => val[15] } }

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

  restore_progress: PROGRESS RECOVERY '=' FLOAT '%' '(' INTEGER '/' INTEGER ')' FINISH '=' FLOAT MIN SPEED '=' INTEGER SPEED_UNIT
                  |

  unused_devices: UNUSED_DEVICES ':' '<' IDENTIFIER '>'
end

---- header

require 'strscan'

---- inner

  def parse(text)
    s = StringScanner.new(text)
    @tokens = []

    until s.eos? do
      case
      when s.scan(/\n/)              then # ignore
      when s.scan(/\s+/)             then # ignore

      when s.scan(/\[=*>.*\]/)       then @tokens << [:PROGRESS, s.matched]
      when s.scan(/%/)               then @tokens << ['%', s.matched]
      when s.scan(/,/)               then @tokens << [',', s.matched]
      when s.scan(/:/)               then @tokens << [':', s.matched]
      when s.scan(/</)               then @tokens << ['<', s.matched]
      when s.scan(/=/)               then @tokens << ['=', s.matched]
      when s.scan(/>/)               then @tokens << ['>', s.matched]
      when s.scan(/\(/)              then @tokens << ['(', s.matched]
      when s.scan(/\)/)              then @tokens << [')', s.matched]
      when s.scan(/\./)              then @tokens << ['.', s.matched]
      when s.scan(/\//)              then @tokens << ['/', s.matched]
      when s.scan(/\[/)              then @tokens << ['[', s.matched]
      when s.scan(/]/)               then @tokens << [']', s.matched]
      when s.scan(/algorithm/)       then @tokens << [:ALGORITHM, s.matched]
      when s.scan(/bitmap/)          then @tokens << [:BITMAP, s.matched]
      when s.scan(/blocks/)          then @tokens << [:BLOCKS, s.matched]
      when s.scan(/chunk/)           then @tokens << [:CHUNK, s.matched]
      when s.scan(/finish/)          then @tokens << [:FINISH, s.matched]
      when s.scan(/level/)           then @tokens << [:LEVEL, s.matched]
      when s.scan(/min/)             then @tokens << [:MIN, s.matched]
      when s.scan(/pages/)           then @tokens << [:PAGES, s.matched]
      when s.scan(/(raid([014-6]|10)|linear|multipath|faulty)\b/) then @tokens << [:PERSONALITY, s.matched]
      when s.scan(/Personalities/)   then @tokens << [:PERSONALITIES, s.matched]
      when s.scan(/recovery/)        then @tokens << [:RECOVERY, s.matched]
      when s.scan(/speed/)           then @tokens << [:SPEED, s.matched]
      when s.scan(/super/)           then @tokens << [:SUPER, s.matched]
      when s.scan(/unused devices/)  then @tokens << [:UNUSED_DEVICES, s.matched]
      when s.scan(/K\/sec/)          then @tokens << [:SPEED_UNIT, s.matched.to_i]
      when s.scan(/KB/)              then @tokens << [:BYTE_UNIT, s.matched.to_i]
      when s.scan(/k/)               then @tokens << [:UNIT, s.matched.to_i]
      when s.scan(/\d+\.\d+/)        then @tokens << [:FLOAT, s.matched.to_i]
      when s.scan(/\d+/)             then @tokens << [:INTEGER, s.matched.to_i]
      when s.scan(/F\b/)             then @tokens << [:FAILED, s.matched.to_i]
      when s.scan(/\w+/)             then @tokens << [:IDENTIFIER, s.matched]
      else
        raise s.rest
      end
    end

    do_parse
  end

  def next_token
    @tokens.shift
  end
