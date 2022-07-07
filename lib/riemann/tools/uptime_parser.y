class Riemann::Tools::UptimeParser
token AM PM UP DAYS HRS MINS SECS USERS LOAD_AVERAGES
  INTEGER FLOAT
rule
  target: time uptime ',' users ',' load_averages { result = { uptime: val[1], users: val[3], load_averages: val[5] } }

  time: INTEGER ':' INTEGER
      | INTEGER ':' INTEGER AM
      | INTEGER ':' INTEGER PM
      | INTEGER ':' INTEGER ':' INTEGER

  uptime: UP uptime_days uptime_hr_min { result = val[1] + val[2] }
        | UP uptime_days uptime_hr     { result = val[1] + val[2] }
        | UP uptime_days uptime_min    { result = val[1] + val[2] }
        | UP uptime_days uptime_sec    { result = val[1] + val[2] }
        | UP uptime_hr_min             { result = val[1] }
        | UP uptime_hr                 { result = val[1] }
        | UP uptime_min                { result = val[1] }
        | UP uptime_sec                { result = val[1] }

  uptime_days: INTEGER DAYS ',' { result = val[0] * 86400 }

  uptime_hr_min: INTEGER ':' INTEGER { result = val[0] * 3600 + val[2] * 60 }

  uptime_hr: INTEGER HRS { result = val[0] * 3600 }

  uptime_min: INTEGER MINS { result = val[0] * 60 }

  uptime_sec: INTEGER SECS { result = val[0] }

  users: INTEGER USERS

  load_averages: LOAD_AVERAGES FLOAT FLOAT FLOAT         { result = { 1 => val[1], 5 => val[2], 15 => val[3] } }
               | LOAD_AVERAGES FLOAT ',' FLOAT ',' FLOAT { result = { 1 => val[1], 5 => val[3], 15 => val[5] } }
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

      when s.scan(/:/)               then @tokens << [':', s.matched]
      when s.scan(/,/)               then @tokens << [',', s.matched]
      when s.scan(/\d+[,.]\d+/)      then @tokens << [:FLOAT, s.matched.sub(',', '.').to_f]
      when s.scan(/\d+/)             then @tokens << [:INTEGER, s.matched.to_i]
      when s.scan(/AM/)              then @tokens << [:AM, s.matched]
      when s.scan(/PM/)              then @tokens << [:PM, s.matched]
      when s.scan(/up/)              then @tokens << [:UP, s.matched]
      when s.scan(/days?/)           then @tokens << [:DAYS, s.matched]
      when s.scan(/hrs?/)            then @tokens << [:HRS, s.matched]
      when s.scan(/mins?/)           then @tokens << [:MINS, s.matched]
      when s.scan(/secs?/)           then @tokens << [:SECS, s.matched]
      when s.scan(/users?/)          then @tokens << [:USERS, s.matched]
      when s.scan(/load averages?:/) then @tokens << [:LOAD_AVERAGES, s.matched]
      else
        raise s.rest
      end
    end

    do_parse
  end

  def next_token
    @tokens.shift
  end
